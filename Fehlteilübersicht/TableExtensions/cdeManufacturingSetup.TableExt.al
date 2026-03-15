tableextension 50000 cdeManufacturingSetup extends "Manufacturing Setup"
{
    fields
    {
        field(50000; cdeShortage; boolean)
        {
            Caption = 'Shortage active', Comment = 'DEU= Fehlteilanalyse aktiv';
        }
        field(50001; cdeTimelineWeeksBefore; Integer)
        {
            // Anzahl der Wochen VOR dem FA-Arbeitsbeginn die in der Zeitschiene angezeigt werden
            Caption = 'Zeitschiene Wochen vorher';
            MinValue = 0;
            MaxValue = 12;
            InitValue = 3;
        }
        field(50002; cdeTimelineWeeksAfter; Integer)
        {
            // Anzahl der Wochen NACH dem FA-Arbeitsbeginn die in der Zeitschiene angezeigt werden
            Caption = 'Zeitschiene Wochen nachher';
            MinValue = 0;
            MaxValue = 12;
            InitValue = 3;
        }
        field(50003; pdeCrossCompanyStockActive; Boolean)
        {
            // Wenn aktiv: Bestandsabfrage läuft über alle Mandanten (Cross-Company)
            // Wenn inaktiv: nur der aktuelle Mandant wird berücksichtigt
            Caption = 'Cross-Company Stock Active';
            InitValue = false;
        }
    }

}