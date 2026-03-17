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
                }
                field(ValidToField; ValidToVal)
                {
                    Caption = 'Gültig bis';
                    ApplicationArea = All;
                    Editable = false;
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
        WarningTxt: Text;
        WarningStyle: Text;
        ImportConfirmed: Boolean;

    /// <summary>
    /// Must be called before RunModal() to populate the dialog fields.
    /// </summary>
    procedure SetPreviewData(FileName: Text[250]; ImportType: Text[50]; LineCount: Integer; CompanyFilter: Text[30]; ValidFrom: Date; ValidTo: Date)
    begin
        FileNameVal := FileName;
        ImportTypeVal := ImportType;
        LineCountVal := LineCount;
        ValidFromVal := ValidFrom;
        ValidToVal := ValidTo;
        if CompanyFilter = '' then begin
            CompanyFilterVal := '(Alle Mandanten)';
            WarningTxt := 'Achtung: Es ist kein Mandant ausgewählt. Der Import wird in ALLE aktiven Mandanten durchgeführt!';
            WarningStyle := 'Attention';
        end else begin
            CompanyFilterVal := CompanyFilter;
            WarningTxt := '';
            WarningStyle := 'None';
        end;
    end;

    /// <summary>
    /// Returns true only if the user clicked "Jetzt importieren".
    /// Must be checked after RunModal() returns.
    /// </summary>
    procedure IsImportConfirmed(): Boolean
    begin
        exit(ImportConfirmed);
    end;
}
