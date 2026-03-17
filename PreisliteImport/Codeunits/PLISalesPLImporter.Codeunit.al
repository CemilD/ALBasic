/// <summary>
/// Concrete implementation of IPLIPriceListImporter for Sales Price Lists.
/// Handles JSON type 'SalesPricelist': upserts Price List Header + Price List Line
/// in the target company using ChangeCompany for cross-company access.
///
/// To add Purchase price list support, create a new codeunit with this same
/// structure, register it in enum "PLI Importer Type" — no other change needed.
/// </summary>
codeunit 70102 "PLI Sales PL Importer" implements "IPLIPriceListImporter"
{
    Access = Internal;

    procedure GetImportType(): Text[50]
    begin
        exit('SalesPricelist');
    end;

    procedure UpsertToCompany(var LogLine: Record "PLI Import Log Line"; CompanyName: Text[30]): Enum "PLI Line Import Status"
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        PriceListHeader.ChangeCompany(CompanyName);
        PriceListLine.ChangeCompany(CompanyName);

        PriceListCode := FindOrCreateHeaderCode(LogLine."Customer No.", LogLine."Currency Code", PriceListHeader);

        PriceListLine.SetLoadFields("Price List Code", "Asset No.", "Unit of Measure Code", "Minimum Quantity", "Starting Date", "Unit Price", "Ending Date");
        PriceListLine.SetRange("Price List Code", PriceListCode);
        PriceListLine.SetRange("Asset No.", LogLine."Item No.");
        PriceListLine.SetRange("Unit of Measure Code", LogLine."Unit of Measure Code");
        PriceListLine.SetRange("Minimum Quantity", LogLine."Minimum Quantity");
        PriceListLine.SetRange("Starting Date", LogLine."Starting Date");

        if PriceListLine.FindFirst() then begin
            PriceListLine."Unit Price" := LogLine."Unit Price";
            PriceListLine."Ending Date" := LogLine."Ending Date";
            PriceListLine.Modify(true);
            exit("PLI Line Import Status"::Updated);
        end;

        PriceListLine.Init();
        PriceListLine."Price List Code" := PriceListCode;
        PriceListLine."Price Type" := PriceListLine."Price Type"::Sale;
        PriceListLine."Source Type" := PriceListLine."Source Type"::Customer;
        PriceListLine."Source No." := LogLine."Customer No.";
        PriceListLine."Asset Type" := PriceListLine."Asset Type"::Item;
        PriceListLine."Asset No." := LogLine."Item No.";
        PriceListLine."Unit of Measure Code" := LogLine."Unit of Measure Code";
        PriceListLine."Minimum Quantity" := LogLine."Minimum Quantity";
        PriceListLine."Unit Price" := LogLine."Unit Price";
        PriceListLine."Currency Code" := LogLine."Currency Code";
        PriceListLine."Starting Date" := LogLine."Starting Date";
        PriceListLine."Ending Date" := LogLine."Ending Date";
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Insert(true);
        exit("PLI Line Import Status"::Imported);
    end;

    /// <summary>
    /// Returns the Code of an existing Sales Price List Header for the given
    /// customer and currency, or creates a new one if none exists.
    /// Note: PriceListHeader must already have ChangeCompany set by the caller.
    /// </summary>
    local procedure FindOrCreateHeaderCode(CustomerNo: Code[20]; CurrencyCode: Code[10]; var PriceListHeader: Record "Price List Header"): Code[20]
    begin
        PriceListHeader.SetLoadFields(Code);
        PriceListHeader.SetRange("Price Type", PriceListHeader."Price Type"::Sale);
        PriceListHeader.SetRange("Source Type", PriceListHeader."Source Type"::Customer);
        PriceListHeader.SetRange("Source No.", CustomerNo);
        PriceListHeader.SetRange("Currency Code", CurrencyCode);
        if PriceListHeader.FindFirst() then
            exit(PriceListHeader.Code);

        PriceListHeader.Init();
        PriceListHeader."Price Type" := PriceListHeader."Price Type"::Sale;
        PriceListHeader."Source Type" := PriceListHeader."Source Type"::Customer;
        PriceListHeader."Source No." := CustomerNo;
        PriceListHeader."Currency Code" := CurrencyCode;
        PriceListHeader.Description := StrSubstNo('JSON Import - Customer %1', CustomerNo);
        PriceListHeader.Status := PriceListHeader.Status::Active;
        PriceListHeader.Insert(true);

        // Fallback when no number series is configured for price lists
        if PriceListHeader.Code = '' then
            PriceListHeader.Code := CopyStr('PLI-' + CustomerNo, 1, 20);

        exit(PriceListHeader.Code);
    end;
}
