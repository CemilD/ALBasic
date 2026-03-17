/// <summary>
/// ListPart showing the number of import errors per company.
/// Uses a temporary buffer (SourceTableTemporary = true) that is populated
/// on page open by iterating PLI Import Log Line records grouped by "Company Name".
/// Error statuses counted: Error, RejectedMissingEndDate.
/// </summary>
page 70109 "PLI Errors By Company Part"
{
    Caption = 'Fehler pro Mandant';
    PageType = ListPart;
    SourceTable = "PLI Company Error Buffer";
    SourceTableTemporary = true;
    ApplicationArea = All;
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
                field(CompanyName; Rec."Company Name")
                {
                    Caption = 'Mandant';
                    ApplicationArea = All;
                }
                field(ErrorCount; Rec."Error Count")
                {
                    Caption = 'Anzahl Fehler';
                    ApplicationArea = All;
                    Style = Unfavorable;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        LogLine: Record "PLI Import Log Line";
        ErrorsPerCompany: Dictionary of [Text, Integer];
        CompanyName: Text;
        CurrentCount: Integer;
    begin
        LogLine.Reset();
        if LogLine.FindSet() then
            repeat
                if LogLine.Status in [LogLine.Status::Error, LogLine.Status::RejectedMissingEndDate] then begin
                    CompanyName := LogLine."Company Name";
                    if ErrorsPerCompany.ContainsKey(CompanyName) then begin
                        CurrentCount := ErrorsPerCompany.Get(CompanyName);
                        ErrorsPerCompany.Set(CompanyName, CurrentCount + 1);
                    end else
                        ErrorsPerCompany.Add(CompanyName, 1);
                end;
            until LogLine.Next() = 0;

        foreach CompanyName in ErrorsPerCompany.Keys() do begin
            Rec.Init();
            Rec."Company Name" := CopyStr(CompanyName, 1, MaxStrLen(Rec."Company Name"));
            Rec."Error Count" := ErrorsPerCompany.Get(CompanyName);
            Rec.Insert();
        end;
    end;
}
