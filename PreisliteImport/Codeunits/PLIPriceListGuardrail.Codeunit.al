/// <summary>
/// Hard guardrail that prevents any code from setting a Price List Header
/// to Status = Active outside of the official "PLI Price List Activation"
/// codeunit (70104).
///
/// How it works:
///   - Subscribes to OnBeforeModify on Price List Header.
///   - If the record's Status is being changed TO Active AND the SingleInstance
///     activation flag is NOT set, an error is raised immediately.
///   - The import pipeline always writes Draft → the flag will never be set
///     during import, so attempting to insert/modify Active headers in import
///     code will be caught here as a last-resort safety net.
///
/// This codeunit contains NO business logic beyond the guard check.
/// It is intentionally small and single-purpose (alguidelines.dev subscriber rule).
/// </summary>
codeunit 70105 "PLI Price List Guardrail"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Price List Header", 'OnBeforeModifyEvent', '', false, false)]
    local procedure GuardAgainstUnauthorisedActivation(var Rec: Record "Price List Header"; var xRec: Record "Price List Header"; RunTrigger: Boolean)
    var
        PLIPriceListActivation: Codeunit "PLI Price List Activation";
    begin
        // Only block changes that flip Status TO Active
        if Rec.Status <> Rec.Status::Active then
            exit;
        // If the status did not change, nothing to guard
        if xRec.Status = Rec.Status::Active then
            exit;
        // If this is the official activation routine, allow it
        if PLIPriceListActivation.IsActivationAllowed() then
            exit;

        Error(
            'Preisliste "%1" darf nicht direkt auf "Aktiv" gesetzt werden.\' +
            'Verwenden Sie die Aktion "Preisliste aktivieren" (PLI Activate Price List),\' +
            'um eine Preisliste nach Pruefung freizugeben.',
            Rec.Code);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Price List Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure GuardAgainstActiveInsert(var Rec: Record "Price List Header"; RunTrigger: Boolean)
    var
        PLIPriceListActivation: Codeunit "PLI Price List Activation";
    begin
        // Reject any Insert that tries to create an already-Active header
        if Rec.Status <> Rec.Status::Active then
            exit;
        if PLIPriceListActivation.IsActivationAllowed() then
            exit;

        Error(
            'Eine neue Preisliste darf nicht direkt als "Aktiv" angelegt werden.\' +
            'Legen Sie die Liste als Entwurf an und aktivieren Sie sie anschliessend\' +
            'ueber die Aktion "Preisliste aktivieren".');
    end;
}
