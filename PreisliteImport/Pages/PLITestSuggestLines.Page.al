/// <summary>
/// "Zeilen vorschlagen" dialog for the PLI Test JSON Builder.
/// Mirrors the standard BC "Preiszeilen - Neue erstellen" dialog (Page 7021).
///
/// Usage:
///   SuggestPage.SetRecord(TempFilter);
///   SuggestPage.LookupMode(true);
///   if SuggestPage.RunModal() = Action::LookupOK then
///       SuggestPage.GetRecord(TempFilter);
/// </summary>
page 70107 "PLI Test Suggest Lines"
{
    Caption = 'Preiszeilen - Neue erstellen';
    PageType = StandardDialog;
    SourceTable = "PLI Test Suggest Filter";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            group(AssetGroup)
            {
                ShowCaption = false;

                field(AssetTypeField; AssetTypeTxt)
                {
                    Caption = 'Produkttyp';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Dieses Tool erstellt immer Zeilen fuer Artikel.';
                }
                field("Asset Filter"; Rec."Asset Filter")
                {
                    Caption = 'Produktfilter';
                    ApplicationArea = All;
                    ToolTip = 'Artikelfilter. Leer = alle Artikel. Beispiel: A-1000..A-2000 oder 10000|20000.';

                    trigger OnAssistEdit()
                    var
                        Item: Record Item;
                        ItemList: Page "Item List";
                    begin
                        ItemList.LookupMode(true);
                        if ItemList.RunModal() = Action::LookupOK then begin
                            ItemList.GetRecord(Item);
                            Rec."Asset Filter" := Item."No.";
                            Rec.Modify();
                        end;
                    end;
                }
            }

            group(OptionsGroup)
            {
                Caption = 'Optionen';

                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    Caption = 'Mindestmenge';
                    ApplicationArea = All;
                    ToolTip = '0 = keine Mengenstaffel. Wird als minimumQuantity in das JSON geschrieben.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    Caption = 'Startdatum';
                    ApplicationArea = All;
                    ToolTip = 'Startdatum fuer alle vorgeschlagenen Preiszeilen.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    Caption = 'Enddatum';
                    ApplicationArea = All;
                    ToolTip = 'Enddatum fuer alle vorgeschlagenen Preiszeilen. Leer = unbefristet.';
                }
                field("Adjustment Factor"; Rec."Adjustment Factor")
                {
                    Caption = 'Korrekturfaktor';
                    ApplicationArea = All;
                    ToolTip = 'Wird mit dem Artikellistenpreis multipliziert. 1 = unveraendert. 0,9 = 10 % Rabatt. 1,1 = 10 % Aufschlag.';
                }
                field("Rounding Precision"; Rec."Rounding Precision")
                {
                    Caption = 'Rundungsgenauigkeit';
                    ApplicationArea = All;
                    ToolTip = 'Nachkommastellen fuer die Rundung des berechneten Preises. 0,01 = centgenau. 0 = keine Rundung.';
                }
            }
        }
    }

    var
        AssetTypeTxt: Text[30];

    trigger OnOpenPage()
    begin
        AssetTypeTxt := 'Artikel';
        if not Rec.FindFirst() then begin
            Rec.Init();
            Rec."Entry No." := 1;
            Rec."Adjustment Factor" := 1;
            Rec."Rounding Precision" := 0.01;
            Rec.Insert();
        end;
    end;
}
