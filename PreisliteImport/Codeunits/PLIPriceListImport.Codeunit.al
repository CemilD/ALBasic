/// <summary>
/// Public façade for the PLI Price List Import subsystem.
/// This is the sole external entry point into the subsystem.
/// All business logic is encapsulated in internal codeunits and is not
/// accessible to callers, enabling the subsystem to evolve freely.
///
/// Usage:
///   var PLIPriceListImport: Codeunit "PLI Price List Import";
///   PLIPriceListImport.ImportFromBlob(TempBlob, FileName, CompanyFilter);
/// </summary>
codeunit 70100 "PLI Price List Import"
{
    Access = Public;
    TableNo = "PLI Import Log";

    trigger OnRun()
    var
        PLIPriceListImportImpl: Codeunit "PLI Price List Import Impl.";
    begin
        PLIPriceListImportImpl.RunImport(Rec);
    end;

    /// <summary>
    /// Imports a price list from a TempBlob containing a UTF-8 encoded JSON file.
    /// Creates a PLI Import Log entry and populates PLI Import Log Lines.
    /// </summary>
    /// <param name="TempBlob">Holds the JSON file bytes as an outstream.</param>
    /// <param name="FileName">Original file name; stored in the import log.</param>
    /// <param name="CompanyFilter">
    /// Leave empty to import into all non-evaluation companies.
    /// Provide a specific company name to restrict import to that company only.
    /// </param>
    /// <param name="PriceListCode">
    /// Optional. If provided, all imported lines are written into this price list (or a
    /// new Draft copy if it is Active). If empty, a Draft per-customer price list is
    /// found or created using the No. Series from Sales &amp; Receivables Setup.
    /// </param>
    /// <remarks>
    /// DRAFT-ONLY: Import ALWAYS creates Draft headers and lines.
    /// Use Page 70108 "PLI Activate Price List" or Codeunit "PLI Price List Activation"
    /// to move lists from Draft to Active after review.
    /// </remarks>
    procedure ImportFromBlob(var TempBlob: Codeunit "Temp Blob"; FileName: Text; CompanyFilter: Text[30]; PriceListCode: Code[20])
    var
        PLIPriceListImportImpl: Codeunit "PLI Price List Import Impl.";
    begin
        PLIPriceListImportImpl.ImportFromBlob(TempBlob, FileName, CompanyFilter, PriceListCode);
    end;

    /// <summary>
    /// Parses the JSON content and returns metadata for a preview dialog.
    /// No records are written to the database.
    /// </summary>
    /// <param name="JsonContent">Raw JSON text to inspect.</param>
    /// <param name="ImportType">Metadata type value (e.g. 'SalesPricelist').</param>
    /// <param name="ValidFrom">Price validity start from metadata.</param>
    /// <param name="ValidTo">Price validity end from metadata.</param>
    /// <param name="LineCount">Number of entries in the prices array.</param>
    /// <param name="UniqueCustomerCount">
    /// Number of distinct 'customerNo' values found in the JSON prices array.
    /// Used by the preview dialog to warn about multi-customer imports into a single override code.
    /// </param>
    procedure GetPreviewData(JsonContent: Text; var ImportType: Text[50]; var ValidFrom: Date; var ValidTo: Date; var LineCount: Integer; var UniqueCustomerCount: Integer)
    var
        PLIPriceListImportImpl: Codeunit "PLI Price List Import Impl.";
    begin
        PLIPriceListImportImpl.ParseJsonMetadata(JsonContent, ImportType, ValidFrom, ValidTo, LineCount, UniqueCustomerCount);
    end;
}
