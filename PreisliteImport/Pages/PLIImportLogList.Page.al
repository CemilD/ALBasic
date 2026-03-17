page 70101 "PLI Import Log List"
{
    Caption = 'Preisimport-Log';
    PageType = List;
    SourceTable = "PLI Import Log";
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    CardPageId = "PLI Import Log Card";

    layout
    {
        area(Content)
        {
            repeater(LogEntries)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Import DateTime"; Rec."Import DateTime")
                {
                    ApplicationArea = All;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                }
                field("Company Filter"; Rec."Company Filter")
                {
                    ApplicationArea = All;
                }
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = All;
                }
                field("Total Lines"; Rec."Total Lines")
                {
                    ApplicationArea = All;
                }
                field("Imported Lines"; Rec."Imported Lines")
                {
                    ApplicationArea = All;
                }
                field("Error Lines"; Rec."Error Lines")
                {
                    ApplicationArea = All;
                    StyleExpr = ErrorStyle;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowLines)
            {
                Caption = 'Zeilen anzeigen';
                ApplicationArea = All;
                Image = AllLines;
                RunObject = Page "PLI Import Log Line List";
                RunPageLink = "Entry No." = field("Entry No.");
            }
            action(BackToCockpit)
            {
                Caption = 'Import-Cockpit';
                ApplicationArea = All;
                Image = Home;
                RunObject = Page "PLI Import Cockpit";
            }
        }
    }

    var
        ErrorStyle: Text;
        StatusStyle: Text;

    trigger OnAfterGetRecord()
    begin
        if Rec."Error Lines" > 0 then
            ErrorStyle := 'Unfavorable'
        else
            ErrorStyle := 'Favorable';

        case Rec.Status of
            Rec.Status::Success:
                StatusStyle := 'Favorable';
            Rec.Status::Failed:
                StatusStyle := 'Unfavorable';
            Rec.Status::Partial:
                StatusStyle := 'Attention';
            else
                StatusStyle := 'None';
        end;
    end;
}
