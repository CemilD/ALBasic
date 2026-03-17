/// <summary>
/// "PLI Preisliste aktivieren" — activation page for PLI-imported price lists.
///
/// Opened from the Import Log Card or directly from search.
/// Shows all PLI price lists in Draft status for the selected company.
/// The user selects one (or more) and clicks "Aktivieren" to move them
/// from Draft to Active through the official PLIPriceListActivation routine.
///
/// This is the ONLY authorised path to activate import-created price lists.
/// Direct status edits on the Price List Header are blocked by PLIPriceListGuardrail.
/// </summary>
page 70108 "PLI Activate Price List"
{
    Caption = 'Preisliste aktivieren';
    PageType = List;
    UsageCategory = Tasks;
    ApplicationArea = All;
    SourceTable = "Price List Header";
    CardPageId = "Sales Price List";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code';
                    ToolTip = 'Preislistencode.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    StyleExpr = StatusStyle;
                    ToolTip = 'Aktueller Status der Preisliste. Nur Entwuerfe koennen hier aktiviert werden.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Beschreibung';
                    ToolTip = 'Beschreibung der Preisliste.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    Caption = 'Zuweisen zu Typ';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = All;
                    Caption = 'Zuweisen zu Nr.';
                    ToolTip = 'Debitorennummer oder andere Quellenangabe.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Caption = 'Waehrungscode';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Startdatum';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    Caption = 'Enddatum';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActivateSelected)
            {
                Caption = 'Aktivieren';
                ApplicationArea = All;
                Image = Approve;
                ToolTip = 'Markierte Preislisten von Entwurf auf Aktiv setzen. Die Listen sind danach sofort in Verkaufsbelegen wirksam. Dieser Schritt kann nicht automatisch rueckgaengig gemacht werden.';
                ShortCutKey = 'Ctrl+F9';

                trigger OnAction()
                var
                    PLIPriceListActivation: Codeunit "PLI Price List Activation";
                    PriceListHeader: Record "Price List Header";
                    ActivatedCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(PriceListHeader);
                    if not PriceListHeader.FindSet() then begin
                        Message('Keine Preislisten ausgewaehlt.');
                        exit;
                    end;

                    if not Confirm(
                        'Sollen %1 Preisliste(n) aktiviert werden?\Aktivierte Listen sind sofort in Verkaufsbelegen wirksam.',
                        false, PriceListHeader.Count)
                    then
                        exit;

                    repeat
                        if PriceListHeader.Status = PriceListHeader.Status::Draft then begin
                            PLIPriceListActivation.ActivatePriceList(PriceListHeader);
                            ActivatedCount += 1;
                        end;
                    until PriceListHeader.Next() = 0;

                    CurrPage.Update(false);
                    if ActivatedCount > 0 then
                        Message('%1 Preisliste(n) erfolgreich aktiviert.', ActivatedCount);
                end;
            }
            action(OpenPriceList)
            {
                Caption = 'Preisliste oeffnen';
                ApplicationArea = All;
                Image = ViewDetails;
                RunObject = Page "Sales Price List";
                RunPageLink = Code = field(Code);
                ToolTip = 'Die markierte Preisliste zur Pruefung der Zeilen oeffnen.';
            }
        }

        area(Promoted)
        {
            actionref(ActivateSelected_Promoted; ActivateSelected) { }
            actionref(OpenPriceList_Promoted; OpenPriceList) { }
        }
    }

    trigger OnOpenPage()
    begin
        // Default filter: show only Draft lists so user sees what needs activation
        Rec.SetRange("Price Type", Rec."Price Type"::Sale);
        Rec.SetRange(Status, Rec.Status::Draft);
    end;

    trigger OnAfterGetRecord()
    begin
        if Rec.Status = Rec.Status::Draft then
            StatusStyle := 'Attention'
        else
            StatusStyle := 'Favorable';
    end;

    var
        StatusStyle: Text;
}
