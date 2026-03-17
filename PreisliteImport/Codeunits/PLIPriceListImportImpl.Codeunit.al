codeunit 70101 "PLI Price List Import Impl."
{
    Access = Internal;

    // ------------------------------------------------------------------
    // Entry points (called from facade)
    // ------------------------------------------------------------------

    procedure ImportFromBlob(var TempBlob: Codeunit "Temp Blob"; FileName: Text; CompanyFilter: Text[30]; PriceListCode: Code[20])
    var
        PLIImportLog: Record "PLI Import Log";
        JsonInStream: InStream;
        JsonContent: Text;
    begin
        TempBlob.CreateInStream(JsonInStream);
        JsonInStream.ReadText(JsonContent);

        CreateImportLog(PLIImportLog, FileName, CompanyFilter, PriceListCode);
        ParseAndImport(PLIImportLog, JsonContent, CompanyFilter);
        UpdateImportLogStatus(PLIImportLog);
    end;

    procedure RunImport(var ImportLog: Record "PLI Import Log")
    var
        JsonInStream: InStream;
        JsonContent: Text;
    begin
        // #8 Guard: skip log entries that have already been processed successfully
        if ImportLog.Status = ImportLog.Status::Success then
            exit;

        ImportLog."Import DateTime" := CurrentDateTime();
        ImportLog."User ID" := CopyStr(UserId(), 1, 50);
        ImportLog.Status := ImportLog.Status::Running;
        ImportLog.Modify();

        ImportLog.CalcFields("JSON Content");
        ImportLog."JSON Content".CreateInStream(JsonInStream);
        JsonInStream.ReadText(JsonContent);

        ParseAndImport(ImportLog, JsonContent, ImportLog."Company Filter");
        UpdateImportLogStatus(ImportLog);
    end;

    /// <summary>
    /// Parses JSON metadata and prices array without any DB writes.
    /// Called by the facade's GetPreviewData for the import preview dialog.
    /// UniqueCustomerCount = number of distinct 'customerNo' values in the prices array.
    /// </summary>
    procedure ParseJsonMetadata(JsonContent: Text; var ImportType: Text[50]; var ValidFrom: Date; var ValidTo: Date; var LineCount: Integer; var UniqueCustomerCount: Integer)
    var
        JsonObj: JsonObject;
        MetaToken: JsonToken;
        TypeToken: JsonToken;
        ValidFromToken: JsonToken;
        ValidToToken: JsonToken;
        PricesToken: JsonToken;
        PricesArray: JsonArray;
        PriceToken: JsonToken;
        CustToken: JsonToken;
        CustomerSet: Dictionary of [Text, Boolean];
        CustNo: Text;
        DateText: Text;
        i: Integer;
    begin
        if not JsonObj.ReadFrom(JsonContent) then
            exit;

        if JsonObj.Get('metadata', MetaToken) then begin
            if MetaToken.AsObject().Get('type', TypeToken) then
                ImportType := CopyStr(TypeToken.AsValue().AsText(), 1, 50);

            if MetaToken.AsObject().Get('validFrom', ValidFromToken) then begin
                DateText := ValidFromToken.AsValue().AsText();
                if DateText <> '' then
                    ValidFrom := ValidFromToken.AsValue().AsDate();
            end;

            if MetaToken.AsObject().Get('validTo', ValidToToken) then begin
                DateText := ValidToToken.AsValue().AsText();
                if DateText <> '' then
                    ValidTo := ValidToToken.AsValue().AsDate();
            end;
        end;

        if JsonObj.Get('prices', PricesToken) then begin
            PricesArray := PricesToken.AsArray();
            LineCount := PricesArray.Count();
            // #7 Count distinct customer numbers for multi-customer warning
            for i := 0 to PricesArray.Count() - 1 do begin
                PricesArray.Get(i, PriceToken);
                if PriceToken.AsObject().Get('customerNo', CustToken) then begin
                    CustNo := CustToken.AsValue().AsText();
                    if not CustomerSet.ContainsKey(CustNo) then
                        CustomerSet.Add(CustNo, true);
                end;
            end;
            UniqueCustomerCount := CustomerSet.Count();
        end;
    end;

    // ------------------------------------------------------------------
    // Log management
    // ------------------------------------------------------------------

    local procedure CreateImportLog(var ImportLog: Record "PLI Import Log"; FileName: Text; CompanyFilter: Text[30]; PriceListCode: Code[20])
    begin
        ImportLog.Init();
        ImportLog."Import DateTime" := CurrentDateTime();
        ImportLog."User ID" := CopyStr(UserId(), 1, 50);
        ImportLog."File Name" := CopyStr(FileName, 1, 250);
        ImportLog."Company Filter" := CompanyFilter;
        ImportLog."Price List Code" := PriceListCode;
        ImportLog.Status := ImportLog.Status::Running;
        ImportLog.Insert(true);
    end;

    local procedure UpdateImportLogStatus(var ImportLog: Record "PLI Import Log")
    begin
        if ImportLog."Error Lines" = 0 then
            ImportLog.Status := ImportLog.Status::Success
        else
            if ImportLog."Imported Lines" > 0 then
                ImportLog.Status := ImportLog.Status::Partial
            else
                ImportLog.Status := ImportLog.Status::Failed;
        ImportLog.Modify();
    end;

    local procedure SetImportLogFailed(var ImportLog: Record "PLI Import Log"; ErrorMessage: Text)
    begin
        ImportLog."Error Message" := CopyStr(ErrorMessage, 1, MaxStrLen(ImportLog."Error Message"));
        ImportLog.Status := ImportLog.Status::Failed;
        ImportLog.Modify();
    end;

    // ------------------------------------------------------------------
    // JSON parsing & dispatch
    // ------------------------------------------------------------------

    local procedure ParseAndImport(var ImportLog: Record "PLI Import Log"; JsonContent: Text; CompanyFilter: Text[30])
    var
        JsonObj: JsonObject;
        PricesToken: JsonToken;
        PricesArray: JsonArray;
        PriceToken: JsonToken;
        Importer: Interface "IPLIPriceListImporter";
        ImportType: Text[50];
        LineNo: Integer;
        i: Integer;
    begin
        if not JsonObj.ReadFrom(JsonContent) then begin
            SetImportLogFailed(ImportLog, 'Invalid JSON: could not parse the file.');
            exit;
        end;

        ImportType := ReadMetadataType(JsonObj);
        if not ResolveImporter(ImportType, Importer) then begin
            SetImportLogFailed(ImportLog, StrSubstNo('Unsupported import type "%1".', ImportType));
            exit;
        end;

        // SetInsertAsActive is intentionally a no-op in the importer — always Draft
        Importer.SetInsertAsActive(false);

        if not JsonObj.Get('prices', PricesToken) then begin
            SetImportLogFailed(ImportLog, 'JSON does not contain a "prices" array.');
            exit;
        end;

        PricesArray := PricesToken.AsArray();
        ImportLog."Total Lines" := PricesArray.Count();
        ImportLog.Modify();

        for i := 0 to PricesArray.Count() - 1 do begin
            PricesArray.Get(i, PriceToken);
            LineNo += 1;
            ProcessPriceLine(ImportLog, PriceToken.AsObject(), LineNo, CompanyFilter, Importer);
        end;
    end;

    local procedure ReadMetadataType(JsonObj: JsonObject): Text[50]
    var
        MetaToken: JsonToken;
        TypeToken: JsonToken;
    begin
        if not JsonObj.Get('metadata', MetaToken) then
            exit('');
        if not MetaToken.AsObject().Get('type', TypeToken) then
            exit('');
        exit(CopyStr(TypeToken.AsValue().AsText(), 1, 50));
    end;

    /// <summary>
    /// Iterates all registered PLI Importer Type enum values and returns
    /// the first one whose GetImportType() matches the JSON type string.
    /// Fully extensible: adding a new enum value requires no changes here.
    /// </summary>
    local procedure ResolveImporter(ImportType: Text[50]; var Importer: Interface "IPLIPriceListImporter"): Boolean
    var
        ImporterOrdinals: List of [Integer];
        OrdinalValue: Integer;
        CurrentType: Enum "PLI Importer Type";
        Candidate: Interface "IPLIPriceListImporter";
    begin
        ImporterOrdinals := Enum::"PLI Importer Type".Ordinals();
        foreach OrdinalValue in ImporterOrdinals do begin
            CurrentType := Enum::"PLI Importer Type".FromInteger(OrdinalValue);
            Candidate := CurrentType;
            if Candidate.GetImportType() = ImportType then begin
                Importer := Candidate;
                exit(true);
            end;
        end;
        exit(false);
    end;

    // ------------------------------------------------------------------
    // Price line processing
    // ------------------------------------------------------------------

    local procedure ProcessPriceLine(var ImportLog: Record "PLI Import Log"; LineObj: JsonObject; LineNo: Integer; CompanyFilter: Text[30]; Importer: Interface "IPLIPriceListImporter")
    var
        PLIImportLogLine: Record "PLI Import Log Line";
    begin
        PLIImportLogLine.Init();
        PLIImportLogLine."Entry No." := ImportLog."Entry No.";
        PLIImportLogLine."Line No." := LineNo;
        PLIImportLogLine."Company Name" := CompanyFilter;
        PLIImportLogLine."Price List Code" := ImportLog."Price List Code";
        PopulateLogLineFromJson(PLIImportLogLine, LineObj);

        if (PLIImportLogLine."Customer No." = '') or (PLIImportLogLine."Item No." = '') then begin
            PLIImportLogLine.Status := PLIImportLogLine.Status::Error;
            PLIImportLogLine."Error Message" := 'customerNo or itemNo is missing.';
            PLIImportLogLine.Insert();
            ImportLog."Error Lines" += 1;
            ImportLog.Modify();
            exit;
        end;

        if CompanyFilter = '' then
            ImportToAllCompanies(ImportLog, PLIImportLogLine, Importer)
        else
            ImportToSingleCompany(ImportLog, PLIImportLogLine, CompanyFilter, Importer);

        PLIImportLogLine.Insert();
    end;

    local procedure PopulateLogLineFromJson(var PLIImportLogLine: Record "PLI Import Log Line"; LineObj: JsonObject)
    var
        AllowLineDiscToken: JsonToken;
        AllowInvDiscToken: JsonToken;
    begin
        PLIImportLogLine."Customer No." := CopyStr(GetJsonText(LineObj, 'customerNo'), 1, 20);
        PLIImportLogLine."Item No." := CopyStr(GetJsonText(LineObj, 'itemNo'), 1, 20);
        PLIImportLogLine."Unit of Measure Code" := CopyStr(GetJsonText(LineObj, 'unitOfMeasure'), 1, 10);
        PLIImportLogLine."Minimum Quantity" := GetJsonDecimal(LineObj, 'minimumQuantity');
        PLIImportLogLine."Unit Price" := GetJsonDecimal(LineObj, 'unitPrice');
        PLIImportLogLine."Currency Code" := CopyStr(GetJsonText(LineObj, 'currency'), 1, 10);
        PLIImportLogLine."Starting Date" := GetJsonDate(LineObj, 'startingDate');
        PLIImportLogLine."Ending Date" := GetJsonDate(LineObj, 'endingDate');
        PLIImportLogLine."Work Type Code" := CopyStr(GetJsonText(LineObj, 'workTypeCode'), 1, 10);
        PLIImportLogLine."Line Discount %" := GetJsonDecimal(LineObj, 'lineDiscountPct');
        // Boolean fields: default to true when not present in JSON (matches BC Price List Line InitValue)
        if LineObj.Get('allowLineDisc', AllowLineDiscToken) then
            PLIImportLogLine."Allow Line Disc." := AllowLineDiscToken.AsValue().AsBoolean()
        else
            PLIImportLogLine."Allow Line Disc." := true;
        if LineObj.Get('allowInvoiceDisc', AllowInvDiscToken) then
            PLIImportLogLine."Allow Invoice Disc." := AllowInvDiscToken.AsValue().AsBoolean()
        else
            PLIImportLogLine."Allow Invoice Disc." := true;
    end;

    local procedure ImportToAllCompanies(var ImportLog: Record "PLI Import Log"; var PLIImportLogLine: Record "PLI Import Log Line"; Importer: Interface "IPLIPriceListImporter")
    var
        Company: Record Company;
    begin
        Company.SetRange("Evaluation Company", false);
        Company.SetLoadFields(Name);
        if not Company.FindSet() then
            exit;
        repeat
            ImportToSingleCompany(ImportLog, PLIImportLogLine, Company.Name, Importer);
        until Company.Next() = 0;
    end;

    local procedure ImportToSingleCompany(var ImportLog: Record "PLI Import Log"; var PLIImportLogLine: Record "PLI Import Log Line"; CompanyName: Text[30]; Importer: Interface "IPLIPriceListImporter")
    begin
        PLIImportLogLine."Company Name" := CompanyName;
        PLIImportLogLine.Status := Importer.UpsertToCompany(PLIImportLogLine, CompanyName);
        if PLIImportLogLine.Status in [PLIImportLogLine.Status::Imported, PLIImportLogLine.Status::Updated] then
            ImportLog."Imported Lines" += 1
        else
            ImportLog."Error Lines" += 1;
        ImportLog.Modify();
    end;

    // ------------------------------------------------------------------
    // JSON helper methods
    // ------------------------------------------------------------------

    local procedure GetJsonText(JsonObj: JsonObject; KeyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not JsonObj.Get(KeyName, Token) then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure GetJsonDecimal(JsonObj: JsonObject; KeyName: Text): Decimal
    var
        Token: JsonToken;
    begin
        if not JsonObj.Get(KeyName, Token) then
            exit(0);
        exit(Token.AsValue().AsDecimal());
    end;

    local procedure GetJsonDate(JsonObj: JsonObject; KeyName: Text): Date
    var
        Token: JsonToken;
        DateText: Text;
    begin
        if not JsonObj.Get(KeyName, Token) then
            exit(0D);
        DateText := Token.AsValue().AsText();
        if DateText = '' then
            exit(0D);
        exit(Token.AsValue().AsDate());
    end;
}
