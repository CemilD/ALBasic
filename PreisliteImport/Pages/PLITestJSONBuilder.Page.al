/// <summary>
/// Test tool for the PLI import pipeline that mirrors the layout of the standard
/// Sales Price List page (Page 7016 / Price List Header 7000).
///
/// • Same header fields: Code, Status, Beschreibung, Waehrungscode,
///   Zuweisen zu Typ, Zuweisen zu Nr., Startdatum, Enddatum
/// • Same line columns in the same order (Zuweisen zu Typ, Zuweisen zu Nr.,
///   Waehrungscode, Startdatum, Enddatum, Produkttyp, Produktnr., Beschreibung,
///   Variantencode, Einheit, Mindestmenge, VK-Preis)
/// • Pflichtfeldmarkierung (ShowMandatory) on Item No. and Source No.
/// • "Zeilen pruefen" validates all lines BEFORE export and shows errors inline
///   (orange row + Fehler column, no popup)
/// • New lines automatically inherit header defaults (Source, Currency, Dates)
/// </summary>
page 70105 "PLI Test JSON Builder"
{
    Caption = 'Verkaufspreisliste (Test-JSON)';
    PageType = Card;
    UsageCategory = Tasks;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            // -------------------------------------------------------
            // Block 1 – mirrors "Allgemein" group of Sales Price List
            // -------------------------------------------------------
            group(GeneralGroup)
            {
                Caption = 'Allgemein';
                ShowCaption = false;

                // Row 1: Code | Status
                field(CodeField; HeaderCode)
                {
                    Caption = 'Code';
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Eindeutiger Code fuer diese Test-Preisliste. Wird als Dateiname beim JSON-Download verwendet. Klicken Sie auf "..." um einen Vorschlag zu generieren.';

                    trigger OnAssistEdit()
                    begin
                        HeaderCode := CopyStr('TEST-' + Format(Today(), 0, '<Year4><Month,2><Day,2>'), 1, 20);
                        CurrPage.Update(false);
                    end;
                }
                field(StatusField; HeaderStatus)
                {
                    Caption = 'Status';
                    ApplicationArea = All;
                    ToolTip = 'Aktiv = neue Preislisten und -zeilen werden sofort aktiv gesetzt (wirkt im naechsten Verkaufsbeleg). Entwurf = manuelle Freigabe in BC erforderlich.';

                    trigger OnValidate()
                    begin
                        ClearHeaderError();
                    end;
                }
                // Row 2: Beschreibung | Waehrungscode
                field(DescriptionField; HeaderDescription)
                {
                    Caption = 'Beschreibung';
                    ApplicationArea = All;
                    ToolTip = 'Beschreibungstext. Nur zur Dokumentation, nicht im JSON enthalten.';
                }
                field(CurrencyCodeField; HeaderCurrencyCode)
                {
                    Caption = 'Waehrungscode';
                    ApplicationArea = All;
                    ToolTip = 'Standard-Waehrung fuer alle Zeilen. Kann pro Zeile ueberschrieben werden.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Currency: Record Currency;
                        CurrencyList: Page Currencies;
                    begin
                        CurrencyList.LookupMode(true);
                        if CurrencyList.RunModal() = Action::LookupOK then begin
                            CurrencyList.GetRecord(Currency);
                            HeaderCurrencyCode := Currency.Code;
                            Text := Currency.Code;
                            PushHeaderDefaults();
                            exit(true);
                        end;
                        exit(false);
                    end;

                    trigger OnValidate()
                    begin
                        PushHeaderDefaults();
                    end;
                }
                // Row 3: Zuweisen zu Typ | Startdatum
                field(SourceTypeField; HeaderSourceType)
                {
                    Caption = 'Zuweisen zu Typ';
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Preisquellentyp. "Debitor" = Pflichtfeld "Zuweisen zu Nr.". "Alle Debitoren" = kein Debitor am Kopf, Debitorennr. muss pro Zeile eingetragen werden.';

                    trigger OnValidate()
                    begin
                        SourceNoVisible := HeaderSourceType = "Price Source Type"::Customer;
                        SourceNoMandatoryHdr := SourceNoVisible;
                        if not SourceNoVisible then
                            HeaderSourceNo := '';
                        PushHeaderDefaults();
                        ClearHeaderError();
                        CurrPage.Update(false);
                    end;
                }
                field(ValidFromField; HeaderValidFrom)
                {
                    Caption = 'Startdatum';
                    ApplicationArea = All;
                    ToolTip = 'Startdatum fuer den JSON-Metadaten-Block (validFrom). Leer = kein Startdatum im JSON.';

                    trigger OnValidate()
                    begin
                        PushHeaderDefaults();
                    end;
                }
                // Row 4: Zuweisen zu Nr. | Enddatum
                field(SourceNoField; HeaderSourceNo)
                {
                    Caption = 'Zuweisen zu Nr.';
                    ApplicationArea = All;
                    ShowMandatory = SourceNoMandatoryHdr;
                    Visible = SourceNoVisible;
                    ToolTip = 'Debitorennummer wenn Zuweisen zu Typ = Debitor. Wird als Standard-customerNo fuer alle neuen Zeilen uebernommen.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Customer: Record Customer;
                        CustomerList: Page "Customer List";
                    begin
                        CustomerList.LookupMode(true);
                        if CustomerList.RunModal() = Action::LookupOK then begin
                            CustomerList.GetRecord(Customer);
                            HeaderSourceNo := Customer."No.";
                            Text := Customer."No.";
                            PushHeaderDefaults();
                            ClearHeaderError();
                            exit(true);
                        end;
                        exit(false);
                    end;

                    trigger OnValidate()
                    begin
                        PushHeaderDefaults();
                        ClearHeaderError();
                    end;
                }
                field(ValidToField; HeaderValidTo)
                {
                    Caption = 'Enddatum';
                    ApplicationArea = All;
                    ToolTip = 'Enddatum fuer den JSON-Metadaten-Block (validTo). Leer = unbefristet (kein validTo-Feld im JSON).';

                    trigger OnValidate()
                    begin
                        PushHeaderDefaults();
                    end;
                }
            }

            // -------------------------------------------------------
            // Block 2 – mirrors "Anzeigen" group of Sales Price List
            // -------------------------------------------------------
            group(ShowGroup)
            {
                Caption = 'Anzeigen';

                field(AmountTypeField; AmountTypeTxt)
                {
                    Caption = 'Spalten anzeigen fuer';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Dieses Format importiert ausschliesslich Preise (kein Rabatt).';
                }
                field(ImportTypeField; ImportType)
                {
                    Caption = 'JSON-Typ  (type)';
                    ApplicationArea = All;
                    ToolTip = 'Import-Typ im JSON-Metadaten-Block. Muss einem registrierten Importer entsprechen. Standard: SalesPricelist.';
                }
            }

            // -------------------------------------------------------
            // Block 3 – inline error summary (hidden when no errors)
            // -------------------------------------------------------
            group(ErrorGroup)
            {
                Caption = 'Validierungsfehler';
                Visible = HasHeaderError;

                field(HeaderErrorField; HeaderError)
                {
                    Caption = '';
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                    StyleExpr = HeaderErrorStyle;
                    ToolTip = 'Fehlermeldung aus der Zeilenvalidierung. Korrigieren Sie die markierten Zeilen und klicken Sie erneut auf "Zeilen pruefen".';
                }
            }

            // -------------------------------------------------------
            // Block 4 – Zeilen (mirrors the "Zeilen" ListPart)
            // -------------------------------------------------------
            part(LinesSubPage; "PLI Test JSON Line Subpage")
            {
                Caption = 'Zeilen';
                ApplicationArea = All;
            }

            // -------------------------------------------------------
            // Block 5 – Test-Einstellungen (extra, not in standard page)
            // -------------------------------------------------------
            group(TestSettingsGroup)
            {
                Caption = 'Test-Einstellungen';

                field(CompanyFilterField; CompanyFilter)
                {
                    Caption = 'Ziel-Mandant';
                    ApplicationArea = All;
                    ToolTip = 'Mandant fuer den Direktimport-Test. Leer = alle aktiven Mandanten.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Company: Record Company;
                        CompanyList: Page "Companies";
                    begin
                        CompanyList.LookupMode(true);
                        if CompanyList.RunModal() = Action::LookupOK then begin
                            CompanyList.GetRecord(Company);
                            CompanyFilter := Company.Name;
                            Text := Company.Name;
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            // Row 1 (mirrors standard top actions)
            action(ValidateLines)
            {
                Caption = 'Zeilen pruefen...';
                ApplicationArea = All;
                Image = Approve;
                ToolTip = 'Alle Zeilen auf Pflichtfelder und Konsistenz pruefen. Fehler werden direkt in der Zeilentabelle (orange) und im Fehlerblock oben angezeigt.';

                trigger OnAction()
                begin
                    if ValidateBeforeExport() then
                        Message('Alle Zeilen sind gueltig. Sie koennen das JSON jetzt herunterladen oder direkt importieren.')
                    else
                        CurrPage.Update(false);
                end;
            }
            action(SuggestLines)
            {
                Caption = 'Zeilen vorschlagen...';
                ApplicationArea = All;
                Image = SuggestLines;
                ToolTip = 'Preiszeilen automatisch aus dem Artikelstamm vorschlagen. Artikellistenpreise koennen per Korrekturfaktor angepasst werden.';

                trigger OnAction()
                begin
                    RunSuggestLines();
                end;
            }
            action(DownloadJson)
            {
                Caption = 'JSON herunterladen';
                ApplicationArea = All;
                Image = ExportFile;
                ToolTip = 'Aktuelle Eingaben als JSON-Datei herunterladen. Kann anschliessend ueber den Import-Cockpit importiert werden. Vor dem Download wird eine Validierung durchgefuehrt.';

                trigger OnAction()
                begin
                    DownloadJsonFile();
                end;
            }
            action(DirectImport)
            {
                Caption = 'Direkt importieren && testen';
                ApplicationArea = All;
                Image = TestDatabase;
                ToolTip = 'JSON sofort in den Ziel-Mandanten importieren. Vor dem Import wird eine Validierung durchgefuehrt. Ergebnis im Import-Log pruefen.';

                trigger OnAction()
                begin
                    DirectImportJson();
                end;
            }
            separator(SepSamples)
            {
            }
            action(LoadSampleData)
            {
                Caption = 'Beispieldaten laden';
                ApplicationArea = All;
                Image = CreateDocument;
                ToolTip = 'Kopffelder und eine Muster-Preiszeile mit Platzhalter-Werten befuellen. Bestehende Zeilen werden geloescht.';

                trigger OnAction()
                begin
                    PopulateSampleData();
                end;
            }
            action(OpenLog)
            {
                Caption = 'Import-Log oeffnen';
                ApplicationArea = All;
                Image = Report;
                RunObject = Page "PLI Import Log List";
                ToolTip = 'Import-Protokoll oeffnen um das Testergebnis zu pruefen.';
            }
        }

        area(Promoted)
        {
            actionref(ValidateLines_Promoted; ValidateLines) { }
            actionref(SuggestLines_Promoted; SuggestLines) { }
            actionref(DownloadJson_Promoted; DownloadJson) { }
            actionref(DirectImport_Promoted; DirectImport) { }
            actionref(LoadSampleData_Promoted; LoadSampleData) { }
            actionref(OpenLog_Promoted; OpenLog) { }
        }
    }

    trigger OnOpenPage()
    begin
        ImportType := 'SalesPricelist';
        AmountTypeTxt := 'Preis';
        HeaderStatus := "Price Status"::Active;
        HeaderSourceType := "Price Source Type"::Customer;
        SourceNoVisible := true;
        SourceNoMandatoryHdr := true;
        HeaderValidFrom := Today();
        HeaderErrorStyle := 'Attention';
        // Push initial defaults so the first new line is pre-filled
        PushHeaderDefaults();
    end;

    var
        ImportType: Text[50];
        AmountTypeTxt: Text[20];
        HeaderCode: Code[20];
        HeaderDescription: Text[100];
        HeaderSourceType: Enum "Price Source Type";
        HeaderSourceNo: Code[20];
        HeaderCurrencyCode: Code[10];
        HeaderValidFrom: Date;
        HeaderValidTo: Date;
        HeaderStatus: Enum "Price Status";
        CompanyFilter: Text[30];
        SourceNoVisible: Boolean;
        SourceNoMandatoryHdr: Boolean;
        HeaderError: Text;
        HeaderErrorStyle: Text;
        HasHeaderError: Boolean;

    /// <summary>
    /// Opens the "Zeilen vorschlagen" dialog, then creates one line per matching
    /// Item using the dialog parameters (filter, factor, rounding, dates).
    /// Mirrors the behaviour of the standard BC "Suggest Price Lines" (Page 7021).
    /// </summary>
    local procedure RunSuggestLines()
    var
        TempFilter: Record "PLI Test Suggest Filter" temporary;
        SuggestPage: Page "PLI Test Suggest Lines";
        Item: Record Item;
        NewLine: Record "PLI Test JSON Line Buffer" temporary;
        NextLineNo: Integer;
        CalcPrice: Decimal;
    begin
        // Pre-fill dialog defaults from current header
        TempFilter.Init();
        TempFilter."Entry No." := 1;
        TempFilter."Adjustment Factor" := 1;
        TempFilter."Rounding Precision" := 0.01;
        TempFilter."Starting Date" := HeaderValidFrom;
        TempFilter."Ending Date" := HeaderValidTo;
        TempFilter.Insert();

        SuggestPage.SetRecord(TempFilter);
        SuggestPage.LookupMode(true);
        if SuggestPage.RunModal() <> Action::LookupOK then
            exit;
        SuggestPage.GetRecord(TempFilter);

        // Apply item filter
        Item.SetLoadFields("No.", Description, "Unit Price", "Base Unit of Measure");
        if TempFilter."Asset Filter" <> '' then
            Item.SetFilter("No.", TempFilter."Asset Filter");
        if not Item.FindSet() then begin
            Message('Keine Artikel gefunden die dem Filter "%1" entsprechen.', TempFilter."Asset Filter");
            exit;
        end;

        NextLineNo := CurrPage.LinesSubPage.Page.GetNextLineNo();

        repeat
            // Calculate adjusted price
            if TempFilter."Rounding Precision" > 0 then
                CalcPrice := Round(Item."Unit Price" * TempFilter."Adjustment Factor", TempFilter."Rounding Precision")
            else
                CalcPrice := Item."Unit Price" * TempFilter."Adjustment Factor";

            NewLine.Init();
            NewLine."Line No." := NextLineNo;
            NewLine."Asset Type" := "Price Asset Type"::Item;
            NewLine."Source Type" := HeaderSourceType;
            NewLine."Source No." := HeaderSourceNo;
            NewLine."Currency Code" := HeaderCurrencyCode;
            NewLine."Starting Date" := TempFilter."Starting Date";
            NewLine."Ending Date" := TempFilter."Ending Date";
            NewLine."Item No." := Item."No.";
            NewLine.Description := CopyStr(Item.Description, 1, MaxStrLen(NewLine.Description));
            NewLine."Unit of Measure Code" := Item."Base Unit of Measure";
            NewLine."Minimum Quantity" := TempFilter."Minimum Quantity";
            NewLine."Unit Price" := CalcPrice;
            CurrPage.LinesSubPage.Page.AddLine(NewLine);

            NextLineNo += 10000;
        until Item.Next() = 0;
    end;

    /// <summary>
    /// Forwards current header defaults to the subpage so new lines inherit them.
    /// Call after any header field that affects line defaults changes.
    /// </summary>
    local procedure PushHeaderDefaults()
    begin
        CurrPage.LinesSubPage.Page.SetHeaderDefaults(
            HeaderSourceType, HeaderSourceNo, HeaderCurrencyCode, HeaderValidFrom, HeaderValidTo);
    end;

    local procedure SetHeaderError(ErrMsg: Text)
    begin
        HeaderError := ErrMsg;
        HasHeaderError := ErrMsg <> '';
    end;

    local procedure ClearHeaderError()
    begin
        SetHeaderError('');
    end;

    /// <summary>
    /// Validates all lines before JSON generation or direct import.
    /// Writes per-line errors back to the subpage (colored rows + Fehler column).
    /// Returns true only when all lines are valid.
    /// </summary>
    local procedure ValidateBeforeExport(): Boolean
    var
        TempLines: Record "PLI Test JSON Line Buffer" temporary;
        ErrLines: Record "PLI Test JSON Line Buffer" temporary;
        ErrTxt: Text[500];
        AllOk: Boolean;
    begin
        ClearHeaderError();

        if HeaderCode = '' then begin
            SetHeaderError('"Code" ist ein Pflichtfeld. Klicken Sie auf "..." um einen Code zu generieren.');
            exit(false);
        end;

        if (HeaderSourceType = "Price Source Type"::Customer) and (HeaderSourceNo = '') then begin
            SetHeaderError('"Zuweisen zu Nr." ist ein Pflichtfeld wenn Zuweisen zu Typ = Debitor.');
            exit(false);
        end;

        CurrPage.LinesSubPage.Page.GetTempTable(TempLines);
        if not TempLines.FindFirst() then begin
            SetHeaderError('Keine Zeilen vorhanden. Mindestens eine Preiszeile ist erforderlich.');
            exit(false);
        end;

        AllOk := true;
        if TempLines.FindSet() then
            repeat
                ErrTxt := '';
                if TempLines."Item No." = '' then
                    ErrTxt += 'Produktnr. fehlt. ';
                if TempLines."Asset Type" <> "Price Asset Type"::Item then
                    ErrTxt += StrSubstNo('Produkttyp "%1" wird im JSON nicht unterstuetzt (nur Artikel). ', TempLines."Asset Type");
                // Effective customerNo = line Source No. > header Source No.
                if (TempLines."Source Type" = "Price Source Type"::Customer)
                    and (TempLines."Source No." = '')
                    and (HeaderSourceNo = '')
                then
                    ErrTxt += 'Zuweisen zu Nr. (Debitorennr.) fehlt. ';
                if TempLines."Unit Price" = 0 then
                    ErrTxt += 'VK-Preis ist 0. ';
                if ErrTxt <> '' then begin
                    AllOk := false;
                    ErrLines.Init();
                    ErrLines."Line No." := TempLines."Line No.";
                    ErrLines."Validation Error" := CopyStr(ErrTxt, 1, 500);
                    ErrLines.Insert();
                end;
            until TempLines.Next() = 0;

        if not AllOk then begin
            CurrPage.LinesSubPage.Page.MarkLineErrors(ErrLines);
            SetHeaderError('Es gibt Fehler in den markierten Zeilen (orange). Bitte korrigieren und erneut pruefen.');
        end;

        exit(AllOk);
    end;

    /// <summary>
    /// Builds the JSON text from header fields and all subpage lines.
    /// customerNo per line = line Source No. if set, else header Source No.
    /// currency per line   = line Currency Code if set, else header Currency Code.
    /// </summary>
    local procedure BuildJsonText(): Text
    var
        TempLines: Record "PLI Test JSON Line Buffer" temporary;
        RootObj: JsonObject;
        MetaObj: JsonObject;
        PricesArr: JsonArray;
        LineObj: JsonObject;
        JsonText: Text;
        EffCustNo: Code[20];
        EffCurrency: Code[10];
    begin
        MetaObj.Add('version', '1.0');
        MetaObj.Add('type', ImportType);
        MetaObj.Add('mandant', CompanyName());
        MetaObj.Add('created', Format(Today(), 0, '<Year4>-<Month,2>-<Day,2>'));
        if HeaderValidFrom <> 0D then
            MetaObj.Add('validFrom', Format(HeaderValidFrom, 0, '<Year4>-<Month,2>-<Day,2>'))
        else
            MetaObj.Add('validFrom', '');
        if HeaderValidTo <> 0D then
            MetaObj.Add('validTo', Format(HeaderValidTo, 0, '<Year4>-<Month,2>-<Day,2>'))
        else
            MetaObj.Add('validTo', '');
        RootObj.Add('metadata', MetaObj);

        CurrPage.LinesSubPage.Page.GetTempTable(TempLines);
        if TempLines.FindSet() then
            repeat
                Clear(LineObj);
                // Skip non-Item lines — JSON format only supports itemNo
                if TempLines."Asset Type" <> "Price Asset Type"::Item then begin
                    LineObj.Add('_skipped', StrSubstNo('Line %1: Asset Type is not Item', TempLines."Line No."));
                    // Do not add to PricesArr — just continue
                end else begin
                    // Effective customerNo: line overrides header
                    if TempLines."Source No." <> '' then
                        EffCustNo := TempLines."Source No."
                    else
                        EffCustNo := HeaderSourceNo;
                    // Effective currency: line overrides header
                    if TempLines."Currency Code" <> '' then
                        EffCurrency := TempLines."Currency Code"
                    else
                        EffCurrency := HeaderCurrencyCode;

                    LineObj.Add('customerNo', EffCustNo);
                    LineObj.Add('itemNo', TempLines."Item No.");
                    LineObj.Add('unitOfMeasure', TempLines."Unit of Measure Code");
                    LineObj.Add('minimumQuantity', TempLines."Minimum Quantity");
                    LineObj.Add('unitPrice', TempLines."Unit Price");
                    LineObj.Add('currency', EffCurrency);
                    if TempLines."Starting Date" <> 0D then
                        LineObj.Add('startingDate', Format(TempLines."Starting Date", 0, '<Year4>-<Month,2>-<Day,2>'))
                    else
                        LineObj.Add('startingDate', '');
                    if TempLines."Ending Date" <> 0D then
                        LineObj.Add('endingDate', Format(TempLines."Ending Date", 0, '<Year4>-<Month,2>-<Day,2>'))
                    else
                        LineObj.Add('endingDate', '');
                    PricesArr.Add(LineObj);
                end;
            until TempLines.Next() = 0;

        RootObj.Add('prices', PricesArr);
        RootObj.WriteTo(JsonText);
        exit(JsonText);
    end;

    local procedure DownloadJsonFile()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        DlFileName: Text;
    begin
        if not ValidateBeforeExport() then begin
            CurrPage.Update(false);
            exit;
        end;
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText(BuildJsonText());
        TempBlob.CreateInStream(InStream);
        DlFileName := HeaderCode + '_' + Format(Today(), 0, '<Year4><Month,2><Day,2>') + '.json';
        DownloadFromStream(InStream, 'JSON herunterladen', '', 'JSON-Dateien (*.json)|*.json', DlFileName);
    end;

    local procedure DirectImportJson()
    var
        TempBlob: Codeunit "Temp Blob";
        PLIPriceListImport: Codeunit "PLI Price List Import";
        OutStream: OutStream;
    begin
        if not ValidateBeforeExport() then begin
            CurrPage.Update(false);
            exit;
        end;
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText(BuildJsonText());
        PLIPriceListImport.ImportFromBlob(
            TempBlob,
            HeaderCode + '.json',
            CompanyFilter,
            '',
            HeaderStatus = "Price Status"::Active);
        Message('Test-Import abgeschlossen. Ergebnis im Import-Log pruefen.');
    end;

    local procedure PopulateSampleData()
    var
        SampleLine: Record "PLI Test JSON Line Buffer" temporary;
    begin
        HeaderCode := CopyStr('TEST-' + Format(Today(), 0, '<Year4><Month,2><Day,2>'), 1, 20);
        HeaderDescription := 'Test-Import Standardpreise';
        HeaderSourceType := "Price Source Type"::Customer;
        HeaderSourceNo := 'D10001';
        HeaderCurrencyCode := 'EUR';
        HeaderValidFrom := Today();
        HeaderValidTo := CalcDate('<+1Y>', Today());
        HeaderStatus := "Price Status"::Active;
        SourceNoVisible := true;
        SourceNoMandatoryHdr := true;
        ClearHeaderError();
        PushHeaderDefaults();

        CurrPage.LinesSubPage.Page.ClearLines();

        SampleLine.Init();
        SampleLine."Line No." := 10000;
        SampleLine."Asset Type" := "Price Asset Type"::Item;
        SampleLine."Source Type" := "Price Source Type"::Customer;
        SampleLine."Source No." := 'D10001';
        SampleLine."Currency Code" := 'EUR';
        SampleLine."Starting Date" := Today();
        SampleLine."Ending Date" := CalcDate('<+1Y>', Today());
        SampleLine."Item No." := 'A-1000';
        SampleLine."Unit of Measure Code" := 'STK';
        SampleLine."Minimum Quantity" := 1;
        SampleLine."Unit Price" := 125.50;
        CurrPage.LinesSubPage.Page.AddLine(SampleLine);

        CurrPage.Update(false);
    end;
}
