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

        // ── GUARDRAIL 1: Ending Date is mandatory for overlap detection ──────────
        // Without an end date we cannot guarantee that the new line does not
        // silently shadow an existing active line forever.
        if LogLine."Ending Date" = 0D then begin
            LogLine."Error Message" :=
                'Importzeile abgelehnt: Enddatum fehlt. Jede Importzeile muss ein Enddatum haben.';
            exit("PLI Line Import Status"::RejectedMissingEndDate);
        end;

        // ── Debitor must exist in target company (nur bei Source Type = Debitor) ──
        if (LogLine."PL Source Type" = 'Customer') or (LogLine."PL Source Type" = '') then begin
            Customer.ChangeCompany(CompanyName);
            Customer.SetLoadFields("No.");
            if not Customer.Get(LogLine."Customer No.") then begin
                LogLine."Error Message" := StrSubstNo(
                    'Debitor "%1" in Mandant "%2" nicht gefunden.',
                    LogLine."Customer No.", CompanyName);
                exit("PLI Line Import Status"::Skipped);
            end;
        end;

        // ── Resolve target price list header ─────────────────────────────────────
        if LogLine."Price List Code" <> '' then begin
            PriceListHeader.SetLoadFields(Code, "Source Type", "Source No.", Status);
            if not PriceListHeader.Get(LogLine."Price List Code") then begin
                // Code was provided in JSON priceListHeader → auto-create the price list
                PriceListCode := CreateHeaderFromJsonData(LogLine);
            end else begin
                if (PriceListHeader."Source Type" = PriceListHeader."Source Type"::Customer)
                    and (PriceListHeader."Source No." <> LogLine."Customer No.")
                    and (LogLine."PL Source Type" <> 'AllCustomers')
                then begin
                    LogLine."Error Message" := StrSubstNo(
                        'Preisliste "%1" gehoert Debitor "%2", nicht "%3".',
                        LogLine."Price List Code", PriceListHeader."Source No.", LogLine."Customer No.");
                    exit("PLI Line Import Status"::Error);
                end;
                if PriceListHeader.Status = PriceListHeader.Status::Active then
                    PriceListCode := CreateDraftCopyCode(PriceListHeader, LogLine."Customer No.", LogLine."Currency Code")
                else
                    PriceListCode := LogLine."Price List Code";
            end;
        end else
            PriceListCode := FindOrCreateDraftHeaderCode(LogLine."Customer No.", LogLine."Currency Code", PriceListHeader);

        // ── GUARDRAIL 2: Check for exact-key existing lines ───────────────────────
        // Exact match = same PriceListCode + Article + UoM + MinQty + Currency + StartDate
        // (all fields that together uniquely identify a price slot).
        PriceListLine.SetLoadFields(
            "Price List Code", "Asset No.", "Unit of Measure Code",
            "Minimum Quantity", "Starting Date", "Ending Date", "Unit Price", Status);
        PriceListLine.SetRange("Price List Code", PriceListCode);
        PriceListLine.SetRange("Asset No.", LogLine."Item No.");
        PriceListLine.SetRange("Unit of Measure Code", LogLine."Unit of Measure Code");
        PriceListLine.SetRange("Currency Code", LogLine."Currency Code");
        PriceListLine.SetRange("Minimum Quantity", LogLine."Minimum Quantity");
        PriceListLine.SetRange("Starting Date", LogLine."Starting Date");

        if PriceListLine.FindFirst() then begin
            // ── GUARDRAIL 3: Never modify an active/overlapping line ──────────────
            // An existing line is considered active/conflicting when:
            //   a) Its own status is Active, OR
            //   b) Its validity period overlaps with the new import period:
            //        existingStart <= newEnd  AND  newStart <= existingEnd (or existingEnd is open)
            if IsLineActiveOrOverlapping(PriceListLine, LogLine."Starting Date", LogLine."Ending Date") then begin
                LogLine."Error Message" := StrSubstNo(
                    'Aktive/ueberlappende Zeile [%1..%2] fuer Artikel %3, MinMgenge %4 gefunden. Neue Zeile wurde zusaetzlich angelegt (alte unveraendert).',
                    PriceListLine."Starting Date", PriceListLine."Ending Date",
                    LogLine."Item No.", LogLine."Minimum Quantity");
                InsertNewPriceLine(PriceListLine, PriceListCode, LogLine);
                exit("PLI Line Import Status"::InsertedConflictActiveOverlap);
            end;

            // Safe to update: same exact key, line is not active and does not overlap
            PriceListLine."Unit Price" := LogLine."Unit Price";
            PriceListLine."Ending Date" := LogLine."Ending Date";
            PriceListLine.Modify(true);
            exit("PLI Line Import Status"::Updated);
        end;

        // ── GUARDRAIL 4: Check for same article but DIFFERENT MinQty (warn + insert) ──
        // Purpose: detect accidental duplicates vs. intentional tiered pricing.
        PriceListLine.SetRange("Minimum Quantity"); // clear the MinQty filter
        if PriceListLine.FindSet() then
            repeat
                if IsLineActiveOrOverlapping(PriceListLine, LogLine."Starting Date", LogLine."Ending Date") then begin
                    // Different MinQty but same article + overlapping period — log warning and insert
                    LogLine."Error Message" := StrSubstNo(
                        'Hinweis (MinMenge): Artikel %1 hat bereits eine Zeile mit MinMenge %2 im Zeitraum [%3..%4]. Neue Zeile mit MinMenge %5 wurde eingefuegt (Staffelpreis?).',
                        LogLine."Item No.", PriceListLine."Minimum Quantity",
                        PriceListLine."Starting Date", PriceListLine."Ending Date",
                        LogLine."Minimum Quantity");
                    InsertNewPriceLine(PriceListLine, PriceListCode, LogLine);
                    exit("PLI Line Import Status"::InsertedMinQtyVariant);
                end;
            until PriceListLine.Next() = 0;

        // ── No existing line found — simply insert ────────────────────────────────
        InsertNewPriceLine(PriceListLine, PriceListCode, LogLine);
        exit("PLI Line Import Status"::InsertedNewLine);
    end;

    /// <summary>
    /// Returns true when the given PriceListLine is considered to be active
    /// and/or has a validity period that overlaps with [NewStart..NewEnd].
    ///
    /// Overlap condition (standard interval intersection):
    ///   existingStart &lt;= NewEnd  AND  NewStart &lt;= effectiveExistingEnd
    /// where effectiveExistingEnd = MaxDate when existingEnd is 0D (open-ended).
    /// </summary>
    local procedure IsLineActiveOrOverlapping(var Line: Record "Price List Line"; NewStart: Date; NewEnd: Date): Boolean
    var
        EffectiveEnd: Date;
    begin
        // An open-ended existing line never expires — treat as MaxDate
        if Line."Ending Date" = 0D then
            EffectiveEnd := DMY2Date(31, 12, 9999)
        else
            EffectiveEnd := Line."Ending Date";

        // Still active as of today (not yet expired)
        if EffectiveEnd >= WorkDate() then begin
            // Overlap: existing interval intersects with new import interval?
            if (Line."Starting Date" <= NewEnd) and (NewStart <= EffectiveEnd) then
                exit(true);
        end;
        exit(false);
    end;

    /// <summary>
    /// Inserts a brand-new Price List Line record for the given LogLine into PriceListCode.
    /// All header-level fields (Source, Status=Draft) are set here.
    /// </summary>
    local procedure InsertNewPriceLine(var PriceListLine: Record "Price List Line"; PriceListCode: Code[20]; var LogLine: Record "PLI Import Log Line")
    begin
        PriceListLine.Init();
        PriceListLine."Price List Code" := PriceListCode;
        PriceListLine."Price Type" := PriceListLine."Price Type"::Sale;
        case LogLine."PL Source Type" of
            'AllCustomers':
                begin
                    PriceListLine.Validate("Source Type", PriceListLine."Source Type"::"All Customers");
                    PriceListLine."Source Group" := "Price Source Group"::Customer;
                end;
            'CustomerPriceGroup':
                begin
                    PriceListLine.Validate("Source Type", PriceListLine."Source Type"::"Customer Price Group");
                    PriceListLine.Validate("Source No.", LogLine."PL Source No.");
                    PriceListLine."Source Group" := "Price Source Group"::Customer;
                end;
            'CustomerDiscGroup':
                begin
                    PriceListLine.Validate("Source Type", PriceListLine."Source Type"::"Customer Disc. Group");
                    PriceListLine.Validate("Source No.", LogLine."PL Source No.");
                    PriceListLine."Source Group" := "Price Source Group"::Customer;
                end;
            else begin
                // Default: Customer (gilt auch fuer leeres PL Source Type)
                PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Customer);
                PriceListLine.Validate("Source No.", LogLine."Customer No.");
                PriceListLine."Source Group" := "Price Source Group"::Customer;
            end;
        end;
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
        PriceListLine.Validate("Asset No.", LogLine."Item No.");
        PriceListLine.Validate("Unit of Measure Code", LogLine."Unit of Measure Code");
        PriceListLine."Minimum Quantity" := LogLine."Minimum Quantity";
        PriceListLine."Unit Price" := LogLine."Unit Price";
        PriceListLine."Currency Code" := LogLine."Currency Code";
        PriceListLine."Starting Date" := LogLine."Starting Date";
        PriceListLine."Ending Date" := LogLine."Ending Date";
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;
        if LogLine."Work Type Code" <> '' then
            PriceListLine."Work Type Code" := LogLine."Work Type Code";
        PriceListLine."Allow Line Disc." := LogLine."Allow Line Disc.";
        PriceListLine."Line Discount %" := LogLine."Line Discount %";
        PriceListLine."Allow Invoice Disc." := LogLine."Allow Invoice Disc.";
        if LogLine."VAT Bus. Posting Group" <> '' then
            PriceListLine."VAT Bus. Posting Gr. (Price)" := LogLine."VAT Bus. Posting Group";
        PriceListLine."Price Includes VAT" := LogLine."Price Includes VAT";
        // DRAFT POLICY: always Draft — activation is a separate step
        PriceListLine.Status := PriceListLine.Status::Draft;
        PriceListLine.Insert(true);
    end;

    /// <summary>
    /// Creates a new Draft Price List Header using the data from the JSON priceListHeader block
    /// (carried on LogLine."PL *" fields). The code comes from LogLine."Price List Code".
    /// Called when a code was provided in JSON but the header does not yet exist in BC.
    /// Always creates Draft. Returns the new header code.
    /// </summary>
    local procedure CreateHeaderFromJsonData(var LogLine: Record "PLI Import Log Line"): Code[20]
    var
        NewHeader: Record "Price List Header";
        EffSourceType: Enum "Price Source Type";
        EffSourceNo: Code[20];
    begin
        // Map JSON sourceType string to enum
        case LogLine."PL Source Type" of
            'AllCustomers':
                EffSourceType := "Price Source Type"::"All Customers";
            'CustomerPriceGroup':
                begin
                    EffSourceType := "Price Source Type"::"Customer Price Group";
                    EffSourceNo := LogLine."PL Source No.";
                end;
            'CustomerDiscGroup':
                begin
                    EffSourceType := "Price Source Type"::"Customer Disc. Group";
                    EffSourceNo := LogLine."PL Source No.";
                end;
            else begin
                EffSourceType := "Price Source Type"::Customer;
                // Default source no.: JSON header sourceNo, fallback to line customer
                EffSourceNo := LogLine."PL Source No.";
                if EffSourceNo = '' then
                    EffSourceNo := LogLine."Customer No.";
            end;
        end;

        NewHeader.ChangeCompany(LogLine."Company Name");
        NewHeader.Init();
        NewHeader.Code := LogLine."Price List Code";
        NewHeader."Price Type" := NewHeader."Price Type"::Sale;
        NewHeader."Source Type" := EffSourceType;
        NewHeader."Source Group" := "Price Source Group"::Customer;
        if EffSourceNo <> '' then
            NewHeader."Source No." := EffSourceNo;
        NewHeader."Currency Code" := LogLine."PL Currency Code";
        if LogLine."PL Description" <> '' then
            NewHeader.Description := LogLine."PL Description"
        else
            NewHeader.Description := StrSubstNo('JSON Import - %1', LogLine."Price List Code");
        if LogLine."PL VAT Bus. Posting Group" <> '' then
            NewHeader."VAT Bus. Posting Gr. (Price)" := LogLine."PL VAT Bus. Posting Group";
        NewHeader."Price Includes VAT" := LogLine."PL Price Includes VAT";
        NewHeader."Allow Updating Defaults" := LogLine."PL Allow Updating Defaults";
        NewHeader."Allow Invoice Disc." := LogLine."PL Allow Invoice Disc.";
        NewHeader."Allow Line Disc." := LogLine."PL Allow Line Disc.";
        case LogLine."PL Amount Type" of
            'Discount':
                NewHeader."Amount Type" := NewHeader."Amount Type"::Discount;
            'Any':
                NewHeader."Amount Type" := NewHeader."Amount Type"::Any;
            else
                NewHeader."Amount Type" := NewHeader."Amount Type"::Price;
        end;
        if LogLine."PL Valid From" <> 0D then
            NewHeader."Starting Date" := LogLine."PL Valid From";
        if LogLine."PL Valid To" <> 0D then
            NewHeader."Ending Date" := LogLine."PL Valid To";
        // DRAFT POLICY: always Draft on import
        NewHeader.Status := NewHeader.Status::Draft;
        NewHeader.Insert(true);
        exit(NewHeader.Code);
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
