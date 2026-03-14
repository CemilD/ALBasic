table 50003 pdeMD04LineBuffer
{
    DataClassification = CustomerContent;
    Caption = 'PDE MD04 Simple - Line Buffer';
    // Buffer table: nur im RAM gehalten, nie in die Datenbank geschrieben
    ReplicateData = false;

    fields
    {
        field(1; EntryNo; Integer)
        {
            Caption = 'Entry No.';
            // Primärschlüssel – wird nach dem Laden nach Datum neu sortiert
            Editable = false;
        }
        field(2; ItemNo; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
            Editable = false;
        }
        field(3; ItemDescription; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(4; SourceType; Option)
        {
            Caption = 'Source Type';
            // Art des Belegs: woher kommt die Bewegung
            OptionMembers = " ",Inventory,"Purchase Order","Sales Order","Prod. Order Output","Prod. Order Component","Transfer In","Transfer Out";
            OptionCaption = ' ,Inventory,Purchase Order,Sales Order,Prod. Order Output,Prod. Order Component,Transfer In,Transfer Out';
            Editable = false;
        }
        field(5; DocumentNo; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(6; DocumentLineNo; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(7; DueDate; Date)
        {
            Caption = 'Date';
            // Datum des Bedarfs oder Zugangs
            Editable = false;
        }
        field(8; Quantity; Decimal)
        {
            Caption = 'Quantity';
            // Positiv = Zugang (erhöht Bestand), Negativ = Abgang (verringert Bestand)
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(9; RunningBalance; Decimal)
        {
            Caption = 'Projected Stock';
            // Kumulierter Hochrechnungsbestand nach dieser Zeile
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(10; LocationCode; Code[10])
        {
            Caption = 'Location';
            TableRelation = Location;
            Editable = false;
        }
        field(11; UnitOfMeasure; Code[10])
        {
            Caption = 'Unit of Measure';
            TableRelation = "Unit of Measure";
            Editable = false;
        }
    }

    keys
    {
        key(PK; EntryNo)
        {
            Clustered = true;
        }
        // Sekundärschlüssel für chronologische Sortierung beim Berechnen des Laufenden Bestands
        key(DateKey; DueDate, EntryNo) { }
    }
}
