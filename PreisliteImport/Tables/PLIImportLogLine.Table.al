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
        field(14; "Price List Code"; Code[20])
        {
            Caption = 'Price List Code';
            ToolTip = 'Preislistencode der verwendeten oder neu erstellten Preisliste.';
        }
        /// <summary>Mirrors Price List Line "Work Type Code". Relevant for Resource lines; usually empty for Items.</summary>
        field(15; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
        }
        /// <summary>Mirrors Price List Line "Allow Line Disc."</summary>
        field(16; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
            InitValue = true;
        }
        /// <summary>Mirrors Price List Line "Line Discount %"</summary>
        field(17; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 100;
        }
        /// <summary>Mirrors Price List Line "Allow Invoice Disc."</summary>
        field(18; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            InitValue = true;
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
