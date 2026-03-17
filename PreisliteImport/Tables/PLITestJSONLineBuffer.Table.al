/// <summary>
/// Temporary buffer holding one price line while building a test JSON file
/// in "PLI Test JSON Builder" (page 70105). Mirrors the fields of "Price List Line".
/// Never persisted to the database.
/// </summary>
table 70105 "PLI Test JSON Line Buffer"
{
    Caption = 'PLI Test-JSON Zeilenpuffer';
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Zeilennr.';
            DataClassification = SystemMetadata;
        }
        /// <summary>Mirrors Price List Line "Source Type". Determines whether Source No. is required.</summary>
        field(2; "Source Type"; Enum "Price Source Type")
        {
            Caption = 'Zuweisen zu Typ';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if "Source Type" <> "Price Source Type"::Customer then
                    "Source No." := '';
            end;
        }
        /// <summary>customerNo in the generated JSON. Pflichtfeld when Source Type = Customer.</summary>
        field(3; "Source No."; Code[20])
        {
            Caption = 'Zuweisen zu Nr.';
            DataClassification = SystemMetadata;
            TableRelation = if ("Source Type" = const(Customer)) Customer."No.";
        }
        field(4; "Currency Code"; Code[10])
        {
            Caption = 'Waehrungscode';
            DataClassification = SystemMetadata;
            TableRelation = Currency.Code;
        }
        field(5; "Starting Date"; Date)
        {
            Caption = 'Startdatum';
            DataClassification = SystemMetadata;
        }
        field(6; "Ending Date"; Date)
        {
            Caption = 'Enddatum';
            DataClassification = SystemMetadata;
        }
        /// <summary>itemNo in the generated JSON. Pflichtfeld when Asset Type = Item.</summary>
        field(7; "Item No."; Code[20])
        {
            Caption = 'Produktnr.';
            DataClassification = SystemMetadata;
            TableRelation = if ("Asset Type" = const(Item)) Item."No.";

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if "Asset Type" <> "Price Asset Type"::Item then
                    exit;
                if "Item No." = '' then
                    Description := ''
                else if Item.Get("Item No.") then begin
                    Description := CopyStr(Item.Description, 1, MaxStrLen(Description));
                    if "Unit of Measure Code" = '' then
                        "Unit of Measure Code" := Item."Base Unit of Measure";
                end else
                    Description := '';
            end;
        }
        /// <summary>Auto-filled from Item table when Item No. is entered.</summary>
        field(8; Description; Text[100])
        {
            Caption = 'Beschreibung';
            DataClassification = SystemMetadata;
        }
        field(9; "Variant Code"; Code[10])
        {
            Caption = 'Variantencode';
            DataClassification = SystemMetadata;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(10; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Einheit';
            DataClassification = SystemMetadata;
            TableRelation = if ("Item No." = filter(<> '')) "Item Unit of Measure".Code where("Item No." = field("Item No."))
            else
            "Unit of Measure".Code;
        }
        field(11; "Minimum Quantity"; Decimal)
        {
            Caption = 'Mindestmenge';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(12; "Unit Price"; Decimal)
        {
            Caption = 'VK-Preis';
            DataClassification = SystemMetadata;
            DecimalPlaces = 2 : 5;
            MinValue = 0;
        }
        /// <summary>Set by ValidateBeforeExport() in the builder page. Shown inline with Attention style.</summary>
        field(13; "Validation Error"; Text[500])
        {
            Caption = 'Fehler';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Mirrors Price List Line "Asset Type". Default = Item.
        /// Lines with a type other than Item are skipped during JSON generation
        /// because the target format only supports itemNo.
        /// </summary>
        field(14; "Asset Type"; Enum "Price Asset Type")
        {
            Caption = 'Produkttyp';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                // Clear product info when product type changes
                if "Asset Type" <> "Price Asset Type"::Item then begin
                    "Item No." := '';
                    Description := '';
                    "Variant Code" := '';
                    "Unit of Measure Code" := '';
                end;
            end;
        }
        /// <summary>Mirrors Price List Line "Work Type Code". Relevant for Resource lines; usually empty for Items.</summary>
        field(15; "Work Type Code"; Code[10])
        {
            Caption = 'Arbeitstypencode';
            DataClassification = SystemMetadata;
            TableRelation = "Work Type".Code;
        }
        /// <summary>Mirrors Price List Line "Allow Line Disc." — default false.</summary>
        field(16; "Allow Line Disc."; Boolean)
        {
            Caption = 'Zeilenrabatt zulassen';
            DataClassification = SystemMetadata;
        }
        /// <summary>Mirrors Price List Line "Line Discount %".</summary>
        field(17; "Line Discount %"; Decimal)
        {
            Caption = 'Zeilenrabatt %';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 100;
        }
        /// <summary>Mirrors Price List Line "Allow Invoice Disc." — default false.</summary>
        field(18; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Rech.-Rabatt zulassen';
            DataClassification = SystemMetadata;
        }
        /// <summary>Mirrors Price List Line "VAT Bus. Posting Gr. (Price)".</summary>
        field(19; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'MwSt.-Geschäftsbuchungsgruppe (Preis)';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>Mirrors Price List Line "Price Includes VAT".</summary>
        field(20; "Price Includes VAT"; Boolean)
        {
            Caption = 'Preis inkl. MwSt.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
    }
}
