/// <summary>
/// Activation Management codeunit for PLI Price Lists.
///
/// Design:
///   This SingleInstance codeunit holds a flag that marks whether
///   the CURRENT call stack originated from the official activation routine
///   (ActivatePriceList). The EventSubscriber in PLIPriceListGuardrail
///   checks this flag on every Price List Header Modify and blocks any
///   Status change to Active that was NOT made through here.
///
/// Usage (from "PLI Activate Price List" page action):
///   PLIPriceListActivation.ActivatePriceList(PriceListHeader);
/// </summary>
codeunit 70104 "PLI Price List Activation"
{
    Access = Public;
    SingleInstance = true;

    /// <summary>
    /// The only authorised path to set a Price List Header from Draft to Active.
    /// Raises an error when the list is not in Draft status.
    /// Sets the guardrail bypass flag so the EventSubscriber allows the change,
    /// then clears it unconditionally in a finally block.
    /// </summary>
    procedure ActivatePriceList(var PriceListHeader: Record "Price List Header")
    begin
        if PriceListHeader.Status = PriceListHeader.Status::Active then
            Error('Preisliste "%1" ist bereits aktiv.', PriceListHeader.Code);

        if PriceListHeader.Status <> PriceListHeader.Status::Draft then
            Error('Preisliste "%1" kann nicht aktiviert werden (Status: %2). Nur Entwuerfe duerfen aktiviert werden.',
                PriceListHeader.Code, PriceListHeader.Status);

        ActivationAllowed := true;
        PriceListHeader.Validate(Status, PriceListHeader.Status::Active);
        PriceListHeader.Modify(true);
        ActivationAllowed := false;

        Message('Preisliste "%1" wurde erfolgreich aktiviert und ist jetzt in Verkaufsbelegen wirksam.',
            PriceListHeader.Code);
    end;

    /// <summary>
    /// Called by PLIPriceListGuardrail subscriber to check whether the current
    /// Status change to Active is authorised.
    /// </summary>
    procedure IsActivationAllowed(): Boolean
    begin
        exit(ActivationAllowed);
    end;

    var
        ActivationAllowed: Boolean;
}
