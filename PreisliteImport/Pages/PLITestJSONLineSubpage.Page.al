/// <summary>
/// Editable list part for the PLI Test JSON Builder.
/// Mirrors the "Zeilen" repeater of the standard Sales Price List (Page 7016):
///   - Same columns in the same order (Source Type, Source No., Currency, Dates,
///     Asset Type [readonly=Artikel], Item No., Description, Variant, UoM, MinQty, Price)
///   - ShowMandatory on Item No. (always) and Source No. (when Source Type = Customer)
///   - StyleExpr highlights the entire row when a validation error is present
///   - Last column shows the error text with Attention style
///   - OnNewRecord inherits header defaults (source, currency, dates)
/// SetHeaderDefaults() MUST be called by the parent page whenever a header field changes.
/// </summary>
page 70106 "PLI Test JSON Line Subpage"
{
    PageType = ListPart;
    SourceTable = "PLI Test JSON Line Buffer";
    SourceTableTemporary = true;
    Caption = 'Zeilen';
    AutoSplitKey = true;
    DelayedInsert = true;
    InsertAllowed = true;
    DeleteAllowed = true;
    ModifyAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    Caption = 'Zuweisen zu Typ';
                    StyleExpr = RowStyle;
                    ToolTip = 'Preisquellentyp dieser Zeile. "Debitor" = Pflichtfeld Zuweisen zu Nr. "Alle Debitoren" = gilt fuer alle Kunden.';

                    trigger OnValidate()
                    begin
                        // Compute fresh ShowMandatory / style when type changes
                        SourceNoMandatory := Rec."Source Type" = "Price Source Type"::Customer;
                        ClearLineError();
                    end;
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = All;
                    Caption = 'Zuweisen zu Nr.';
                    ShowMandatory = SourceNoMandatory;
                    StyleExpr = RowStyle;
                    ToolTip = 'Debitorennummer (customerNo im JSON). Pflichtfeld wenn Zuweisen zu Typ = Debitor.';

                    trigger OnValidate()
                    begin
                        ClearLineError();
                    end;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Caption = 'Waehrungscode';
                    StyleExpr = RowStyle;
                    ToolTip = 'Waehrungscode (currency im JSON). Leer = Mandantenwaehrung.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Startdatum';
                    StyleExpr = RowStyle;
                    ToolTip = 'Startdatum (startingDate im JSON, Format YYYY-MM-DD).';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    Caption = 'Enddatum';
                    StyleExpr = RowStyle;
                    ToolTip = 'Enddatum (endingDate im JSON). Leer = unbefristet gueltig, kein endingDate-Feld.';
                }
                field("Asset Type"; Rec."Asset Type")
                {
                    ApplicationArea = All;
                    Caption = 'Produkttyp';
                    StyleExpr = RowStyle;
                    ToolTip = 'Produkttyp dieser Preiszeile. Hinweis: Der JSON-Import unterstuetzt ausschliesslich "Artikel". Zeilen mit anderen Typen werden beim Export uebersprungen und als Fehler markiert.';

                    trigger OnValidate()
                    begin
                        SourceNoMandatory := Rec."Source Type" = "Price Source Type"::Customer;
                        ClearLineError();
                    end;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Caption = 'Produktnr.';
                    ShowMandatory = true;
                    StyleExpr = RowStyle;
                    ToolTip = 'Artikelnummer (itemNo im JSON). Pflichtfeld.';

                    trigger OnValidate()
                    begin
                        ClearLineError();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Beschreibung';
                    Editable = false;
                    StyleExpr = RowStyle;
                    ToolTip = 'Wird automatisch aus dem Artikelstamm befuellt wenn Produktnr. eingetragen wird.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Caption = 'Variantencode';
                    StyleExpr = RowStyle;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Caption = 'Einheit';
                    StyleExpr = RowStyle;
                    ToolTip = 'Einheitencode (unitOfMeasure im JSON), z.B. STK.';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Mindestmenge';
                    StyleExpr = RowStyle;
                    ToolTip = 'Mindestmenge (minimumQuantity im JSON). 0 = keine Mengenstaffel.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    Caption = 'VK-Preis';
                    ShowMandatory = true;
                    StyleExpr = RowStyle;
                    ToolTip = 'Netto-Verkaufspreis (unitPrice im JSON). Pflichtfeld.';

                    trigger OnValidate()
                    begin
                        ClearLineError();
                    end;
                }
                field("Validation Error"; Rec."Validation Error")
                {
                    ApplicationArea = All;
                    Caption = 'Fehler';
                    Editable = false;
                    StyleExpr = ErrorColStyle;
                    ToolTip = 'Validierungsfehler fuer diese Zeile. Wird von "Zeilen pruefen" befuellt. Verschwindet sobald Sie die fehlerhaften Felder korrigieren.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SourceNoMandatory := Rec."Source Type" = "Price Source Type"::Customer;
        if Rec."Validation Error" <> '' then begin
            RowStyle := 'Attention';
            ErrorColStyle := 'Attention';
        end else begin
            RowStyle := 'Standard';
            ErrorColStyle := 'None';
        end;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        // Inherit header-level defaults so each new line is pre-filled
        Rec."Asset Type" := "Price Asset Type"::Item;
        Rec."Source Type" := DefSourceType;
        Rec."Source No." := DefSourceNo;
        Rec."Currency Code" := DefCurrencyCode;
        Rec."Starting Date" := DefValidFrom;
        Rec."Ending Date" := DefValidTo;
        Rec."Minimum Quantity" := 1;
        SourceNoMandatory := Rec."Source Type" = "Price Source Type"::Customer;
    end;

    var
        RowStyle: Text;
        ErrorColStyle: Text;
        SourceNoMandatory: Boolean;
        DefSourceType: Enum "Price Source Type";
        DefSourceNo: Code[20];
        DefCurrencyCode: Code[10];
        DefValidFrom: Date;
        DefValidTo: Date;

    local procedure ClearLineError()
    begin
        if Rec."Validation Error" = '' then
            exit;
        Rec."Validation Error" := '';
        Rec.Modify();
        RowStyle := 'Standard';
        ErrorColStyle := 'None';
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Called by the parent page whenever a header field (Source Type, Source No.,
    /// Currency Code, ValidFrom, ValidTo) changes. New lines inherit these defaults.
    /// </summary>
    procedure SetHeaderDefaults(SourceType: Enum "Price Source Type"; SourceNo: Code[20]; CurrencyCode: Code[10]; ValidFrom: Date; ValidTo: Date)
    begin
        DefSourceType := SourceType;
        DefSourceNo := SourceNo;
        DefCurrencyCode := CurrencyCode;
        DefValidFrom := ValidFrom;
        DefValidTo := ValidTo;
    end;

    /// <summary>Copies all current line records into the caller's temporary variable.</summary>
    procedure GetTempTable(var TempLineBuffer: Record "PLI Test JSON Line Buffer" temporary)
    begin
        TempLineBuffer.Copy(Rec, true);
    end;

    /// <summary>
    /// Writes validation errors back onto the corresponding line records
    /// and triggers a page refresh so the colored rows are visible immediately.
    /// </summary>
    procedure MarkLineErrors(var ErrorLines: Record "PLI Test JSON Line Buffer" temporary)
    begin
        if not ErrorLines.FindSet() then
            exit;
        repeat
            if Rec.Get(ErrorLines."Line No.") then begin
                Rec."Validation Error" := ErrorLines."Validation Error";
                Rec.Modify();
            end;
        until ErrorLines.Next() = 0;
        CurrPage.Update(false);
    end;

    procedure ClearLines()
    begin
        Rec.DeleteAll();
        CurrPage.Update(false);
    end;

    procedure AddLine(var NewLine: Record "PLI Test JSON Line Buffer" temporary)
    begin
        Rec.TransferFields(NewLine);
        if Rec.Insert() then;
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Returns the next available Line No. for inserting new lines.
    /// Returns 10000 when the subpage is empty.
    /// </summary>
    procedure GetNextLineNo(): Integer
    begin
        if Rec.FindLast() then
            exit(Rec."Line No." + 10000);
        exit(10000);
    end;
}
