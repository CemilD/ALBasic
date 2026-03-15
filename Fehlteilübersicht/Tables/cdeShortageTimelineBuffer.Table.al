table 50002 cdeShortageTimelineBuffer
{
    DataClassification = CustomerContent;
    Caption = 'CDE Shortage Timeline';
    // Nur im RAM gehalten, wird nie in die Datenbank geschrieben
    ReplicateData = false;

    fields
    {
        field(1; ItemNo; Code[20])
        {
            Caption = 'Artikel';
            Editable = false;
        }
        field(2; WeekNo; Integer)
        {
            // Wochennummer relativ zur aktuellen Woche (0 = aktuelle Woche, 1 = nächste, usw.)
            Caption = 'Woche';
            Editable = false;
        }
        field(3; PeriodLabel; Text[50])
        {
            // Angezeigtes Label z.B. "KW 12  (17.03 - 23.03)"
            Caption = 'Zeitraum';
            Editable = false;
        }
        field(4; PeriodStart; Date)
        {
            Caption = 'Von';
            Editable = false;
        }
        field(5; PeriodEnd; Date)
        {
            Caption = 'Bis';
            Editable = false;
        }
        field(6; DemandQty; Decimal)
        {
            // Summe der verbleibenden Bedarfsmengen aller FA-Komponenten in dieser Woche
            Caption = 'Bedarf';
            Editable = false;
            DecimalPlaces = 0 : 5;
        }
        field(7; RunningBalance; Decimal)
        {
            // Laufender Bestand = Anfangsbestand - kumulierter Bedarf bis zu dieser Woche
            Caption = 'Bestand';
            Editable = false;
            DecimalPlaces = 0 : 5;
        }
        field(8; LocationCode; Code[10])
        {
            Caption = 'Lagerort';
            Editable = false;
        }
    }

    keys
    {
        // Zusammengesetzter PK: Artikel + Wochennummer
        key(PK; ItemNo, WeekNo)
        {
            Clustered = true;
        }
    }
}
