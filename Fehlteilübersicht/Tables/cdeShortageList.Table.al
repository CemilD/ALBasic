table 50001 cdeShortageListTableBuffer
{
    DataClassification = CustomerContent;
    Caption = 'CDE Shortage List Table';
    ReplicateData = false;

    fields
    {
        field(1; ProdOrderNo; Code[20])
        {
            Caption = 'Production Order';
            TableRelation = "Production Order" where(Status = const(Released));
            Editable = false;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; UnitOfMeasure; Code[10])
        {
            Caption = 'Unit of Measure';
        }
        field(5; ProdOrder; Integer)
        {
            Caption = 'Production Order';
            FieldClass = FlowField;
            CalcFormula = Sum("Production Order".Quantity where("Source No." = field(ProdOrderNo)));
        }
    }

    keys
    {
        key(Key1; ProdOrderNo)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

}