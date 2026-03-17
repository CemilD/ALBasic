/// <summary>
/// Modal confirmation dialog shown before any import is executed.
/// Displays parsed JSON metadata so the user can verify the file content
/// before any data is written to the database.
///
/// Usage (from caller):
///   PLIImportPreview.SetPreviewData(FileName, ImportType, LineCount, CompanyFilter, ValidFrom, ValidTo);
///   PLIImportPreview.RunModal();
///   if PLIImportPreview.IsImportConfirmed() then ...;
/// </summary>
page 70104 "PLI Import Preview"
{
    Caption = 'Importvorschau';
    PageType = Card;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    LinksAllowed = false;

    layout
    {
        area(Content)
        {
            group(FileInfoGroup)
            {
                Caption = 'Dateiinformationen';

                field(FileNameField; FileNameVal)
                {
                    Caption = 'Dateiname';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Name der ausgewählten JSON-Datei.';
                }
                field(ImportTypeField; ImportTypeVal)
                {
                    Caption = 'Importtyp';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Wert aus dem JSON-Metadatenfeld "type".';
                }
                field(LineCountField; LineCountVal)
                {
                    Caption = 'Anzahl Preiszeilen';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Anzahl der Einträge im "prices"-Array der JSON-Datei.';
                }
            }

            group(ValidityGroup)
            {
                Caption = 'Gültigkeit laut Metadaten';

                field(ValidFromField; ValidFromVal)
                {
                    Caption = 'Gültig von';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Startdatum aus dem JSON-Metadatenfeld "validFrom".';
                }
                field(ValidToField; ValidToVal)
                {
                    Caption = 'Gültig bis';
                    ApplicationArea = All;
                    Editable = false;
                    // #6 Explain 0D = unbefristet to the user
                    ToolTip = 'Enddatum aus dem JSON-Metadatenfeld "validTo". Ist das Enddatum leer, gilt der Preis unbefristet und läuft nie automatisch ab.';
                }
            }

            group(TargetGroup)
            {
                Caption = 'Import-Ziel';

                field(CompanyFilterField; CompanyFilterVal)
                {
                    Caption = 'Ziel-Mandant';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Mandant, in den die Preisliste importiert wird.';
                }
                field(InsertAsDraftField; InsertAsDraftVal)
                {
                    Caption = 'Als Entwurf importieren';
                    ApplicationArea = All;
                    ToolTip = 'Aktiviert: Neue Preislisten und -zeilen werden als Entwurf angelegt und müssen manuell freigegeben werden, bevor sie in Belegen wirken. Deaktiviert (Standard): Direkt aktiv — wirkt sofort im nächsten Verkaufsbeleg.';
                }
                field(WarningField; WarningTxt)
                {
                    Caption = '';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = WarningStyle;
                    MultiLine = true;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(StartImport)
            {
                Caption = 'Jetzt importieren';
                ApplicationArea = All;
                Image = Import;
                ToolTip = 'Import mit den angezeigten Einstellungen starten.';

                trigger OnAction()
                begin
                    ImportConfirmed := true;
                    CurrPage.Close();
                end;
            }
            action(CancelImport)
            {
                Caption = 'Abbrechen';
                ApplicationArea = All;
                Image = Cancel;
                ToolTip = 'Import abbrechen. Es werden keine Daten geändert.';

                trigger OnAction()
                begin
                    ImportConfirmed := false;
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        FileNameVal: Text[250];
        ImportTypeVal: Text[50];
        LineCountVal: Integer;
        ValidFromVal: Date;
        ValidToVal: Date;
        CompanyFilterVal: Text[30];
        InsertAsDraftVal: Boolean;
        WarningTxt: Text;
        WarningStyle: Text;
        ImportConfirmed: Boolean;

    /// <summary>
    /// Must be called before RunModal() to populate the dialog fields.
    /// </summary>
    /// <param name="PriceListCode">Override code entered in the cockpit. Empty = auto-assign per customer.</param>
    /// <param name="UniqueCustomerCount">Number of distinct customerNo values in the JSON prices array.
    /// When more than 1 and PriceListCode is set, a multi-customer warning is shown.</param>
    procedure SetPreviewData(FileName: Text[250]; ImportType: Text[50]; LineCount: Integer; CompanyFilter: Text[30]; ValidFrom: Date; ValidTo: Date; PriceListCode: Code[20]; UniqueCustomerCount: Integer)
    var
        WarningLines: List of [Text];
        WarningLine: Text;
    begin
        FileNameVal := FileName;
        ImportTypeVal := ImportType;
        LineCountVal := LineCount;
        ValidFromVal := ValidFrom;
        ValidToVal := ValidTo;
        InsertAsDraftVal := false; // default: direct active

        if CompanyFilter = '' then begin
            CompanyFilterVal := '(Alle Mandanten)';
            WarningLines.Add('Achtung: Kein Mandant ausgewaehlt. Import in ALLE aktiven Mandanten!');
        end else
            CompanyFilterVal := CompanyFilter;

        // #7 Warn if a single override code is used for multiple customers
        if (PriceListCode <> '') and (UniqueCustomerCount > 1) then
            WarningLines.Add(StrSubstNo(
                'Hinweis: Preislistencode "%1" wird fuer %2 verschiedene Debitoren verwendet. Alle Zeilen landen in dieser einen Liste.',
                PriceListCode, UniqueCustomerCount));

        // #5 Best-price info always shown
        WarningLines.Add('Info: BC verwendet immer den guenstigsten Preis (Best-Price-Prinzip). Ein importierter Preis kann durch eine andere guenstigere Preisliste uebersteuert werden.');

        foreach WarningLine in WarningLines do
            if WarningTxt = '' then
                WarningTxt := WarningLine
            else
                WarningTxt := WarningTxt + ' | ' + WarningLine;

        if WarningLines.Count > 1 then
            WarningStyle := 'Attention'
        else
            WarningStyle := 'None';
    end;

    /// <summary>
    /// Returns true only if the user clicked "Jetzt importieren".
    /// Must be checked after RunModal() returns.
    /// </summary>
    procedure IsImportConfirmed(): Boolean
    begin
        exit(ImportConfirmed);
    end;

    /// <summary>
    /// Returns false = insert as Active (default), true = insert as Draft.
    /// Must be checked after RunModal() returns.
    /// </summary>
    procedure IsInsertAsDraft(): Boolean
    begin
        exit(InsertAsDraftVal);
    end;
}
