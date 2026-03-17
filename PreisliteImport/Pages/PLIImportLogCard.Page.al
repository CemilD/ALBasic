page 70102 "PLI Import Log Card"
{
    Caption = 'Import-Log Detail';
    PageType = Document;
    SourceTable = "PLI Import Log";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Allgemein';
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Import DateTime"; Rec."Import DateTime") { ApplicationArea = All; }
                field("User ID"; Rec."User ID") { ApplicationArea = All; }
                field("Company Filter"; Rec."Company Filter") { ApplicationArea = All; }
                field("File Name"; Rec."File Name") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Error Message"; Rec."Error Message") { ApplicationArea = All; Multiline = true; }
            }
            group(Statistics)
            {
                Caption = 'Statistik';
                field("Total Lines"; Rec."Total Lines") { ApplicationArea = All; }
                field("Imported Lines"; Rec."Imported Lines") { ApplicationArea = All; }
                field("Error Lines"; Rec."Error Lines") { ApplicationArea = All; }
            }
            part(LogLines; "PLI Import Log Line List")
            {
                ApplicationArea = All;
                Caption = 'Import-Zeilen';
                SubPageLink = "Entry No." = field("Entry No.");
            }
        }
    }
}
