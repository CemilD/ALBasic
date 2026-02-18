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
                RunObject = Page "cdeKVPCard";
                RunPageLink = KVPid = field("No.");
                RunPageMode = Create;
            }
        }
    }
}