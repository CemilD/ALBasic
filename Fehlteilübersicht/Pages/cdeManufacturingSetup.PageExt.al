pageextension 50001 cdeManufacturingSetupExt extends "Manufacturing Setup"
{
    layout
    {
        addlast(Content)
        {
            group(cdeShortageGroup)
            {
                Caption = 'Fehlteilanalyse';
                field(cdeShortage; Rec.cdeShortage)
                {
                    ApplicationArea = All;
                }
                field(cdeTimelineWeeksBefore; Rec.cdeTimelineWeeksBefore)
                {
                    ApplicationArea = All;
                    Caption = 'Zeitschiene Wochen vorher';
                    ToolTip = 'Anzahl der Wochen vor dem FA-Arbeitsbeginn, die in der Zeitschiene angezeigt werden.';
                }
                field(cdeTimelineWeeksAfter; Rec.cdeTimelineWeeksAfter)
                {
                    ApplicationArea = All;
                    Caption = 'Zeitschiene Wochen nachher';
                    ToolTip = 'Anzahl der Wochen nach dem FA-Arbeitsbeginn, die in der Zeitschiene angezeigt werden.';
                }
                field(pdeCrossCompanyStockActive; Rec.pdeCrossCompanyStockActive)
                {
                    ApplicationArea = All;
                    Caption = 'Cross-Company Stock Active';
                    ToolTip = 'Aktiviert die mandantenübergreifende Bestandsanzeige in der Bestandsübersicht. Wenn deaktiviert, wird nur der aktuelle Mandant angezeigt.';
                }
            }
        }
    }
}