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

    /// <summary>
    /// Controls whether new price list lines are inserted as Active or Draft.
    /// Default is Active (direct effect). Set to false to insert as Draft
    /// for manual review before activation.
    /// </summary>
    procedure SetInsertAsActive(Value: Boolean)
    begin
        InsertAsActive := Value;
        InsertAsActiveInitialized := true;
    end;

    procedure UpsertToCompany(var LogLine: Record "PLI Import Log Line"; CompanyName: Text[30]): Enum "PLI Line Import Status"
    var
        Customer: Record Customer;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        PriceListHeader.ChangeCompany(CompanyName);
        PriceListLine.ChangeCompany(CompanyName);

        // #3 Validate customer exists in target company before touching price lists
        Customer.ChangeCompany(CompanyName);
        Customer.SetLoadFields("No.");
        if not Customer.Get(LogLine."Customer No.") then begin
            LogLine."Error Message" := StrSubstNo(
                'Debitor "%1" in Mandant "%2" nicht gefunden. Preisliste wurde nicht aktualisiert.',
                LogLine."Customer No.", CompanyName);
            exit("PLI Line Import Status"::Skipped);
        end;

        // Honor explicit override code from import log (user-selected on cockpit)
        if LogLine."Price List Code" <> '' then begin
            PriceListHeader.SetLoadFields(Code, "Source Type", "Source No.", Status);
            if not PriceListHeader.Get(LogLine."Price List Code") then begin
                LogLine."Error Message" := StrSubstNo('Preisliste "%1" nicht gefunden.', LogLine."Price List Code");
                exit("PLI Line Import Status"::Error);
            end;
            if PriceListHeader.Status <> PriceListHeader.Status::Active then begin
                LogLine."Error Message" := StrSubstNo('Preisliste "%1" ist nicht aktiv.', LogLine."Price List Code");
                exit("PLI Line Import Status"::Error);
            end;
            if (PriceListHeader."Source Type" = PriceListHeader."Source Type"::Customer)
                and (PriceListHeader."Source No." <> LogLine."Customer No.")
            then begin
                LogLine."Error Message" := StrSubstNo(
                    'Preisliste "%1" gehoert Debitor "%2", nicht "%3".',
                    LogLine."Price List Code", PriceListHeader."Source No.", LogLine."Customer No.");
                exit("PLI Line Import Status"::Error);
            end;
            PriceListCode := LogLine."Price List Code";
        end else
            PriceListCode := FindOrCreateHeaderCode(LogLine."Customer No.", LogLine."Currency Code", PriceListHeader);

        PriceListLine.SetLoadFields("Price List Code", "Asset No.", "Unit of Measure Code", "Minimum Quantity", "Starting Date", "Ending Date", "Unit Price");
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
        // #2 Use Validate on Source No. and Asset No. so BC OnValidate triggers run
        // and dependent fields (description, derived types) are filled automatically.
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Customer);
        PriceListLine.Validate("Source No.", LogLine."Customer No.");
        // #1 Source Group must be set explicitly on the line for BC price finding to work
        PriceListLine."Source Group" := "Price Source Group"::Customer;
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
        PriceListLine.Validate("Asset No.", LogLine."Item No.");
        PriceListLine.Validate("Unit of Measure Code", LogLine."Unit of Measure Code");
        PriceListLine."Minimum Quantity" := LogLine."Minimum Quantity";
        PriceListLine."Unit Price" := LogLine."Unit Price";
        PriceListLine."Currency Code" := LogLine."Currency Code";
        PriceListLine."Starting Date" := LogLine."Starting Date";
        PriceListLine."Ending Date" := LogLine."Ending Date";
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;
        // #4 Draft mode: insert as Draft or Active depending on caller setting
        if GetInsertAsActive() then
            PriceListLine.Status := PriceListLine.Status::Active
        else
            PriceListLine.Status := PriceListLine.Status::Draft;
        PriceListLine.Insert(true);
        exit("PLI Line Import Status"::Imported);
    end;

    /// <summary>
    /// Returns the Code of an existing Sales Price List Header for the given
    /// customer and currency, or creates a new one if none exists.
    /// Note: PriceListHeader must already have ChangeCompany set by the caller.
    /// </summary>
    local procedure FindOrCreateHeaderCode(CustomerNo: Code[20]; CurrencyCode: Code[10]; var PriceListHeader: Record "Price List Header"): Code[20]
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Codeunit "No. Series";
        NextCode: Code[20];
    begin
        PriceListHeader.SetLoadFields(Code);
        PriceListHeader.SetRange("Price Type", PriceListHeader."Price Type"::Sale);
        PriceListHeader.SetRange("Source Type", PriceListHeader."Source Type"::Customer);
        PriceListHeader.SetRange("Source No.", CustomerNo);
        PriceListHeader.SetRange("Currency Code", CurrencyCode);
        if PriceListHeader.FindFirst() then
            exit(PriceListHeader.Code);

        // Determine new code: No. Series from Sales Setup → fallback PLI-{CustomerNo}
        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Price List Nos." <> '' then
            NextCode := CopyStr(NoSeries.GetNextNo(SalesReceivablesSetup."Price List Nos.", Today()), 1, 20)
        else
            NextCode := CopyStr('PLI-' + CustomerNo, 1, 20);

        PriceListHeader.Init();
        PriceListHeader.Code := NextCode;
        PriceListHeader."Price Type" := PriceListHeader."Price Type"::Sale;
        PriceListHeader."Source Type" := PriceListHeader."Source Type"::Customer;
        PriceListHeader."Source Group" := "Price Source Group"::Customer;
        PriceListHeader."Source No." := CustomerNo;
        PriceListHeader."Currency Code" := CurrencyCode;
        PriceListHeader.Description := StrSubstNo('JSON Import - Customer %1', CustomerNo);
        // #4 New header status follows InsertAsActive setting
        if GetInsertAsActive() then
            PriceListHeader.Status := PriceListHeader.Status::Active
        else
            PriceListHeader.Status := PriceListHeader.Status::Draft;
        PriceListHeader.Insert(true);

        exit(PriceListHeader.Code);
    end;

    var
        InsertAsActive: Boolean; // default false (= Active) intentionally; SetInsertAsActive(true) = Active
        InsertAsActiveInitialized: Boolean;

    /// <summary>
    /// Returns the effective InsertAsActive flag, defaulting to true (Active) if
    /// SetInsertAsActive was never called. A codeunit-level field defaults to false in AL,
    /// so we track initialisation separately.
    /// </summary>
    local procedure GetInsertAsActive(): Boolean
    begin
        if not InsertAsActiveInitialized then
            exit(true);
        exit(InsertAsActive);
    end;
}
