table 50005 pdeMD04CrossCompanyBuffer
{
    DataClassification = CustomerContent;
    Caption = 'PDE MD04 - Cross-Company Stock Buffer';
    // Nur im RAM gehalten – wird nie in die Datenbank geschrieben
    ReplicateData = false;

    fields
    {
        field(1; CompanyName; Text[30])
        {
            Caption = 'Company (Mandant)';
            // Name des Mandanten aus dem Company-Record
            Editable = false;
        }
        field(2; ItemNo; Code[20])
        {
            Caption = 'Item No.';
            Editable = false;
        }
        field(3; Inventory; Decimal)
        {
            Caption = 'Inventory';
            // Lagerbestand beim jeweiligen Mandanten (alle Lagerorte summiert)
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(4; LocationCode; Code[10])
        {
            Caption = 'Location';
            // Leerstring = Summe aller Lagerorte dieses Mandanten
            Editable = false;
        }
        field(5; UnitOfMeasure; Code[10])
        {
            Caption = 'Base UoM';
            Editable = false;
        }
        field(6; ItemDescription; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(7; ReorderPoint; Decimal)
        {
            Caption = 'Reorder Point';
            // Meldebestand aus dem jeweiligen Mandanten
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
    }

    keys
    {
        // Primärschlüssel: Mandant + Artikel + Lagerort – eindeutige Kombination
        key(PK; CompanyName, ItemNo, LocationCode)
        {
            Clustered = true;
        }
    }
}
