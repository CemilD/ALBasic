pageextension 50000 ReleasedProductionOrder extends "Released Production Order"
{
    layout
    {
    }

    actions
    {
        addlast(processing)
        {
            action(KVPNotes)
            {
                ApplicationArea = All;
                Caption = 'KVP', Comment = 'DEU = KVP Vorschalg';
                Image = Info;

                trigger OnAction()
                var

                begin

                end;
            }
        }
    }
}