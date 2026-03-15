page 50005 pdeMD04PeriodTotalsPart
{
    PageType = ListPart;
    Caption = 'Period Totals';
    SourceTable = pdeMD04PeriodBuffer;
    // Temporäre Tabelle: Daten nur im RAM, nie gespeichert
    SourceTableTemporary = true;
    Editable = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            // Jede Zeile repräsentiert einen Periodenblock (Tag/Woche/Monat)
            repeater(Periods)
            {
                field(PeriodLabel; Rec.PeriodLabel)
                {
                    ApplicationArea = All;
                    Caption = 'Period';
                    ToolTip = 'Label der Periode (z.B. KW 11 / 2026 oder Mar 2026).';
                    // StyleExpr färbt die Zeile je nach Bestandssituation
                    StyleExpr = PeriodStyle;
                }
                field(DemandQty; Rec.DemandQty)
                {
                    ApplicationArea = All;
                    Caption = 'Demand';
                    ToolTip = 'Gesamtbedarf in dieser Periode.';
                    StyleExpr = PeriodStyle;
                }
                field(SupplyQty; Rec.SupplyQty)
                {
                    ApplicationArea = All;
                    Caption = 'Supply';
                    ToolTip = 'Gesamtzugang in dieser Periode.';
                    StyleExpr = PeriodStyle;
                }
                field(NetChange; Rec.NetChange)
                {
                    ApplicationArea = All;
                    Caption = 'Net Change';
                    ToolTip = 'Nettoveränderung (Zugang - Abgang) in dieser Periode.';
                    StyleExpr = PeriodStyle;
                }
                field(ProjectedBalance; Rec.ProjectedBalance)
                {
                    ApplicationArea = All;
                    Caption = 'Projected Balance';
                    ToolTip = 'Kumulierter Hochrechnungsbestand am Ende der Periode.';
                    StyleExpr = PeriodStyle;
                }
            }
        }
    }

    var
        // Zeilenstil pro Periode: gesetzt in OnAfterGetRecord
        PeriodStyle: Text;

    trigger OnAfterGetRecord()
    begin
        // Rot = Hochrechnungsbestand wird negativ (Fehlmenge)
        // Gelb = Bedarf übersteigt Zugang, aber noch positiver Bestand
        // Grün = Zugang deckt Bedarf
        if Rec.ProjectedBalance < 0 then
            PeriodStyle := 'Unfavorable'
        else
            if Rec.DemandQty > Rec.SupplyQty then
                PeriodStyle := 'Attention'
            else
                PeriodStyle := 'Favorable';
    end;

    /// <summary>
    /// Wird von der Workspace-Page aufgerufen wenn Daten neu geladen oder die Periodenansicht geändert wird.
    /// Baut Periodenblöcke aus den übergebenen Zeilen auf.
    /// </summary>
    procedure LoadPeriods(var LineBuffer: Record pdeMD04LineBuffer; PeriodMode: Integer; InitialStock: Decimal)
    var
        Mgt: Codeunit pdeMD04Mgt;
    begin
        // Puffer leeren und neu aufbauen
        Rec.Reset();
        Rec.DeleteAll();

        // Codeunit baut die Periodenblöcke aus den Zeilen auf
        Mgt.BuildPeriods(LineBuffer, PeriodMode, InitialStock, Rec);

        // Cursor auf erste Periode setzen
        if Rec.FindFirst() then;

        // FactBox-Anzeige aktualisieren
        CurrPage.Update(false);
    end;
}
