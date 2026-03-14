page 50003 cdeShortageTimelinePart
{
    PageType = ListPart;
    Caption = 'Zeitschiene';
    SourceTable = cdeShortageTimelineBuffer;
    // Temporär: Daten werden nur im RAM gehalten, nie gespeichert
    SourceTableTemporary = true;
    Editable = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            // Jede Zeile repräsentiert einen Wochenblock in der Zeitschiene
            repeater(TimelineBlocks)
            {
                field(PeriodLabel; Rec.PeriodLabel)
                {
                    ApplicationArea = All;
                    Caption = 'Zeitraum';
                    ToolTip = 'Kalenderwoche und Datumsbereich dieses Blocks';
                    StyleExpr = BlockStyle;
                }
                field(DemandQty; Rec.DemandQty)
                {
                    ApplicationArea = All;
                    Caption = 'Bedarf';
                    ToolTip = 'Summe der Bedarfsmengen aller FA-Komponenten in dieser Woche';
                    StyleExpr = BlockStyle;
                }
                field(RunningBalance; Rec.RunningBalance)
                {
                    ApplicationArea = All;
                    Caption = 'Bestand';
                    ToolTip = 'Laufender Bestand nach Abzug des kumulierten Bedarfs';
                    StyleExpr = BlockStyle;
                }
            }
        }
    }

    var
        // Wird pro Zeile in OnAfterGetRecord gesetzt um den Block einzufärben
        BlockStyle: Text;

    trigger OnAfterGetRecord()
    begin
        // Rot = Bestand unter 0 (nicht gedeckt), Gelb = Bedarf vorhanden aber noch positiv, Grün = keine Fehlmenge
        if Rec.RunningBalance < 0 then
            BlockStyle := 'Unfavorable'
        else
            if Rec.DemandQty > 0 then
                BlockStyle := 'Attention'
            else
                BlockStyle := 'Favorable';
    end;

    /// <summary>
    /// Wird von der Hauptpage bei OnAfterGetRecord aufgerufen.
    /// Berechnet Wochen-Blöcke für den ausgewählten Artikel und aktualisiert die Zeitschiene.
    /// </summary>
    procedure LoadTimeline(pItemNo: Code[20]; pLocationCode: Code[10]; pProdOrderFilter: Text; pStartingDate: Date)
    var
        ProdOrderComp: Record "Prod. Order Component";
        ManufacturingSetup: Record "Manufacturing Setup";
        Item: Record Item;
        RefMonday: Date;
        WeekStart: Date;
        WeekEnd: Date;
        DemandThisWeek: Decimal;
        RunningBalance: Decimal;
        WeeksBefore: Integer;
        WeeksAfter: Integer;
        TotalWeeks: Integer;
        i: Integer;
        DayOffset: Integer;
    begin
        // Bestehende Zeitschiene leeren bevor neue aufgebaut wird
        Rec.Reset();
        Rec.DeleteAll();

        // Ohne Artikel keine Zeitschiene anzeigen
        if pItemNo = '' then begin
            CurrPage.Update(false);
            exit;
        end;

        // Einstellungen aus der Produktionseinrichtung lesen
        // Standard: 3 Wochen vorher und 3 Wochen nachher wenn Setup nicht gefunden
        WeeksBefore := 3;
        WeeksAfter := 3;
        if ManufacturingSetup.Get() then begin
            if ManufacturingSetup.cdeTimelineWeeksBefore > 0 then
                WeeksBefore := ManufacturingSetup.cdeTimelineWeeksBefore;
            if ManufacturingSetup.cdeTimelineWeeksAfter > 0 then
                WeeksAfter := ManufacturingSetup.cdeTimelineWeeksAfter;
        end;
        TotalWeeks := WeeksBefore + WeeksAfter;

        // Referenzdatum: Montag der Woche des FA-Arbeitsbeginns
        // Fallback auf heute wenn kein Startdatum am FA vorhanden
        if pStartingDate = 0D then
            pStartingDate := Today();
        DayOffset := Date2DWY(pStartingDate, 1) - 1;  // 1 = Montag
        RefMonday := pStartingDate - DayOffset;

        // Anfangsbestand des Artikels berechnen – Stichtag: Beginn der ersten anzuzeigenden Woche
        if Item.Get(pItemNo) then begin
            Item.SetRange("Location Filter", pLocationCode);
            Item.SetRange("Date Filter", RefMonday - (WeeksBefore * 7));
            // CalcFields berechnet das FlowField "Inventory" neu
            Item.CalcFields(Inventory);
            RunningBalance := Item.Inventory;
        end;

        // Wochenblöcke aufbauen: WeeksBefore Wochen vor Arbeitsbeginn bis WeeksAfter Wochen danach
        // i = 0 entspricht der ersten Woche (= WeeksBefore Wochen vor dem Arbeitsbeginn)
        for i := 0 to TotalWeeks - 1 do begin
            WeekStart := RefMonday - (WeeksBefore * 7) + (i * 7);
            WeekEnd := WeekStart + 6;
            DemandThisWeek := 0;

            // Bedarf aus FA-Komponenten für diesen Artikel in dieser Woche summieren
            ProdOrderComp.Reset();
            ProdOrderComp.SetRange(Status, ProdOrderComp.Status::Released);
            ProdOrderComp.SetFilter("Prod. Order No.", pProdOrderFilter);
            ProdOrderComp.SetRange("Item No.", pItemNo);
            ProdOrderComp.SetRange("Location Code", pLocationCode);
            ProdOrderComp.SetRange("Due Date", WeekStart, WeekEnd);
            if ProdOrderComp.FindSet() then
                repeat
                    DemandThisWeek += ProdOrderComp."Remaining Quantity";
                until ProdOrderComp.Next() = 0;

            // Laufenden Bestand nach Abzug des Wochenbedarfs aktualisieren
            RunningBalance -= DemandThisWeek;

            // Block-Zeile in den temporären Puffer schreiben
            Rec.Init();
            Rec.ItemNo := pItemNo;
            // WeekNo: negativ = vor Arbeitsbeginn, 0 = Arbeitswoche, positiv = danach
            Rec.WeekNo := i - WeeksBefore;
            // Label: "KW 12  (17.03 - 23.03)" – Arbeitsbeginnwoche wird mit * markiert
            Rec.PeriodLabel := 'KW ' + Format(Date2DWY(WeekStart, 2)) + '  (' +
                                Format(WeekStart, 0, '<Day,2>') + '.' + Format(WeekStart, 0, '<Month,2>') +
                                ' - ' +
                                Format(WeekEnd, 0, '<Day,2>') + '.' + Format(WeekEnd, 0, '<Month,2>') + ')';
            // Arbeitsbeginnwoche mit * kennzeichnen damit sie sofort erkennbar ist
            if Rec.WeekNo = 0 then
                Rec.PeriodLabel := '* ' + Rec.PeriodLabel;
            Rec.PeriodStart := WeekStart;
            Rec.PeriodEnd := WeekEnd;
            Rec.DemandQty := DemandThisWeek;
            Rec.RunningBalance := RunningBalance;
            Rec.LocationCode := pLocationCode;
            Rec.Insert();
        end;

        // Part-Page neu zeichnen ohne zu speichern
        CurrPage.Update(false);
    end;
}
