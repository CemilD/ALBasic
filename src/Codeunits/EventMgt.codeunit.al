codeunit 50001 EventMgtCDE
{
    [EventSubscriber(ObjectType::Table, Database::CDEKVPTableMyTable, OnBeforeInsertEvent, '', false, false)]
    local procedure OnBeforeInsertEvent(RunTrigger: Boolean; Rec: Record CDEKVPTableMyTable)
    begin
        if RunTrigger then
            Message('Record Inserted with true')
        else
            Message('with false');
    end;

    [EventSubscriber(ObjectType::Page, Page::cdeKVPCard, OnQueryClosePageEvent, '', false, false)]
    local procedure OnQueryClosePageEvent()
    begin
        Message('Event1 Triggered');

    end;

}