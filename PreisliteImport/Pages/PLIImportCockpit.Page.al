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
                    ToolTip = 'Leer lassen = alle Mandanten. Mandant auswählen = nur dieser Mandant wird aktualisiert.';

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
                            IsAllCompaniesStyle := 'None';
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
                field(AllCompaniesInfo; AllCompaniesInfoTxt)
                {
                    Caption = '';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = IsAllCompaniesStyle;
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
        CompanyFilter := '';
        AllCompaniesInfoTxt := 'Kein Mandant gewaehlt - Import in ALLE Mandanten';
        IsAllCompaniesStyle := 'Attention';
        LoadLastImportInfo();
    end;

    var
        CompanyFilter: Text[30];
        FileName: Text[250];
        AllCompaniesInfoTxt: Text;
        IsAllCompaniesStyle: Text;
        PriceListCode: Code[20];
        LastImportDate: DateTime;
        LastImportStatus: Enum "PLI Import Status";
        LastImportLines: Integer;
        LastImportErrors: Integer;
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
        TempBlob.CreateInStream(JsonInStream);
        JsonInStream.ReadText(JsonContent);

        // Parse metadata and show confirmation dialog
        PLIPriceListImport.GetPreviewData(JsonContent, ImportType, ValidFrom, ValidTo, LineCount, UniqueCustomerCount);
        // #7 Pass PriceListCode + UniqueCustomerCount so preview can show multi-customer warning
        PLIImportPreview.SetPreviewData(FileName, ImportType, LineCount, CompanyFilter, ValidFrom, ValidTo, PriceListCode, UniqueCustomerCount);
        PLIImportPreview.RunModal();
        if not PLIImportPreview.IsImportConfirmed() then
            exit;

        // #4 Draft mode: user chooses in preview dialog; InsertAsActive = not Draft
        // Run actual import (TempBlob stream is re-created internally)
        PLIPriceListImport.ImportFromBlob(TempBlob, FileName, CompanyFilter, PriceListCode, not PLIImportPreview.IsInsertAsDraft());

        LoadLastImportInfo();
        Message('Import abgeschlossen. Pruefen Sie den Import-Log fuer Details.');
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
        end else begin
            LastImportDate := 0DT;
            LastImportStatus := LastImportStatus::" ";
            LastImportLines := 0;
            LastImportErrors := 0;
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
            '    "mandant": "4101",' +
            '    "created": "' + Format(Today(), 0, '<Year4>-<Month,2>-<Day,2>') + '",' +
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

        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText(Template);
        TempBlob.CreateInStream(InStream);
        TemplateFileName := 'PriceList_Template.json';
        DownloadFromStream(InStream, 'Vorlage herunterladen', '', 'JSON-Dateien (*.json)|*.json', TemplateFileName);
    end;
}
