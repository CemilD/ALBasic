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
                    ShowMandatory = true;
                    ToolTip = 'Beschreibung der Preisliste. Pflichtfeld - wird als Kopfbeschreibung in die Preisliste übernommen.';
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
                        SourceNoEditable := HeaderSourceType <> "Price Source Type"::"All Customers";
                        SourceNoMandatoryHdr := HeaderSourceType = "Price Source Type"::Customer;
                        if not SourceNoEditable then
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
                    Editable = SourceNoEditable;
                    ToolTip = 'Nummer des Datensatzes dem die Preisliste zugewiesen wird (Debitor, Debitorenpreisgruppe, Debitorenrabattgruppe oder Kampagne). Nicht editierbar fuer "Alle Debitoren".';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Customer: Record Customer;
                        CustomerList: Page "Customer List";
                        CustPriceGroup: Record "Customer Price Group";
                        CustPriceGroupList: Page "Customer Price Groups";
                        CustDiscGroup: Record "Customer Discount Group";
                        CustDiscGroupList: Page "Customer Disc. Groups";
                        Campaign: Record Campaign;
                        CampaignList: Page "Campaign List";
                    begin
                        case HeaderSourceType of
                            "Price Source Type"::Customer:
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
                                end;
                            "Price Source Type"::"Customer Price Group":
                                begin
                                    CustPriceGroupList.LookupMode(true);
                                    if CustPriceGroupList.RunModal() = Action::LookupOK then begin
                                        CustPriceGroupList.GetRecord(CustPriceGroup);
                                        HeaderSourceNo := CustPriceGroup.Code;
                                        Text := CustPriceGroup.Code;
                                        PushHeaderDefaults();
                                        exit(true);
                                    end;
                                end;
                            "Price Source Type"::"Customer Disc. Group":
                                begin
                                    CustDiscGroupList.LookupMode(true);
                                    if CustDiscGroupList.RunModal() = Action::LookupOK then begin
                                        CustDiscGroupList.GetRecord(CustDiscGroup);
                                        HeaderSourceNo := CustDiscGroup.Code;
                                        Text := CustDiscGroup.Code;
                                        PushHeaderDefaults();
                                        exit(true);
                                    end;
                                end;
                            "Price Source Type"::Campaign:
                                begin
                                    CampaignList.LookupMode(true);
                                    if CampaignList.RunModal() = Action::LookupOK then begin
                                        CampaignList.GetRecord(Campaign);
                                        HeaderSourceNo := Campaign."No.";
                                        Text := Campaign."No.";
                                        PushHeaderDefaults();
                                        exit(true);
                                    end;
                                end;
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
            // Block 2 – MwSt. (mirrors Sales Price List)
            // -------------------------------------------------------
            group(VATGroup)
            {
                Caption = 'MwSt.';

                field(VATBusPostingGroupField; HeaderVATBusPostingGroup)
                {
                    Caption = 'MwSt.-Geschäftsbuchungsgruppe (Preis)';
                    ApplicationArea = All;
                    TableRelation = "VAT Business Posting Group";
                    ToolTip = 'Gibt die MwSt.-Geschäftsbuchungsgruppe für die Preislistenkopfdaten an.';

                    trigger OnValidate()
                    begin
                        PushHeaderDefaults();
                        ClearHeaderError();
                    end;
                }
                field(PriceIncludesVATField; HeaderPriceIncludesVAT)
                {
                    Caption = 'Preis inkl. MwSt.';
                    ApplicationArea = All;
                    ToolTip = 'Gibt an, ob in den Preisen auf dieser Preisliste die Mehrwertsteuer enthalten ist.';

                    trigger OnValidate()
                    begin
                        PushHeaderDefaults();
                    end;
                }
            }

            // -------------------------------------------------------
            // Block 3 – Zeilenstandardwerte (mirrors Sales Price List)
            // -------------------------------------------------------
            group(LineDefaultsGroup)
            {
                Caption = 'Zeilenstandardwerte';

                field(AllowUpdatingDefaultsField; HeaderAllowUpdatingDefaults)
                {
                    Caption = 'Aktualisieren von Standardeinstellungen zulassen';
                    ApplicationArea = All;
                    ToolTip = 'Gibt an, ob die Standardwerte (Zeilenrabatt zulassen, Rechnungsrabatt zulassen) in den Zeilen dieser Preisliste geändert werden können.';

                    trigger OnValidate()
                    begin
                        PushHeaderDefaults();
                    end;
                }
                field(AllowInvoiceDiscField; HeaderAllowInvoiceDisc)
                {
                    Caption = 'Rech.-Rabatt zulassen';
                    ApplicationArea = All;
                    ToolTip = 'Gibt an, ob ein Rechnungsrabatt für Preise auf dieser Preisliste berechnet werden darf.';

                    trigger OnValidate()
                    begin
                        PushHeaderDefaults();
                    end;
                }
                field(AllowLineDiscField; HeaderAllowLineDisc)
                {
                    Caption = 'Zeilenrabatt zulassen';
                    ApplicationArea = All;
                    ToolTip = 'Gibt an, ob ein Zeilenrabatt für Preise auf dieser Preisliste berechnet werden darf.';

                    trigger OnValidate()
                    begin
                        PushHeaderDefaults();
                    end;
                }
            }

            // -------------------------------------------------------
            // Block 4 – Anzeigen (mirrors Sales Price List)
            // -------------------------------------------------------
            group(ShowGroup)
            {
                Caption = 'Anzeigen';

                field(AmountTypeField; HeaderAmountType)
                {
                    Caption = 'Spalten anzeigen für';
                    ApplicationArea = All;
                    ToolTip = 'Legt fest, ob die Preisliste Preise, Rabatte oder beides enthält.';
                }
            }

            // -------------------------------------------------------
            // Block 5 – inline error summary (hidden when no errors)
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
                field(ImportTypeField; ImportType)
                {
                    Caption = 'JSON-Typ (type)';
                    ApplicationArea = All;
                    ToolTip = 'Import-Typ im JSON-Metadaten-Block. Muss einem registrierten Importer entsprechen. Standard: SalesPricelist.';
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
            action(ActivatePriceLists)
            {
                Caption = 'Preislisten aktivieren...';
                ApplicationArea = All;
                Image = Approve;
                RunObject = Page "PLI Activate Price List";
                ToolTip = 'Als Entwurf importierte Preislisten nach Pruefung auf Aktiv setzen.';
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
        HeaderStatus := "Price Status"::Draft;
        HeaderSourceType := "Price Source Type"::Customer;
        SourceNoEditable := true;
        SourceNoMandatoryHdr := true;
        HeaderValidFrom := Today();
        HeaderAmountType := "Price Amount Type"::Price;
        HeaderErrorStyle := 'Attention';
        // Default to current company — mirrors cockpit behaviour
        CompanyFilter := CopyStr(CompanyName(), 1, MaxStrLen(CompanyFilter));
        // Push initial defaults so the first new line is pre-filled
        PushHeaderDefaults();
    end;

    var
        ImportType: Text[50];
        HeaderCode: Code[20];
        HeaderDescription: Text[100];
        HeaderSourceType: Enum "Price Source Type";
        HeaderSourceNo: Code[20];
        HeaderCurrencyCode: Code[10];
        HeaderValidFrom: Date;
        HeaderValidTo: Date;
        HeaderStatus: Enum "Price Status";
        HeaderVATBusPostingGroup: Code[20];
        HeaderPriceIncludesVAT: Boolean;
        HeaderAllowUpdatingDefaults: Boolean;
        HeaderAllowInvoiceDisc: Boolean;
        HeaderAllowLineDisc: Boolean;
        HeaderAmountType: Enum "Price Amount Type";
        CompanyFilter: Text[30];
        SourceNoEditable: Boolean;
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
            NewLine."Allow Line Disc." := HeaderAllowLineDisc;
            NewLine."Allow Invoice Disc." := HeaderAllowInvoiceDisc;
            NewLine."VAT Bus. Posting Group" := HeaderVATBusPostingGroup;
            NewLine."Price Includes VAT" := HeaderPriceIncludesVAT;
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
        CurrPage.LinesSubPage.Page.SetHeaderVATDefaults(
            HeaderVATBusPostingGroup, HeaderPriceIncludesVAT, HeaderAllowLineDisc, HeaderAllowInvoiceDisc);
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

        if HeaderDescription = '' then begin
            SetHeaderError('"Beschreibung" ist ein Pflichtfeld.');
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
        HeaderObj: JsonObject;
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

        // ── priceListHeader block ─────────────────────────────────────────────────
        // If a Code is set, the importer will auto-create this exact price list header.
        // If Code is empty, the importer will look up or create per-customer draft lists.
        HeaderObj.Add('code', HeaderCode);
        HeaderObj.Add('description', HeaderDescription);
        case HeaderSourceType of
            "Price Source Type"::Customer:
                HeaderObj.Add('sourceType', 'Customer');
            "Price Source Type"::"All Customers":
                HeaderObj.Add('sourceType', 'AllCustomers');
            "Price Source Type"::"Customer Price Group":
                HeaderObj.Add('sourceType', 'CustomerPriceGroup');
            "Price Source Type"::"Customer Disc. Group":
                HeaderObj.Add('sourceType', 'CustomerDiscGroup');
            else
                HeaderObj.Add('sourceType', '');
        end;
        HeaderObj.Add('sourceNo', HeaderSourceNo);
        HeaderObj.Add('currency', HeaderCurrencyCode);
        if HeaderValidFrom <> 0D then
            HeaderObj.Add('validFrom', Format(HeaderValidFrom, 0, '<Year4>-<Month,2>-<Day,2>'))
        else
            HeaderObj.Add('validFrom', '');
        if HeaderValidTo <> 0D then
            HeaderObj.Add('validTo', Format(HeaderValidTo, 0, '<Year4>-<Month,2>-<Day,2>'))
        else
            HeaderObj.Add('validTo', '');
        HeaderObj.Add('vatBusPostingGroup', HeaderVATBusPostingGroup);
        HeaderObj.Add('priceIncludesVat', HeaderPriceIncludesVAT);
        HeaderObj.Add('allowUpdatingDefaults', HeaderAllowUpdatingDefaults);
        HeaderObj.Add('allowInvoiceDisc', HeaderAllowInvoiceDisc);
        HeaderObj.Add('allowLineDisc', HeaderAllowLineDisc);
        HeaderObj.Add('amountType', Format(HeaderAmountType));
        RootObj.Add('priceListHeader', HeaderObj);

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
                    if TempLines."Work Type Code" <> '' then
                        LineObj.Add('workTypeCode', TempLines."Work Type Code")
                    else
                        LineObj.Add('workTypeCode', '');
                    LineObj.Add('allowLineDisc', TempLines."Allow Line Disc.");
                    LineObj.Add('lineDiscountPct', TempLines."Line Discount %");
                    LineObj.Add('allowInvoiceDisc', TempLines."Allow Invoice Disc.");
                    LineObj.Add('priceIncludesVat', TempLines."Price Includes VAT");
                    LineObj.Add('vatBusPostingGroup', TempLines."VAT Bus. Posting Group");
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
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildJsonText());
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
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
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildJsonText());
        PLIPriceListImport.ImportFromBlob(
            TempBlob,
            HeaderCode + '.json',
            CompanyFilter,
            ''); // Code is embedded in JSON priceListHeader — no separate override needed
        Message('Test-Import abgeschlossen als Entwurf. Verwenden Sie "Preisliste aktivieren" um das Ergebnis freizugeben.');
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
        SourceNoEditable := true;
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
        SampleLine."Allow Line Disc." := true;
        SampleLine."Allow Invoice Disc." := true;
        CurrPage.LinesSubPage.Page.AddLine(SampleLine);

        CurrPage.Update(false);
    end;
}
