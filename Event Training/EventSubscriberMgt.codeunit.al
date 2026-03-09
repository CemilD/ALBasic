codeunit 50006 "Event Subscriber Mgt."
{
    // Hier ist das entscheidende Element
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Event Training Mgt.", OnAfterEvent1Action, '', false, false)]
    local procedure OnAfterEvent1Action(var PurchaseHeader: Record "Purchase Header")
    begin
        Message('Subscriber aktiv ');
    end;
}
