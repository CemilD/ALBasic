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
        /// <summary>Price list description from JSON priceListHeader block. Used when auto-creating a new price list.</summary>
        field(13; "PL Description"; Text[100])
        {
            Caption = 'Preislisten-Beschreibung (JSON)';
        }
        /// <summary>Source type from JSON priceListHeader.sourceType: '' = per customer, 'Customer', 'AllCustomers'.</summary>
        field(14; "PL Source Type"; Text[30])
        {
            Caption = 'Preisliste Quelle Typ (JSON)';
        }
        /// <summary>Source No. from JSON priceListHeader.sourceNo (customer no.).</summary>
        field(15; "PL Source No."; Code[20])
        {
            Caption = 'Preisliste Quelle Nr. (JSON)';
        }
        /// <summary>Currency from JSON priceListHeader.currency.</summary>
        field(16; "PL Currency Code"; Code[10])
        {
            Caption = 'Preisliste Waehrungscode (JSON)';
        }
        field(17; "PL VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'Preisliste MwSt.-Geschäftsbuchungsgruppe (JSON)';
            TableRelation = "VAT Business Posting Group";
        }
        field(18; "PL Price Includes VAT"; Boolean)
        {
            Caption = 'Preisliste Preis inkl. MwSt. (JSON)';
        }
        field(19; "PL Allow Updating Defaults"; Boolean)
        {
            Caption = 'Preisliste Aktualisieren Standardwerte (JSON)';
        }
        field(20; "PL Allow Invoice Disc."; Boolean)
        {
            Caption = 'Preisliste Rech.-Rabatt zulassen (JSON)';
            InitValue = true;
        }
        field(21; "PL Allow Line Disc."; Boolean)
        {
            Caption = 'Preisliste Zeilenrabatt zulassen (JSON)';
            InitValue = true;
        }
        field(22; "PL Amount Type"; Text[30])
        {
            Caption = 'Preisliste Mengentyp (JSON)';
        }
        field(23; "PL Valid From"; Date)
        {
            Caption = 'Preisliste Gültig von (JSON)';
        }
        field(24; "PL Valid To"; Date)
        {
            Caption = 'Preisliste Gültig bis (JSON)';
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
