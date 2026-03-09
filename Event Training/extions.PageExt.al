pageextension 50001 EinkaufExt extends "Purchase Order"
{
    layout
    {
    }
    actions
    {
        addlast(Processing)
        {
            action(RunWithoutSubscriber)
            {
                ApplicationArea = All;
                Caption = 'ohne Subscriber';
                trigger OnAction()
                var
                    EventTrainingMgt: Codeunit "Event Training Mgt.";
                begin
                    EventTrainingMgt.RunEvent1(Rec);
                end;
            }
            action(RunWithSubscriber)
            {
                ApplicationArea = All;
                Caption = 'mit Subscriber';
                trigger OnAction()
                var
                    EventTrainingMgt: Codeunit "Event Training Mgt.";
                    EventSubscriberMgt: Codeunit "Event Subscriber Mgt.";
                begin
                    BindSubscription(EventSubscriberMgt);
                    EventTrainingMgt.RunEvent1(Rec);
                    UnbindSubscription(EventSubscriberMgt);
                end;
            }
        }
    }
}