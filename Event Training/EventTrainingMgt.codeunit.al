codeunit 50005 "Event Training Mgt."
{
    procedure RunEvent1(var PurchaseHeader: Record "Purchase Header")
    begin
        Message('kein Subscriber aktiv');
        OnAfterEvent1Action(PurchaseHeader);
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterEvent1Action(var PurchaseHeader: Record "Purchase Header")
    begin
    end;
}
