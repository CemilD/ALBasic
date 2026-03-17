/// <summary>
/// Temporary parameter record for the "Zeilen vorschlagen" dialog in the
/// PLI Test JSON Builder (Page 70105). Never persisted to the database.
/// </summary>
table 70106 "PLI Test Suggest Filter"
{
    Caption = 'PLI Test-JSON Zeilen vorschlagen Filter';
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Lfd. Nr.';
            DataClassification = SystemMetadata;
        }
        /// <summary>Item filter string applied to Item."No." via SetFilter. Empty = all items.</summary>
        field(2; "Asset Filter"; Text[2048])
        {
            Caption = 'Produktfilter';
            DataClassification = SystemMetadata;
        }
        field(3; "Minimum Quantity"; Decimal)
        {
            Caption = 'Mindestmenge';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(4; "Starting Date"; Date)
        {
            Caption = 'Startdatum';
            DataClassification = SystemMetadata;
        }
        field(5; "Ending Date"; Date)
        {
            Caption = 'Enddatum';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Multiplied with Item."Unit Price" to calculate the suggested line price.
        /// 1 = take price as-is. 0.9 = 10 % discount. 1.1 = 10 % surcharge.
        /// </summary>
        field(6; "Adjustment Factor"; Decimal)
        {
            Caption = 'Korrekturfaktor';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            InitValue = 1;
        }
        /// <summary>
        /// Decimal precision for rounding the calculated price.
        /// Examples: 0.01 = cent-exact, 0.10 = 10-cent steps, 1 = full euro.
        /// 0 = no rounding.
        /// </summary>
        field(7; "Rounding Precision"; Decimal)
        {
            Caption = 'Rundungsgenauigkeit';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            InitValue = 0.01;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
