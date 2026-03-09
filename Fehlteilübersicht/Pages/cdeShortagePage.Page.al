page 50002 cdeShortagePage
{
    Caption = 'CDE Shortage List';
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Tasks;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    AboutTitle = 'CDE Shortage List';
    AboutText = 'Use this page to review the list of items with shortages for a specific production order. The list is based on the current inventory and the demand from the production order.';
    SourceTable = "cdeShortageListTableBuffer";
    SourceTableTemporary = true;


    layout
    {
        area(Content)
        {
            group(General)
            {
                field(ProdOrderFilter; ProdOrderFilter)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Production Order Filter';
                    ToolTip = 'Specifies the production order number or a filter on the production order numbers that you would like to trace.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ProdOrder: Record "Production Order";
                        ProdOrderList: Page "Production Order List";
                        SelectionFilterMgt: Codeunit SelectionFilterManagement;
                        RecRef: RecordRef;
                    begin
                        ProdOrder.Reset();
                        ProdOrder.SetRange(Status, ProdOrder.Status::Released);
                        Clear(ProdOrderList);

                        ProdOrderList.SetTableView(ProdOrder);
                        ProdOrderList.LookupMode(true);
                        if ProdOrderList.RunModal() = ACTION::LookupOK then begin
                            ProdOrderList.GetRecord(ProdOrder);
                            RecRef.GetTable(ProdOrder);
                            ProdOrderFilter := SelectionFilterMgt.GetSelectionFilter(RecRef, ProdOrder.FieldNo("No."));
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        if ProdOrderFilter = '' then
                            VariantFilter := '';
                    end;
                }

            }
        }
    }

    var
        ProdOrderFilter: Text;
        VariantFilter: Text;

}
