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
        /// <summary>Price list description carried from JSON priceListHeader. Used for auto-creating the header.</summary>
        field(19; "PL Description"; Text[100])
        {
            Caption = 'Preislisten-Beschreibung (JSON)';
        }
        /// <summary>Source type from JSON priceListHeader.sourceType (e.g. 'Customer', 'AllCustomers').</summary>
        field(20; "PL Source Type"; Text[30])
        {
            Caption = 'Preisliste Quelle Typ (JSON)';
        }
        /// <summary>Source No. from JSON priceListHeader.sourceNo.</summary>
        field(21; "PL Source No."; Code[20])
        {
            Caption = 'Preisliste Quelle Nr. (JSON)';
        }
        /// <summary>Currency from JSON priceListHeader.currency.</summary>
        field(22; "PL Currency Code"; Code[10])
        {
            Caption = 'Preisliste Waehrungscode (JSON)';
        }
        field(23; "PL VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'Preisliste MwSt.-Geschäftsbuchungsgruppe (JSON)';
        }
        field(24; "PL Price Includes VAT"; Boolean)
        {
            Caption = 'Preisliste Preis inkl. MwSt. (JSON)';
        }
        field(25; "PL Allow Updating Defaults"; Boolean)
        {
            Caption = 'Preisliste Aktualisieren Standardwerte (JSON)';
        }
        field(26; "PL Allow Invoice Disc."; Boolean)
        {
            Caption = 'Preisliste Rech.-Rabatt zulassen (JSON)';
            InitValue = true;
        }
        field(27; "PL Allow Line Disc."; Boolean)
        {
            Caption = 'Preisliste Zeilenrabatt zulassen (JSON)';
            InitValue = true;
        }
        field(28; "PL Amount Type"; Text[30])
        {
            Caption = 'Preisliste Mengentyp (JSON)';
        }
        /// <summary>Line-level VAT Bus. Posting Group mirrored to Price List Line.</summary>
        field(29; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'MwSt.-Geschäftsbuchungsgruppe (Preis)';
        }
        /// <summary>Line-level Price Includes VAT mirrored to Price List Line.</summary>
        field(30; "Price Includes VAT"; Boolean)
        {
            Caption = 'Preis inkl. MwSt.';
        }
        field(31; "PL Valid From"; Date)
        {
            Caption = 'Preisliste Gültig von (JSON)';
        }
        field(32; "PL Valid To"; Date)
        {
            Caption = 'Preisliste Gültig bis (JSON)';
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
