table 50001 cdeShortageListTableBuffer
{
    DataClassification = CustomerContent;
    Caption = 'CDE Shortage List Table';
    // ReplicateData = false → diese Tabelle wird nie in die Datenbank geschrieben, nur im Arbeitsspeicher verwendet
    ReplicateData = false;

    fields
    {
        field(1; ProdOrderNo; Code[20])
        {
            Caption = 'FA-Nr.';
            // Relation auf freigegebene FAs für Drilldown-Funktionalität
            TableRelation = "Production Order"."No." where(Status = const(Released));
            Editable = false;
        }
        field(2; ProdOrderLineNo; Integer)
        {
            Caption = 'FA-Zeilennr.';
            Editable = false;
        }
        field(3; LineNo; Integer)
        {
            Caption = 'Position';
            Editable = false;
        }
        field(4; ItemNo; Code[20])
        {
            Caption = 'Material';
            TableRelation = Item;
            Editable = false;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Materialkurztext';
            Editable = false;
        }
        field(6; DueDate; Date)
        {
            Caption = 'Bedarfstermin';
            Editable = false;
        }
        field(7; RequiredQty; Decimal)
        {
            Caption = 'Bedarfsmenge';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(8; UnitOfMeasure; Code[10])
        {
            Caption = 'ME';
            TableRelation = "Unit of Measure";
            Editable = false;
        }
        field(9; LocationCode; Code[10])
        {
            Caption = 'Lagerort';
            TableRelation = Location;
            Editable = false;
        }
        field(10; OperationNo; Code[10])
        {
            Caption = 'Vorgang';
            Editable = false;
        }
        field(11; AvailableQty; Decimal)
        {
            // Verfügbarer Bestand am Lagerort zum Bedarfstermin
            Caption = 'Bestätigte Menge';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
    }

    keys
    {
        // Zusammengesetzter PK: FA-Nr. + Zeilennr. + Komponentenzeilennr.
        key(Key1; ProdOrderNo, ProdOrderLineNo, LineNo)
        {
            Clustered = true;
        }
    }
}