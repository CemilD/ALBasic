page 50010 cdeCrossCompanyPart
{
    PageType = ListPart;
    Caption = 'Mandantenbestand';
    // Wiederverwendet den Cross-Company Puffer aus der Bestandsübersicht
    SourceTable = pdeMD04CrossCompanyBuffer;
    SourceTableTemporary = true;
    Editable = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            // Jede Zeile = ein Mandant mit seinem Bestand für den markierten Artikel
            repeater(CrossCompanyLines)
            {
                field(CompanyName; Rec.CompanyName)
                {
                    ApplicationArea = All;
                    Caption = 'Mandant';
                    ToolTip = 'Name des Mandanten in diesem Business Central-System.';
                    StyleExpr = StockStyle;
                }
                field(Inventory; Rec.Inventory)
                {
                    ApplicationArea = All;
                    Caption = 'Bestand';
                    ToolTip = 'Aktueller Lagerbestand über alle Lagerorte beim jeweiligen Mandanten.';
                    StyleExpr = StockStyle;
                }
                field(UnitOfMeasure; Rec.UnitOfMeasure)
                {
                    ApplicationArea = All;
                    Caption = 'ME';
                    ToolTip = 'Basismengeneinheit des Artikels.';
                    StyleExpr = StockStyle;
                }
            }
        }
    }

    var
        StockStyle: Text;

    trigger OnAfterGetRecord()
    begin
        // Rot = kein Bestand, Grün = Bestand vorhanden
        if Rec.Inventory <= 0 then
            StockStyle := 'Unfavorable'
        else
            StockStyle := 'Favorable';
    end;

    /// <summary>
    /// Wird von cdeShortagePage aufgerufen wenn ein Artikel im Repeater markiert wird.
    /// Lädt den Bestand aus ALLEN Mandanten für diesen Artikel – unabhängig vom
    /// ManufacturingSetup-Flag "pdeCrossCompanyStockActive".
    /// </summary>
    procedure LoadCrossCompanyStock(pItemNo: Code[20])
    var
        Companies: Record Company;
        CrossItem: Record Item;
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if pItemNo = '' then begin
            CurrPage.Update(false);
            exit;
        end;

        // Alle Mandanten durchlaufen und Bestand direkt über ChangeCompany() abfragen
        if Companies.FindSet() then
            repeat
                CrossItem.ChangeCompany(Companies.Name);
                CrossItem.Reset();
                if CrossItem.Get(pItemNo) then begin
                    CrossItem.CalcFields(Inventory);
                    Rec.Init();
                    Rec.CompanyName := CopyStr(Companies.Name, 1, 30);
                    Rec.ItemNo := pItemNo;
                    Rec.LocationCode := '';
                    Rec.Inventory := CrossItem.Inventory;
                    Rec.UnitOfMeasure := CrossItem."Base Unit of Measure";
                    Rec.ItemDescription := CrossItem.Description;
                    Rec.Insert();
                end;
            until Companies.Next() = 0;

        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;
}
