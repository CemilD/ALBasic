table 50006 cdeShortageItemBOMBuffer
{
    DataClassification = CustomerContent;
    Caption = 'CDE Shortage Item BOM Buffer';
    // Nur im RAM gehalten, wird nie in die Datenbank geschrieben
    ReplicateData = false;

    fields
    {
        field(1; EntryNo; Integer)
        {
            Caption = 'Lfd. Nr.';
            Editable = false;
        }
        field(2; Level; Integer)
        {
            // Stücklistenebene: 0 = direkter Bestandteil des markierten Artikels
            Caption = 'Ebene';
            Editable = false;
        }
        field(3; ParentItemNo; Code[20])
        {
            Caption = 'Übergeord. Artikel';
            Editable = false;
        }
        field(4; ItemNo; Code[20])
        {
            Caption = 'Artikelnr.';
            TableRelation = Item;
            Editable = false;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Beschreibung';
            Editable = false;
        }
        field(6; QtyPerParent; Decimal)
        {
            Caption = 'Menge je';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(7; UOM; Code[10])
        {
            Caption = 'ME';
            TableRelation = "Unit of Measure";
            Editable = false;
        }
        field(8; HasBOM; Boolean)
        {
            // Gibt an ob dieser Artikel selbst eine Fertigungsstückliste besitzt
            Caption = 'Hat Stückliste';
            Editable = false;
        }
    }

    keys
    {
        // Reihenfolge über EntryNo → Tiefensuche ergibt automatisch korrekte Baumreihenfolge
        key(PK; EntryNo)
        {
            Clustered = true;
        }
    }
}
