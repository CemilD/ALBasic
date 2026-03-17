page 70100 "PLI Import Cockpit"
{
    Caption = 'Debitorenpreislisten Import';
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
            group(ImportSettings)
            {
                Caption = 'Import-Einstellungen';

                field(CompanyFilter; CompanyFilter)
                {
                    Caption = 'Mandant';
                    ApplicationArea = All;
                    ToolTip = 'Standard: aktueller Mandant. Leer lassen = Import in ALLE aktiven Mandanten. Mandant auswählen = nur dieser Mandant wird aktualisiert. Achtung: Leer = alle Mandanten!';

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
                field(FileName; FileName)
                {
                    Caption = 'Dateiname';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Name der ausgewählten JSON-Importdatei.';
                }
                field(PriceListCodeField; PriceListCode)
                {
                    Caption = 'Preislistencode';
                    ApplicationArea = All;
                    ToolTip = 'Optional: Vorhandene Preisliste gezielt befuellen. Leer lassen = Nummernserie aus Deb. Einrichtung wird gezogen, oder neue Preisliste je Debitor wird angelegt.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        PriceListHeader: Record "Price List Header";
                        PriceListHeaderList: Page "Sales Price Lists";
                    begin
                        PriceListHeader.SetRange("Price Type", PriceListHeader."Price Type"::Sale);
                        PriceListHeaderList.SetTableView(PriceListHeader);
                        PriceListHeaderList.LookupMode(true);
                        if PriceListHeaderList.RunModal() = Action::LookupOK then begin
                            PriceListHeaderList.GetRecord(PriceListHeader);
                            PriceListCode := PriceListHeader.Code;
                            Text := PriceListHeader.Code;
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
            }

            group(LastImportGroup)
            {
                Caption = 'Letzter Import';
                Editable = false;

                field(LastImportDate; LastImportDate)
                {
                    Caption = 'Datum/Uhrzeit';
                    ApplicationArea = All;
                }
                field(LastImportStatus; LastImportStatus)
                {
                    Caption = 'Status';
                    ApplicationArea = All;
                }
                field(LastImportLines; LastImportLines)
                {
                    Caption = 'Importierte Zeilen';
                    ApplicationArea = All;
                }
                field(LastImportErrors; LastImportErrors)
                {
                    Caption = 'Fehlerhafte Zeilen';
                    ApplicationArea = All;
                }
                field(LastImportTotalLines; LastImportTotalLines)
                {
                    Caption = 'Gesamtzeilen';
                    ApplicationArea = All;
                }
            }

            part(ErrorByCompany; "PLI Errors By Company Part")
            {
                ApplicationArea = All;
                Caption = 'Fehler pro Mandant';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SelectFile)
            {
                Caption = 'Datei auswählen';
                ApplicationArea = All;
                Image = Import;
                ToolTip = 'JSON-Preislistendatei auswählen und importieren.';

                trigger OnAction()
                begin
                    SelectAndImport();
                end;
            }
            action(ActivatePriceLists)
            {
                Caption = 'Preislisten aktivieren...';
                ApplicationArea = All;
                Image = Approve;
                RunObject = Page "PLI Activate Price List";
                ToolTip = 'Als Entwurf importierte Preislisten nach Pruefung auf Aktiv setzen. Nur aktivierte Listen wirken in Verkaufsbelegen.';
            }
            action(ViewLog)
            {
                Caption = 'Import-Log';
                ApplicationArea = All;
                Image = Report;
                RunObject = Page "PLI Import Log List";
                ToolTip = 'Alle bisherigen Importe und deren Status anzeigen.';
            }
            action(DownloadTemplate)
            {
                Caption = 'JSON-Vorlage herunterladen';
                ApplicationArea = All;
                Image = ExportFile;
                ToolTip = 'Eine Beispiel-JSON-Datei als Vorlage herunterladen.';

                trigger OnAction()
                begin
                    DownloadJsonTemplate();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        // Default to the currently active company; user can clear to import into all companies
        CompanyFilter := CopyStr(CompanyName(), 1, MaxStrLen(CompanyFilter));
        LoadLastImportInfo();
    end;

    var
        CompanyFilter: Text[30];
        FileName: Text[250];
        PriceListCode: Code[20];
        LastImportDate: DateTime;
        LastImportStatus: Enum "PLI Import Status";
        LastImportLines: Integer;
        LastImportErrors: Integer;
        LastImportTotalLines: Integer;
        UniqueCustomerCount: Integer;

    local procedure SelectAndImport()
    var
        TempBlob: Codeunit "Temp Blob";
        PLIPriceListImport: Codeunit "PLI Price List Import";
        PLIImportPreview: Page "PLI Import Preview";
        JsonInStream: InStream;
        UploadInStream: InStream;
        OutStream: OutStream;
        ImportedFileName: Text;
        JsonContent: Text;
        ImportType: Text[50];
        ValidFrom: Date;
        ValidTo: Date;
        LineCount: Integer;
    begin
        if not UploadIntoStream('JSON-Preislistendatei auswaehlen', '', 'JSON-Dateien (*.json)|*.json|Alle Dateien (*.*)|*.*', ImportedFileName, UploadInStream) then
            exit;

        if ImportedFileName = '' then
            exit;

        FileName := CopyStr(ImportedFileName, 1, 250);

        // Store in TempBlob so the stream can be reused
        TempBlob.CreateOutStream(OutStream);
        CopyStream(OutStream, UploadInStream);

        // Read JSON text for preview (TempBlob creates a fresh stream each time)
        TempBlob.CreateInStream(JsonInStream, TextEncoding::UTF8);
        JsonInStream.ReadText(JsonContent);

        // Parse metadata and show confirmation dialog
        PLIPriceListImport.GetPreviewData(JsonContent, ImportType, ValidFrom, ValidTo, LineCount, UniqueCustomerCount);
        // #7 Pass PriceListCode + UniqueCustomerCount so preview can show multi-customer warning
        PLIImportPreview.SetPreviewData(FileName, ImportType, LineCount, CompanyFilter, ValidFrom, ValidTo, PriceListCode, UniqueCustomerCount);
        PLIImportPreview.RunModal();
        if not PLIImportPreview.IsImportConfirmed() then
            exit;

        // Run actual import — always Draft, activation is a separate step
        PLIPriceListImport.ImportFromBlob(TempBlob, FileName, CompanyFilter, PriceListCode);

        LoadLastImportInfo();
        Message('Import abgeschlossen als Entwurf. Verwenden Sie "Preisliste aktivieren" um importierte Listen freizugeben.');
    end;

    local procedure LoadLastImportInfo()
    var
        ImportLog: Record "PLI Import Log";
    begin
        ImportLog.SetCurrentKey("Import DateTime");
        ImportLog.SetAscending("Import DateTime", false);
        if ImportLog.FindFirst() then begin
            LastImportDate := ImportLog."Import DateTime";
            LastImportStatus := ImportLog.Status;
            LastImportLines := ImportLog."Imported Lines";
            LastImportErrors := ImportLog."Error Lines";
            LastImportTotalLines := ImportLog."Total Lines";
        end else begin
            LastImportDate := 0DT;
            LastImportStatus := LastImportStatus::" ";
            LastImportLines := 0;
            LastImportErrors := 0;
            LastImportTotalLines := 0;
        end;
    end;

    local procedure DownloadJsonTemplate()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        Template: Text;
        TemplateFileName: Text;
    begin
        Template :=
            '{' +
            '  "metadata": {' +
            '    "version": "1.0",' +
            '    "type": "SalesPricelist",' +
            '    "mandant": "' + CompanyName() + '",' +
            '    "created": "' + Format(Today(), 0, '<Year4>-<Month,2>-<Day,2>') + '",' +
            '    "validFrom": "' + Format(Today(), 0, '<Year4>-<Month,2>-<Day,2>') + '",' +
            '    "validTo": "' + Format(CalcDate('<+1Y>', Today()), 0, '<Year4>-<Month,2>-<Day,2>') + '"' +
            '  },' +
            '  "priceListHeader": {' +
            '    "code": "S00001",' +
            '    "description": "Muster-Preisliste Import",' +
            '    "sourceType": "Customer",' +
            '    "sourceNo": "D10001",' +
            '    "currency": "EUR",' +
            '    "validFrom": "' + Format(Today(), 0, '<Year4>-<Month,2>-<Day,2>') + '",' +
            '    "validTo": "' + Format(CalcDate('<+1Y>', Today()), 0, '<Year4>-<Month,2>-<Day,2>') + '"' +
            '  },' +
            '  "prices": [' +
            '    {' +
            '      "customerNo": "D10001",' +
            '      "itemNo": "A-1000",' +
            '      "unitOfMeasure": "STK",' +
            '      "minimumQuantity": 1,' +
            '      "unitPrice": 125.50,' +
            '      "currency": "EUR",' +
            '      "startingDate": "' + Format(Today(), 0, '<Year4>-<Month,2>-<Day,2>') + '",' +
            '      "endingDate": "' + Format(CalcDate('<+1Y>', Today()), 0, '<Year4>-<Month,2>-<Day,2>') + '"' +
            '    }' +
            '  ]' +
            '}';

        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Template);
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        TemplateFileName := 'PriceList_Template.json';
        DownloadFromStream(InStream, 'Vorlage herunterladen', '', 'JSON-Dateien (*.json)|*.json', TemplateFileName);
    end;
}
