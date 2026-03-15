table 50004 pdeMD04PeriodBuffer
{
    DataClassification = CustomerContent;
    Caption = 'PDE MD04 Simple - Period Buffer';
    // Buffer table: nur im RAM gehalten, nie gespeichert
    ReplicateData = false;

    fields
    {
        field(1; EntryNo; Integer)
        {
            Caption = 'Entry No.';
            // Vergabe in chronologischer Reihenfolge beim Aufbau der Perioden
            Editable = false;
        }
        field(2; ItemNo; Code[20])
        {
            Caption = 'Item No.';
            Editable = false;
        }
        field(3; LocationCode; Code[10])
        {
            Caption = 'Location';
            Editable = false;
        }
        field(4; PeriodLabel; Text[30])
        {
            Caption = 'Period';
            // Angezeigter Bezeichner z.B. "KW 11 / 2026" oder "Mar 2026"
            Editable = false;
        }
        field(5; PeriodStart; Date)
        {
            Caption = 'From';
            Editable = false;
        }
        field(6; PeriodEnd; Date)
        {
            Caption = 'To';
            Editable = false;
        }
        field(7; DemandQty; Decimal)
        {
            Caption = 'Demand';
            // Gesamtbedarf in dieser Periode (als positive Zahl dargestellt)
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(8; SupplyQty; Decimal)
        {
            Caption = 'Supply';
            // Gesamtzugang in dieser Periode
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(9; NetChange; Decimal)
        {
            Caption = 'Net Change';
            // Nettoveränderung = Zugang - Abgang in dieser Periode
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(10; ProjectedBalance; Decimal)
        {
            Caption = 'Projected Balance';
            // Kumulierter Hochrechnungsbestand am Ende der Periode
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
    }

    keys
    {
        key(PK; EntryNo) { Clustered = true; }
        // Zum Finden einer Periode anhand ihres Startdatums
        key(PeriodKey; PeriodStart) { }
    }
}
