table 70100 "PLI Import Log"
{
    Caption = 'Price List Import Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Import DateTime"; DateTime)
        {
            Caption = 'Import Date/Time';
        }
        field(3; "User ID"; Code[50])
        {
            Caption = 'User ID';
        }
        field(4; "Company Filter"; Text[30])
        {
            Caption = 'Company Filter';
        }
        field(5; "File Name"; Text[250])
        {
            Caption = 'File Name';
        }
        field(6; "Total Lines"; Integer)
        {
            Caption = 'Total Lines';
        }
        field(7; "Imported Lines"; Integer)
        {
            Caption = 'Imported Lines';
        }
        field(8; "Error Lines"; Integer)
        {
            Caption = 'Error Lines';
        }
        field(9; Status; Enum "PLI Import Status")
        {
            Caption = 'Status';
        }
        field(10; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
        }
        field(11; "JSON Content"; Blob)
        {
            Caption = 'JSON Content';
        }
        field(12; "Price List Code"; Code[20])
        {
            Caption = 'Price List Code';
            ToolTip = 'Optionaler Preislistencode. Leer = Nummernserie aus Deb. Einrichtung wird gezogen.';
            TableRelation = "Price List Header".Code;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(K2; "Import DateTime") { }
    }
}
