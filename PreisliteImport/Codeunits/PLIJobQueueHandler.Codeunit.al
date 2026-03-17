/// <summary>
/// Job Queue entry handler for scheduled PLI price list imports.
/// Set Object ID to Run = 70103 in the Job Queue Entry.
///
/// Note: If you are upgrading from an earlier version where the handler
/// was Codeunit 70101, update any existing Job Queue Entries to use ID 70103.
/// </summary>
codeunit 70103 "PLI Job Queue Handler"
{
    Access = Internal;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        PLIImportLog: Record "PLI Import Log";
        PLIPriceListImport: Codeunit "PLI Price List Import";
    begin
        PLIImportLog.SetLoadFields("Entry No.", Status, "Company Filter");
        PLIImportLog.SetRange(Status, PLIImportLog.Status::Running);
        if not PLIImportLog.FindSet() then
            exit;
        repeat
            Codeunit.Run(Codeunit::"PLI Price List Import", PLIImportLog);
        until PLIImportLog.Next() = 0;
    end;
}
