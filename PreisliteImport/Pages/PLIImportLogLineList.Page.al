page 70103 "PLI Import Log Line List"
{
    Caption = 'Import-Log Zeilen';
    PageType = ListPart;
    SourceTable = "PLI Import Log Line";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Company Name"; Rec."Company Name") { ApplicationArea = All; }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { ApplicationArea = All; }
                field("Minimum Quantity"; Rec."Minimum Quantity") { ApplicationArea = All; }
                field("Unit Price"; Rec."Unit Price") { ApplicationArea = All; }
                field("Currency Code"; Rec."Currency Code") { ApplicationArea = All; }
                field("Starting Date"; Rec."Starting Date") { ApplicationArea = All; }
                field("Ending Date"; Rec."Ending Date") { ApplicationArea = All; }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                }
                field("Error Message"; Rec."Error Message") { ApplicationArea = All; }
            }
        }
    }

    var
        StatusStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Imported, Rec.Status::Updated:
                StatusStyle := 'Favorable';
            Rec.Status::Error:
                StatusStyle := 'Unfavorable';
            Rec.Status::Skipped:
                StatusStyle := 'Attention';
            else
                StatusStyle := 'None';
        end;
    end;
}
