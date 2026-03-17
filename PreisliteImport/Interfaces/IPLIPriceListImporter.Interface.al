/// <summary>
/// Contract for a PLI price list importer.
///
/// To add a new import source type (e.g. vendor price lists):
///   1. Create a codeunit that fulfils this interface.
///   2. Add a new value to enum "PLI Importer Type" pointing to that codeunit.
///   No changes to existing code are required.
/// </summary>
interface "IPLIPriceListImporter"
{
    /// <summary>
    /// Returns the JSON metadata type string this importer handles.
    /// Must match the "type" field in the JSON metadata section.
    /// Example: 'SalesPricelist'
    /// </summary>
    procedure GetImportType(): Text[50];

    /// <summary>
    /// Controls whether newly created price list headers and lines receive
    /// Status = Active (true, default) or Status = Draft (false).
    /// Must be called before UpsertToCompany.
    /// </summary>
    procedure SetInsertAsActive(Value: Boolean);

    /// <summary>
    /// Upserts the price described by LogLine into the specified company context.
    /// The implementation must call ChangeCompany on any records it accesses.
    /// On failure, set LogLine."Error Message" before returning Error status.
    /// </summary>
    /// <param name="LogLine">Price line data carrier; fields may be updated in place.</param>
    /// <param name="CompanyName">Target company for ChangeCompany calls.</param>
    /// <returns>Resulting line import status (Imported / Updated / Error / Skipped).</returns>
    procedure UpsertToCompany(var LogLine: Record "PLI Import Log Line"; CompanyName: Text[30]): Enum "PLI Line Import Status";
}
