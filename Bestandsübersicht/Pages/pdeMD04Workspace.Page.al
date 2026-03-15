page 50004 pdeMD04Workspace
{
    // Hauptseite: MD04 Simple – Bedarfs- und Bestandsübersicht
    // Zeigt alle offenen Bedarfe und Zugänge für einen Artikel mit laufendem Hochrechnungsbestand
    Caption = 'PDE MD04 Simple - Stock/Requirements List';
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Tasks;
    // Temporäre Puffertabelle als Datenquelle: Zeilen werden nur im RAM gehalten
    SourceTable = pdeMD04LineBuffer;
    SourceTableTemporary = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    AboutTitle = 'MD04 Simple - Bestandsübersicht';
    AboutText = 'Zeigt alle offenen Bedarfe und Zugänge für einen Artikel sortiert nach Datum. Der Hochrechnungsbestand gibt den erwarteten Bestand nach jeder Bewegung an.';

    layout
    {
        area(Content)
        {
            // Filterbereich: Auswahl des Artikels und Analysezeitraums
            group(GrpSelection)
            {
                Caption = 'Selection';

                field(ItemNoFilter; ItemNoFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Item No.';
                    // TableRelation für Lookup-Funktion auf die Artikelliste
                    TableRelation = Item;
                    ToolTip = 'Artikelnummer für die Bestandsanalyse eingeben oder auswählen.';

                    trigger OnValidate()
                    begin
                        // Bei Artikelwechsel bisherige Ergebnisse löschen
                        ClearResults();
                        // Cross-Company Bestand sofort beim Artikelwechsel laden
                        // damit der Benutzer schnell sieht ob der Artikel in anderen Mandanten verfügbar ist
                        if ItemNoFilter <> '' then
                            CurrPage.CrossCompanyStock.Page.LoadCrossCompanyStock(ItemNoFilter);
                    end;
                }
                field(LocationFilter; LocationFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Location';
                    TableRelation = Location;
                    ToolTip = 'Lagerort für die Analyse. Leer lassen für alle Lagerorte.';
                }
                field(DateFromFilter; DateFromFilter)
                {
                    ApplicationArea = All;
                    Caption = 'From Date';
                    ToolTip = 'Startdatum des Analysezeitraums.';
                }
                field(DateToFilter; DateToFilter)
                {
                    ApplicationArea = All;
                    Caption = 'To Date';
                    ToolTip = 'Enddatum des Analysezeitraums.';
                }
                // Anzeige des aktuellen Hochrechnungsbestands am Periodenbeginn (schreibgeschützt)
                field(InitialStockDisplay; InitialStock)
                {
                    ApplicationArea = All;
                    Caption = 'Initial Stock';
                    Editable = false;
                    ToolTip = 'Lagerbestand am Tag vor dem Startdatum (Ausgangspunkt der Hochrechnung).';
                }
            }

            // Bedarfs- und Zugangsliste: eine Zeile pro Beleg/Bewegung
            repeater(Lines)
            {
                field(DueDate; Rec.DueDate)
                {
                    ApplicationArea = All;
                    Caption = 'Date';
                    ToolTip = 'Datum des Bedarfs oder Zugangs.';
                    StyleExpr = LineStyle;
                }
                field(SourceType; Rec.SourceType)
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                    // Belegart: Purchase Order, Sales Order, Prod. Order usw.
                    ToolTip = 'Art des Belegs (Bestellung, Auftrag, FA, Transfer).';
                    StyleExpr = LineStyle;
                }
                field(DocumentNo; Rec.DocumentNo)
                {
                    ApplicationArea = All;
                    Caption = 'Document No.';
                    ToolTip = 'Belegnummer des zugehörigen Dokuments.';
                    StyleExpr = LineStyle;
                }
                field(ItemDescription; Rec.ItemDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    StyleExpr = LineStyle;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Quantity';
                    // Positiv = Zugang (grün), Negativ = Abgang (rot)
                    ToolTip = 'Menge: Positiv = Zugang (erhöht Bestand), Negativ = Abgang (verringert Bestand).';
                    StyleExpr = LineStyle;
                }
                field(UnitOfMeasure; Rec.UnitOfMeasure)
                {
                    ApplicationArea = All;
                    Caption = 'UoM';
                    StyleExpr = LineStyle;
                }
                field(RunningBalance; Rec.RunningBalance)
                {
                    ApplicationArea = All;
                    Caption = 'Projected Stock';
                    // Kumulierter Hochrechnungsbestand nach dieser Zeile
                    ToolTip = 'Erwarteter Lagerbestand nach dieser Bewegung (kumuliert).';
                    StyleExpr = LineStyle;
                }
                field(LocationCode; Rec.LocationCode)
                {
                    ApplicationArea = All;
                    Caption = 'Location';
                    StyleExpr = LineStyle;
                }
            }
        }

        area(FactBoxes)
        {
            // Periodenübersicht rechts: fasst Bedarf/Zugang pro Periode zusammen
            part(PeriodTotals; pdeMD04PeriodTotalsPart)
            {
                ApplicationArea = All;
                Caption = 'Period Totals';
            }
            // Materialinfo FactBox: folgt automatisch via SubPageLink dem aktuellen Artikel
            part(MaterialInfo; pdeMD04MaterialInfoPart)
            {
                ApplicationArea = All;
                Caption = 'Material Info';
                // SubPageLink: Item."No." wird automatisch mit ItemNo der aktuellen Zeile verknüpft
                SubPageLink = "No." = field(ItemNo);
            }

            // Cross-Company FactBox: zeigt Bestand des Artikels in allen Mandanten
            part(CrossCompanyStock; pdeMD04CrossCompanyPart)
            {
                ApplicationArea = All;
                Caption = 'Cross-Company Stock';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                Caption = 'Refresh';
                ApplicationArea = All;
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Lädt alle Bedarfe und Zugänge für den ausgewählten Artikel und Zeitraum neu.';

                trigger OnAction()
                begin
                    RefreshData();
                end;
            }
            action(ResetFilters)
            {
                Caption = 'Reset';
                ApplicationArea = All;
                Image = ClearFilter;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Setzt alle Filter zurück und löscht die Ergebnisliste.';

                trigger OnAction()
                begin
                    // Artikel und Lagerort zurücksetzen
                    ItemNoFilter := '';
                    LocationFilter := '';
                    // Standardzeitraum wiederherstellen
                    DateFromFilter := Today();
                    DateToFilter := CalcDate('<+6M>', Today());
                    InitialStock := 0;
                    ClearResults();
                end;
            }
        }

        area(Navigation)
        {
            group(PeriodGroup)
            {
                Caption = 'Period View';
                Image = Calendar;
                ToolTip = 'Wählen Sie die Granularität der Periodenübersicht.';

                action(PeriodDay)
                {
                    Caption = 'Days';
                    ApplicationArea = All;
                    Image = Calendar;
                    ToolTip = 'Periodenübersicht nach Tagen gruppieren.';

                    trigger OnAction()
                    begin
                        // PeriodMode 1 = Tagesmodus
                        PeriodMode := 1;
                        RefreshPeriods();
                    end;
                }
                action(PeriodWeek)
                {
                    Caption = 'Weeks';
                    ApplicationArea = All;
                    Image = CalendarWorkcenter;
                    ToolTip = 'Periodenübersicht nach Kalenderwochen gruppieren (Standard).';

                    trigger OnAction()
                    begin
                        // PeriodMode 2 = Wochenmodus (Standard)
                        PeriodMode := 2;
                        RefreshPeriods();
                    end;
                }
                action(PeriodMonth)
                {
                    Caption = 'Months';
                    ApplicationArea = All;
                    Image = CalendarMachine;
                    ToolTip = 'Periodenübersicht nach Kalendermonaten gruppieren.';

                    trigger OnAction()
                    begin
                        // PeriodMode 3 = Monatsmodus
                        PeriodMode := 3;
                        RefreshPeriods();
                    end;
                }
            }
        }
    }

    // Beim Öffnen der Seite: Standardwerte setzen
    trigger OnOpenPage()
    begin
        DateFromFilter := Today();
        DateToFilter := CalcDate('<+6M>', Today());
        // Standard: Wochenansicht in der Periodenübersicht
        PeriodMode := 2;
    end;

    // Pro Zeile: Zeilenstil basierend auf Bewegungsart und Bestandssituation setzen
    trigger OnAfterGetRecord()
    begin
        if Rec.Quantity < 0 then
            // Abgang (Bedarf): rot markieren
            LineStyle := 'Unfavorable'
        else
            if Rec.RunningBalance < 0 then
                // Zugang, aber Bestand immer noch negativ: gelb (Warnung)
                LineStyle := 'Attention'
            else
                // Zugang mit positivem Bestand: grün
                LineStyle := 'Favorable';
    end;

    var
        // Filtervariablen – nicht in der Tabelle gespeichert, nur auf der Seite
        ItemNoFilter: Code[20];
        LocationFilter: Code[10];
        DateFromFilter: Date;
        DateToFilter: Date;
        // Periodenmodus: 1=Tag, 2=Woche, 3=Monat
        PeriodMode: Integer;
        // Anfangsbestand vor dem Analysezeitraum (wird beim Laden berechnet)
        InitialStock: Decimal;
        // Zeilenstil pro Datensatz (gesetzt in OnAfterGetRecord)
        LineStyle: Text;

    // Alle Daten neu laden und Anzeige aktualisieren
    local procedure RefreshData()
    var
        Mgt: Codeunit pdeMD04Mgt;
    begin
        // Eingabe prüfen: Artikelnummer ist Pflichtfeld
        if ItemNoFilter = '' then begin
            Message('Please enter an Item No. to analyze.');
            exit;
        end;

        // Puffertabelle leeren und neu befüllen
        Rec.Reset();
        Rec.DeleteAll();

        // Codeunit lädt alle Bedarfe/Zugänge und berechnet Hochrechnungsbestand
        Mgt.LoadLines(ItemNoFilter, LocationFilter, DateFromFilter, DateToFilter, InitialStock, Rec);

        // Cursor auf die erste Zeile setzen für korrekte Anzeige
        if Rec.FindFirst() then;

        // Periodenübersicht auf Basis der geladenen Zeilen aufbauen
        CurrPage.PeriodTotals.Page.LoadPeriods(Rec, PeriodMode, InitialStock);

        // Cross-Company Bestand neu laden (aktuelle Bestände aus allen Mandanten)
        CurrPage.CrossCompanyStock.Page.LoadCrossCompanyStock(ItemNoFilter);

        // Seite neu zeichnen ohne zu speichern
        CurrPage.Update(false);
    end;

    // Nur Periodenübersicht neu aufbauen ohne Daten neu zu laden (bei Periodenmodus-Wechsel)
    local procedure RefreshPeriods()
    begin
        // Nur ausführen wenn bereits Daten geladen sind
        if Rec.IsEmpty() then
            exit;

        CurrPage.PeriodTotals.Page.LoadPeriods(Rec, PeriodMode, InitialStock);
        CurrPage.Update(false);
    end;

    // Ergebnisliste und Anfangsbestand zurücksetzen
    local procedure ClearResults()
    begin
        Rec.Reset();
        Rec.DeleteAll();
        InitialStock := 0;
        CurrPage.Update(false);
    end;
}
