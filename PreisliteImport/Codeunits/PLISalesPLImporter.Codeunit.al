/// <summary>
/// Concrete implementation of IPLIPriceListImporter for Sales Price Lists.
/// Handles JSON type 'SalesPricelist': upserts Price List Header + Price List Line
/// in the target company using ChangeCompany for cross-company access.
///
/// DRAFT-ONLY POLICY:
///   Imported price lists are ALWAYS written as Draft (Status = Draft).
///   Activation is only possible through the explicit "PLI Activate Price List" page
///   or Codeunit "PLI Price List Activation". The guardrail codeunit
///   "PLI Price List Guardrail" blocks any direct Active insert/modify.
///
/// Active-target handling:
///   If the target price list (by override code or found by customer+currency) is
///   already Active, a new Draft copy is created with a fresh No. Series code.
///   The original Active list is not touched.
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
    /// SetInsertAsActive is kept for interface compatibility but intentionally ignored.
    /// This implementation ALWAYS inserts as Draft. Activation is a separate step.
    /// </summary>
    procedure SetInsertAsActive(Value: Boolean)
    begin
        // Intentionally ignored — import always creates Draft. Use PLI Price List Activation.
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
            if (PriceListHeader."Source Type" = PriceListHeader."Source Type"::Customer)
                and (PriceListHeader."Source No." <> LogLine."Customer No.")
            then begin
                LogLine."Error Message" := StrSubstNo(
                    'Preisliste "%1" gehoert Debitor "%2", nicht "%3".',
                    LogLine."Price List Code", PriceListHeader."Source No.", LogLine."Customer No.");
                exit("PLI Line Import Status"::Error);
            end;
            // DRAFT POLICY: if the target list is Active, create a new Draft copy instead
            if PriceListHeader.Status = PriceListHeader.Status::Active then
                PriceListCode := CreateDraftCopyCode(PriceListHeader, LogLine."Customer No.", LogLine."Currency Code")
            else
                PriceListCode := LogLine."Price List Code";
        end else
            PriceListCode := FindOrCreateDraftHeaderCode(LogLine."Customer No.", LogLine."Currency Code", PriceListHeader);

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
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Customer);
        PriceListLine.Validate("Source No.", LogLine."Customer No.");
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
        // DRAFT POLICY: lines are always Draft — activation is a separate step
        PriceListLine.Status := PriceListLine.Status::Draft;
        PriceListLine.Insert(true);
        exit("PLI Line Import Status"::Imported);
    end;

    /// <summary>
    /// Finds an existing DRAFT Sales Price List Header for the given customer/currency,
    /// or creates a new Draft one. If only an Active header exists, a new Draft is created
    /// alongside it (so the Active list is never touched by the import).
    /// </summary>
    local procedure FindOrCreateDraftHeaderCode(CustomerNo: Code[20]; CurrencyCode: Code[10]; var PriceListHeader: Record "Price List Header"): Code[20]
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Codeunit "No. Series";
        NextCode: Code[20];
    begin
        // Prefer an existing Draft header for the same customer+currency
        PriceListHeader.SetLoadFields(Code, Status);
        PriceListHeader.SetRange("Price Type", PriceListHeader."Price Type"::Sale);
        PriceListHeader.SetRange("Source Type", PriceListHeader."Source Type"::Customer);
        PriceListHeader.SetRange("Source No.", CustomerNo);
        PriceListHeader.SetRange("Currency Code", CurrencyCode);
        PriceListHeader.SetRange(Status, PriceListHeader.Status::Draft);
        if PriceListHeader.FindFirst() then
            exit(PriceListHeader.Code);

        // No Draft found — create a new one
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
        // DRAFT POLICY: always Draft on import
        PriceListHeader.Status := PriceListHeader.Status::Draft;
        PriceListHeader.Insert(true);
        exit(PriceListHeader.Code);
    end;

    /// <summary>
    /// Creates a new Draft copy of an Active price list header and returns its code.
    /// Called when the user explicitly selected an Active list as override target.
    /// The new list is a sibling (same customer/currency) but with Draft status.
    /// </summary>
    local procedure CreateDraftCopyCode(var SourceHeader: Record "Price List Header"; CustomerNo: Code[20]; CurrencyCode: Code[10]): Code[20]
    var
        NewHeader: Record "Price List Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Codeunit "No. Series";
        NextCode: Code[20];
    begin
        NewHeader.ChangeCompany(SourceHeader.CurrentCompany);
        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Price List Nos." <> '' then
            NextCode := CopyStr(NoSeries.GetNextNo(SalesReceivablesSetup."Price List Nos.", Today()), 1, 20)
        else
            NextCode := CopyStr('PLI-' + CustomerNo + '-D', 1, 20);

        NewHeader.Init();
        NewHeader.Code := NextCode;
        NewHeader."Price Type" := SourceHeader."Price Type";
        NewHeader."Source Type" := SourceHeader."Source Type";
        NewHeader."Source Group" := SourceHeader."Source Group";
        NewHeader."Source No." := CustomerNo;
        NewHeader."Currency Code" := CurrencyCode;
        NewHeader.Description := StrSubstNo('JSON Import (Entwurf) - %1', SourceHeader.Code);
        // DRAFT POLICY: new copy is always Draft
        NewHeader.Status := NewHeader.Status::Draft;
        NewHeader.Insert(true);
        exit(NewHeader.Code);
    end;
}
