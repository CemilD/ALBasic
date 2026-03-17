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
    /// Optional. If provided, all imported lines are written into this existing price list.
    /// If empty, a per-customer price list is found or created using the No. Series from
    /// Sales &amp; Receivables Setup ("Price List Nos."). If no No. Series is configured,
    /// a new price list with code PLI-{CustomerNo} is created.
    /// </param>
    /// <param name="InsertAsActive">
    /// True (default): new price list headers and lines are set to Status = Active and
    /// take effect immediately on the next sales document.
    /// False: inserted as Draft for manual review before activation in BC.
    /// Note: the Best-Price principle applies after activation — if another price list
    /// offers a lower price for the same item, BC will use that lower price instead.
    /// </param>
    procedure ImportFromBlob(var TempBlob: Codeunit "Temp Blob"; FileName: Text; CompanyFilter: Text[30]; PriceListCode: Code[20]; InsertAsActive: Boolean)
    var
        PLIPriceListImportImpl: Codeunit "PLI Price List Import Impl.";
    begin
        PLIPriceListImportImpl.ImportFromBlob(TempBlob, FileName, CompanyFilter, PriceListCode, InsertAsActive);
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
