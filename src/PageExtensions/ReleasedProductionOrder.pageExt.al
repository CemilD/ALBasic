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
                    KVPRec: Record CDEKVPTableMyTable;
                begin
                    if KVPRec.Get(Rec."No.", Rec."Source No.") then begin
                        Page.RunModal(Page::"cdeKVPCard", KVPRec);
                    end
                    else begin
                        Page.RunModal(Page::"cdeKVPCard", KVPRec);
                        KVPRec.Init();
                        KVPRec.KVPid := Rec."No.";
                        KVPRec.Subject := Rec.Description;
                        KVPRec.ItemDescription := Rec."Description";
                        KVPRec.ItemNo := Rec."Source No.";
                        KVPRec.Insert(false);
                        CurrPage.Update();
                    end;
                end;
            }
        }
    }
}