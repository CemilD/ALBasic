enum 70101 "PLI Line Import Status"
{
    Extensible = true;
    Caption = 'PLI Line Import Status';

    value(0; " ") { Caption = ' '; }
    value(1; Imported) { Caption = 'Imported'; }
    value(2; Updated) { Caption = 'Updated'; }
    value(3; Error) { Caption = 'Error'; }
    value(4; Skipped) { Caption = 'Skipped'; }
    /// <summary>New line inserted because an active/overlapping line already exists for the same key.</summary>
    value(5; InsertedConflictActiveOverlap) { Caption = 'Inserted (Active Overlap)'; }
    /// <summary>Import line rejected because no Ending Date was provided (mandatory for overlap detection).</summary>
    value(6; RejectedMissingEndDate) { Caption = 'Rejected (Missing End Date)'; }
    /// <summary>
    /// New line inserted for a matching article but with a DIFFERENT Minimum Quantity.
    /// The existing line was not touched; a new line was created alongside it.
    /// </summary>
    value(7; InsertedMinQtyVariant) { Caption = 'Inserted (MinQty Variant)'; }
    /// <summary>New price line inserted (no existing line found at all for this key).</summary>
    value(8; InsertedNewLine) { Caption = 'Inserted (New)'; }
}
