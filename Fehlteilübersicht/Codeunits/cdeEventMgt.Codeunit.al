codeunit 50002 cdeEventMgt
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Status Management", OnAfterChangeStatusOnProdOrder, '', false, false)]
    local procedure cdeOnAfterChangeStatusOnProdOrder(ProdOrder: Record "Production Order")
    begin
        if GuiAllowed() and (ProdOrder.Status = ProdOrder.Status::"Firm Planned") then begin
            case ProdOrder.Status of
                ProdOrder.Status::"Firm Planned":
                    Message('Dein Produktionsauftrag ist Fest geplant.');
                else
                    exit;
            end;
        end;

    end;
}