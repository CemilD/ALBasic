table 70101 "PLI Import Log Line"
{
    Caption = 'Price List Import Log Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            TableRelation = "PLI Import Log"."Entry No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
        }
        field(4; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(5; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
        }
        field(6; "Minimum Quantity"; Decimal)
        {
            Caption = 'Minimum Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(7; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            DecimalPlaces = 2 : 5;
        }
        field(8; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(9; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(10; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
        }
        field(11; Status; Enum "PLI Line Import Status")
        {
            Caption = 'Status';
        }
        field(12; "Error Message"; Text[500])
        {
            Caption = 'Error Message';
        }
        field(13; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
        }
    }

    keys
    {
        key(PK; "Entry No.", "Line No.")
        {
            Clustered = true;
        }
    }
}
