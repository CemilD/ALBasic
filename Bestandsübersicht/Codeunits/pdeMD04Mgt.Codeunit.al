codeunit 50005 pdeMD04Mgt
{
    // =========================================================
    // PDE MD04 Simple - Aggregationscodeunit
    // Verantwortlich für:
    //   - Laden aller Bedarfs- und Zugangspositionen in den LineBuffer
    //   - Berechnung des laufenden Hochrechnungsbestands
    //   - Gruppierung der Zeilen in Periodenblöcke (Tag / Woche / Monat)
    //   - Mandantenübergreifende Bestandsabfrage (Cross-Company)
    // =========================================================

    // --- ÖFFENTLICH: Mandantenübergreifenden Bestand laden ---

    /// <summary>
    /// Liest den Lagerbestand des angegebenen Artikels aus ALLEN Mandanten.
    /// Verwendet ChangeCompany() um auf Daten fremder Mandanten zuzugreifen.
    /// Ergebnis: eine Zeile pro Mandant (und optional pro Lagerort).
    /// </summary>
    procedure LoadCrossCompanyStock(
        pItemNo: Code[20];
        var CrossBuffer: Record pdeMD04CrossCompanyBuffer)
    var
        Companies: Record Company;
        ManufacturingSetup: Record "Manufacturing Setup";
        // CrossItem ohne SecurityCheck damit ChangeCompany() funktioniert
        CrossItem: Record Item;
        CurrentItem: Record Item;
    begin
        // Puffer leeren bevor neu geladen wird
        CrossBuffer.Reset();
        CrossBuffer.DeleteAll();

        if pItemNo = '' then
            exit;

        // Setup lesen: Cross-Company aktiv oder nur aktueller Mandant?
        // Standard (kein Setup-Datensatz): nur aktueller Mandant
        if ManufacturingSetup.Get() and ManufacturingSetup.pdeCrossCompanyStockActive then begin
            // --- Cross-Company Modus: alle Mandanten durchlaufen ---
            if Companies.FindSet() then
                repeat
                    // ChangeCompany() wechselt den Datenkontext auf den Zielmandanten
                    // Der aktuelle Mandant der Session bleibt unverändert
                    CrossItem.ChangeCompany(Companies.Name);
                    CrossItem.Reset();

                    // Prüfen ob dieser Artikel beim Zielmandanten überhaupt existiert
                    if CrossItem.Get(pItemNo) then begin
                        // FlowField Inventory ohne Lagerortfilter = Summe über alle Lagerorte
                        CrossItem.CalcFields(Inventory);

                        CrossBuffer.Init();
                        CrossBuffer.CompanyName := CopyStr(Companies.Name, 1, 30);
                        CrossBuffer.ItemNo := pItemNo;
                        CrossBuffer.LocationCode := '';
                        CrossBuffer.Inventory := CrossItem.Inventory;
                        CrossBuffer.UnitOfMeasure := CrossItem."Base Unit of Measure";
                        CrossBuffer.ItemDescription := CrossItem.Description;
                        CrossBuffer.ReorderPoint := CrossItem."Reorder Point";
                        CrossBuffer.Insert();
                    end;
                until Companies.Next() = 0;
        end else begin
            // --- Einzelmandant-Modus: nur aktuellen Mandanten lesen ---
            // CompanyName() gibt den Namen des aktuellen Mandanten zurück
            if CurrentItem.Get(pItemNo) then begin
                CurrentItem.CalcFields(Inventory);

                CrossBuffer.Init();
                CrossBuffer.CompanyName := CopyStr(CompanyName(), 1, 30);
                CrossBuffer.ItemNo := pItemNo;
                CrossBuffer.LocationCode := '';
                CrossBuffer.Inventory := CurrentItem.Inventory;
                CrossBuffer.UnitOfMeasure := CurrentItem."Base Unit of Measure";
                CrossBuffer.ItemDescription := CurrentItem.Description;
                CrossBuffer.ReorderPoint := CurrentItem."Reorder Point";
                CrossBuffer.Insert();
            end;
        end;
    end;

    // --- ÖFFENTLICH: Zeilen laden ---

    /// <summary>
    /// Lädt alle offenen Bedarfe und Zugänge für einen Artikel in den LineBuffer.
    /// pInitialStock gibt den Anfangsbestand vor dem Analysezeitraum zurück.
    /// </summary>
    procedure LoadLines(
        pItemNo: Code[20];
        pLocationCode: Code[10];
        pDateFrom: Date;
        pDateTo: Date;
        var pInitialStock: Decimal;
        var LineBuffer: Record pdeMD04LineBuffer)
    var
        EntryNo: Integer;
    begin
        // Alten Pufferinhalt löschen bevor neue Daten geladen werden
        LineBuffer.Reset();
        LineBuffer.DeleteAll();

        if pItemNo = '' then
            exit;

        // Datumsgrenzen normalisieren: Standardzeitraum heute + 6 Monate
        if pDateFrom = 0D then pDateFrom := Today();
        if pDateTo = 0D then pDateTo := CalcDate('<+6M>', pDateFrom);

        EntryNo := 0;

        // Anfangsbestand vor dem Analysezeitraum berechnen
        pInitialStock := GetInitialInventory(pItemNo, pLocationCode, pDateFrom);

        // Alle Bedarfs- und Zugangsquellen einsammeln
        CollectPurchaseLines(pItemNo, pLocationCode, pDateFrom, pDateTo, LineBuffer, EntryNo);
        CollectSalesLines(pItemNo, pLocationCode, pDateFrom, pDateTo, LineBuffer, EntryNo);
        CollectProdOrderLines(pItemNo, pLocationCode, pDateFrom, pDateTo, LineBuffer, EntryNo);
        CollectProdOrderComponents(pItemNo, pLocationCode, pDateFrom, pDateTo, LineBuffer, EntryNo);
        CollectTransferLines(pItemNo, pLocationCode, pDateFrom, pDateTo, LineBuffer, EntryNo);

        // Zeilen nach Datum sortieren und laufenden Hochrechnungsbestand berechnen
        RecalcRunningBalance(pInitialStock, LineBuffer);
    end;

    // --- ÖFFENTLICH: Periodenblöcke aufbauen ---

    /// <summary>
    /// Gruppiert die geladenen Zeilen in Periodenblöcke (Tag/Woche/Monat).
    /// PeriodMode: 1=Tag, 2=Woche (Standard), 3=Monat
    /// </summary>
    procedure BuildPeriods(
        var LineBuffer: Record pdeMD04LineBuffer;
        PeriodMode: Integer;
        InitialStock: Decimal;
        var PeriodBuffer: Record pdeMD04PeriodBuffer)
    var
        EntryNo: Integer;
        PeriodStart: Date;
        PeriodEnd: Date;
        PeriodLabel: Text[30];
        RunningBalance: Decimal;
    begin
        // Alten Periodeninhalt löschen
        PeriodBuffer.Reset();
        PeriodBuffer.DeleteAll();

        EntryNo := 0;

        // Zeilen in chronologischer Reihenfolge verarbeiten (Sekundärschlüssel DateKey)
        LineBuffer.SetCurrentKey(LineBuffer.DueDate, LineBuffer.EntryNo);
        if not LineBuffer.FindSet() then
            exit;

        repeat
            // Periodengrenzen für das Datum dieser Zeile berechnen
            GetPeriodBounds(LineBuffer.DueDate, PeriodMode, PeriodStart, PeriodEnd);
            PeriodLabel := BuildPeriodLabel(PeriodStart, PeriodMode);

            // Periodenblock suchen oder neu anlegen
            PeriodBuffer.SetRange(PeriodStart, PeriodStart);
            if not PeriodBuffer.FindFirst() then begin
                // Neuen Block anlegen – EntryNo in Datumsreihenfolge
                EntryNo += 1;
                PeriodBuffer.Init();
                PeriodBuffer.EntryNo := EntryNo;
                PeriodBuffer.ItemNo := LineBuffer.ItemNo;
                PeriodBuffer.LocationCode := LineBuffer.LocationCode;
                PeriodBuffer.PeriodLabel := PeriodLabel;
                PeriodBuffer.PeriodStart := PeriodStart;
                PeriodBuffer.PeriodEnd := PeriodEnd;
                PeriodBuffer.Insert();
            end;

            // Bedarf oder Zugang in den Block aggregieren
            if LineBuffer.Quantity < 0 then
                // Abgang: als positive Bedarfsmenge summieren
                PeriodBuffer.DemandQty += Abs(LineBuffer.Quantity)
            else
                // Zugang: als Zugangsmenge summieren
                PeriodBuffer.SupplyQty += LineBuffer.Quantity;

            // Nettoveränderung = Zugang - Abgang in dieser Periode
            PeriodBuffer.NetChange := PeriodBuffer.SupplyQty - PeriodBuffer.DemandQty;
            PeriodBuffer.Modify();

            // Filter zurücksetzen für nächste Zeile
            PeriodBuffer.Reset();
        until LineBuffer.Next() = 0;

        // Zweiter Durchlauf: kumulierten Hochrechnungsbestand am Ende jeder Periode berechnen
        RunningBalance := InitialStock;
        PeriodBuffer.Reset();
        PeriodBuffer.SetCurrentKey(PeriodBuffer.EntryNo); // EntryNo = Datumsreihenfolge
        if PeriodBuffer.FindSet() then
            repeat
                RunningBalance += PeriodBuffer.NetChange;
                // Hochrechnungsbestand am Periodenende kumulativ setzen
                PeriodBuffer.ProjectedBalance := RunningBalance;
                PeriodBuffer.Modify();
            until PeriodBuffer.Next() = 0;
    end;

    // --- PRIVAT: Anfangsbestand ---

    local procedure GetInitialInventory(pItemNo: Code[20]; pLocationCode: Code[10]; pDateFrom: Date): Decimal
    var
        Item: Record Item;
    begin
        if not Item.Get(pItemNo) then
            exit(0);

        // Lagerortfilter setzen falls angegeben
        if pLocationCode <> '' then
            Item.SetRange("Location Filter", pLocationCode);

        // Bestand bis zum Tag VOR dem Analysezeitraum → Anfangsbestand
        // 0D = leeres Datum in AL; wenn ein echtes Datum gesetzt ist, einen Tag zurückgehen
        if pDateFrom <> 0D then
            Item.SetRange("Date Filter", 0D, pDateFrom - 1)
        else
            Item.SetRange("Date Filter", 0D, Today());

        // FlowField "Inventory" neu berechnen lassen
        Item.CalcFields(Inventory);
        exit(Item.Inventory);
    end;

    // --- PRIVAT: Quelldaten einsammeln ---

    local procedure CollectPurchaseLines(
        pItemNo: Code[20]; pLocationCode: Code[10];
        pDateFrom: Date; pDateTo: Date;
        var Buffer: Record pdeMD04LineBuffer; var EntryNo: Integer)
    var
        PurchLine: Record "Purchase Line";
    begin
        // Nur offene Einkaufsbestellungen mit ausstehender Menge
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("No.", pItemNo);
        if pLocationCode <> '' then
            PurchLine.SetRange("Location Code", pLocationCode);
        PurchLine.SetRange("Expected Receipt Date", pDateFrom, pDateTo);
        PurchLine.SetFilter("Outstanding Quantity", '>0');

        if PurchLine.FindSet() then
            repeat
                EntryNo += 1;
                Buffer.Init();
                Buffer.EntryNo := EntryNo;
                Buffer.ItemNo := pItemNo;
                Buffer.ItemDescription := PurchLine.Description;
                Buffer.SourceType := Buffer.SourceType::"Purchase Order";
                Buffer.DocumentNo := PurchLine."Document No.";
                Buffer.DocumentLineNo := PurchLine."Line No.";
                Buffer.DueDate := PurchLine."Expected Receipt Date";
                // Zugang: positive Menge erhöht den Bestand
                Buffer.Quantity := PurchLine."Outstanding Quantity";
                Buffer.LocationCode := PurchLine."Location Code";
                Buffer.UnitOfMeasure := PurchLine."Unit of Measure Code";
                Buffer.Insert();
            until PurchLine.Next() = 0;
    end;

    local procedure CollectSalesLines(
        pItemNo: Code[20]; pLocationCode: Code[10];
        pDateFrom: Date; pDateTo: Date;
        var Buffer: Record pdeMD04LineBuffer; var EntryNo: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        // Nur offene Auftragszeilen mit noch ausstehender Liefermenge
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", pItemNo);
        if pLocationCode <> '' then
            SalesLine.SetRange("Location Code", pLocationCode);
        SalesLine.SetRange("Shipment Date", pDateFrom, pDateTo);
        SalesLine.SetFilter("Outstanding Quantity", '>0');

        if SalesLine.FindSet() then
            repeat
                EntryNo += 1;
                Buffer.Init();
                Buffer.EntryNo := EntryNo;
                Buffer.ItemNo := pItemNo;
                Buffer.ItemDescription := SalesLine.Description;
                Buffer.SourceType := Buffer.SourceType::"Sales Order";
                Buffer.DocumentNo := SalesLine."Document No.";
                Buffer.DocumentLineNo := SalesLine."Line No.";
                Buffer.DueDate := SalesLine."Shipment Date";
                // Abgang: negative Menge verringert den Bestand
                Buffer.Quantity := -SalesLine."Outstanding Quantity";
                Buffer.LocationCode := SalesLine."Location Code";
                Buffer.UnitOfMeasure := SalesLine."Unit of Measure Code";
                Buffer.Insert();
            until SalesLine.Next() = 0;
    end;

    local procedure CollectProdOrderLines(
        pItemNo: Code[20]; pLocationCode: Code[10];
        pDateFrom: Date; pDateTo: Date;
        var Buffer: Record pdeMD04LineBuffer; var EntryNo: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Freigegebene FA-Kopfzeilen: geplanter Fertigungsausstoß
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Item No.", pItemNo);
        if pLocationCode <> '' then
            ProdOrderLine.SetRange("Location Code", pLocationCode);
        ProdOrderLine.SetRange("Due Date", pDateFrom, pDateTo);
        ProdOrderLine.SetFilter("Remaining Quantity", '>0');

        if ProdOrderLine.FindSet() then
            repeat
                EntryNo += 1;
                Buffer.Init();
                Buffer.EntryNo := EntryNo;
                Buffer.ItemNo := pItemNo;
                Buffer.ItemDescription := ProdOrderLine.Description;
                Buffer.SourceType := Buffer.SourceType::"Prod. Order Output";
                Buffer.DocumentNo := ProdOrderLine."Prod. Order No.";
                Buffer.DocumentLineNo := ProdOrderLine."Line No.";
                Buffer.DueDate := ProdOrderLine."Due Date";
                // Zugang: Fertigungsausstoß erhöht den Bestand
                Buffer.Quantity := ProdOrderLine."Remaining Quantity";
                Buffer.LocationCode := ProdOrderLine."Location Code";
                Buffer.UnitOfMeasure := ProdOrderLine."Unit of Measure Code";
                Buffer.Insert();
            until ProdOrderLine.Next() = 0;
    end;

    local procedure CollectProdOrderComponents(
        pItemNo: Code[20]; pLocationCode: Code[10];
        pDateFrom: Date; pDateTo: Date;
        var Buffer: Record pdeMD04LineBuffer; var EntryNo: Integer)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        // Freigegebene FA-Komponenten: Materialbedarf für die Produktion
        ProdOrderComp.SetRange(Status, ProdOrderComp.Status::Released);
        ProdOrderComp.SetRange("Item No.", pItemNo);
        if pLocationCode <> '' then
            ProdOrderComp.SetRange("Location Code", pLocationCode);
        ProdOrderComp.SetRange("Due Date", pDateFrom, pDateTo);
        ProdOrderComp.SetFilter("Remaining Quantity", '>0');

        if ProdOrderComp.FindSet() then
            repeat
                EntryNo += 1;
                Buffer.Init();
                Buffer.EntryNo := EntryNo;
                Buffer.ItemNo := pItemNo;
                Buffer.ItemDescription := ProdOrderComp.Description;
                Buffer.SourceType := Buffer.SourceType::"Prod. Order Component";
                Buffer.DocumentNo := ProdOrderComp."Prod. Order No.";
                Buffer.DocumentLineNo := ProdOrderComp."Line No.";
                Buffer.DueDate := ProdOrderComp."Due Date";
                // Abgang: Komponentenverbrauch verringert den Bestand
                Buffer.Quantity := -ProdOrderComp."Remaining Quantity";
                Buffer.LocationCode := ProdOrderComp."Location Code";
                Buffer.UnitOfMeasure := ProdOrderComp."Unit of Measure Code";
                Buffer.Insert();
            until ProdOrderComp.Next() = 0;
    end;

    local procedure CollectTransferLines(
        pItemNo: Code[20]; pLocationCode: Code[10];
        pDateFrom: Date; pDateTo: Date;
        var Buffer: Record pdeMD04LineBuffer; var EntryNo: Integer)
    var
        TransLine: Record "Transfer Line";
    begin
        // Transfer-Abgang: Ware verlässt diesen Lagerort (Abgang)
        if pLocationCode <> '' then begin
            TransLine.Reset();
            TransLine.SetRange("Transfer-from Code", pLocationCode);
            TransLine.SetRange("Item No.", pItemNo);
            TransLine.SetRange("Shipment Date", pDateFrom, pDateTo);
            TransLine.SetFilter("Outstanding Quantity", '>0');

            if TransLine.FindSet() then
                repeat
                    EntryNo += 1;
                    Buffer.Init();
                    Buffer.EntryNo := EntryNo;
                    Buffer.ItemNo := pItemNo;
                    Buffer.ItemDescription := TransLine.Description;
                    Buffer.SourceType := Buffer.SourceType::"Transfer Out";
                    Buffer.DocumentNo := TransLine."Document No.";
                    Buffer.DocumentLineNo := TransLine."Line No.";
                    Buffer.DueDate := TransLine."Shipment Date";
                    // Abgang: Ware verlässt diesen Lagerort
                    Buffer.Quantity := -TransLine."Outstanding Quantity";
                    Buffer.LocationCode := TransLine."Transfer-from Code";
                    Buffer.UnitOfMeasure := TransLine."Unit of Measure Code";
                    Buffer.Insert();
                until TransLine.Next() = 0;
        end;

        // Transfer-Zugang: Ware kommt an diesem Lagerort an (Zugang)
        TransLine.Reset();
        if pLocationCode <> '' then
            TransLine.SetRange("Transfer-to Code", pLocationCode);
        TransLine.SetRange("Item No.", pItemNo);
        TransLine.SetRange("Receipt Date", pDateFrom, pDateTo);
        TransLine.SetFilter("Outstanding Quantity", '>0');

        if TransLine.FindSet() then
            repeat
                // Nur Ware, die noch nicht gebucht wurde (Menge - geliefert)
                if (TransLine.Quantity - TransLine."Quantity Received") > 0 then begin
                    EntryNo += 1;
                    Buffer.Init();
                    Buffer.EntryNo := EntryNo;
                    Buffer.ItemNo := pItemNo;
                    Buffer.ItemDescription := TransLine.Description;
                    Buffer.SourceType := Buffer.SourceType::"Transfer In";
                    Buffer.DocumentNo := TransLine."Document No.";
                    Buffer.DocumentLineNo := TransLine."Line No.";
                    Buffer.DueDate := TransLine."Receipt Date";
                    // Zugang: Ware kommt an und erhöht den Bestand
                    Buffer.Quantity := TransLine.Quantity - TransLine."Quantity Received";
                    Buffer.LocationCode := TransLine."Transfer-to Code";
                    Buffer.UnitOfMeasure := TransLine."Unit of Measure Code";
                    Buffer.Insert();
                end;
            until TransLine.Next() = 0;
    end;

    // --- PRIVAT: Laufenden Hochrechnungsbestand berechnen ---

    local procedure RecalcRunningBalance(InitialStock: Decimal; var Buffer: Record pdeMD04LineBuffer)
    var
        RunningBalance: Decimal;
    begin
        RunningBalance := InitialStock;

        // Zeilen nach Datum sortiert durchlaufen (Sekundärschlüssel DateKey)
        Buffer.SetCurrentKey(Buffer.DueDate, Buffer.EntryNo);
        if Buffer.FindSet() then
            repeat
                // Hochrechnungsbestand kumulativ fortschreiben
                RunningBalance += Buffer.Quantity;
                Buffer.RunningBalance := RunningBalance;
                Buffer.Modify();
            until Buffer.Next() = 0;
    end;

    // --- PRIVAT: Periodenhelfer ---

    local procedure GetPeriodBounds(ForDate: Date; PeriodMode: Integer; var PStart: Date; var PEnd: Date)
    begin
        case PeriodMode of
            1:
                begin
                    // Tagesmodus: Periode = genau dieser Tag
                    PStart := ForDate;
                    PEnd := ForDate;
                end;
            2:
                begin
                    // Wochenmodus: Montag bis Sonntag der betreffenden Woche
                    // Date2DWY(Date, 1) = Wochentag (1=Montag ... 7=Sonntag)
                    PStart := ForDate - (Date2DWY(ForDate, 1) - 1);
                    PEnd := PStart + 6;
                end;
            3:
                begin
                    // Monatsmodus: 1. bis letzter Tag des Monats
                    // DMY2Date(1, Monat, Jahr) = erster Tag des Monats
                    PStart := DMY2Date(1, Date2DMY(ForDate, 2), Date2DMY(ForDate, 3));
                    // <CM> = Current Month End = letzter Tag des Monats
                    PEnd := CalcDate('<CM>', PStart);
                end;
            else begin
                // Fallback: Wochenmodus
                PStart := ForDate - (Date2DWY(ForDate, 1) - 1);
                PEnd := PStart + 6;
            end;
        end;
    end;

    local procedure BuildPeriodLabel(PeriodStart: Date; PeriodMode: Integer): Text[30]
    begin
        case PeriodMode of
            1:
                // Tag: "14.03.2026"
                exit(CopyStr(Format(PeriodStart, 0, '<Day,2>.<Month,2>.<Year4>'), 1, 30));
            2:
                // Woche: "KW 11 / 2026" – Date2DWY(Date, 2) = Kalenderwochennummer
                exit(CopyStr('KW ' + Format(Date2DWY(PeriodStart, 2)) + ' / ' + Format(Date2DMY(PeriodStart, 3)), 1, 30));
            3:
                // Monat: "Mar 2026" – Kurzname des Monats
                exit(CopyStr(Format(PeriodStart, 0, '<Month Text,3> <Year4>'), 1, 30));
            else
                exit(CopyStr(Format(PeriodStart, 0, '<Day,2>.<Month,2>.<Year4>'), 1, 30));
        end;
    end;
}
