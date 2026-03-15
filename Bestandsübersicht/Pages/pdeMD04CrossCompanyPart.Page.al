page 50007 pdeMD04CrossCompanyPart
{
    PageType = ListPart;
    Caption = 'Cross-Company Stock';
    SourceTable = pdeMD04CrossCompanyBuffer;
    // Temporär: Daten nur im RAM, nie gespeichert
    SourceTableTemporary = true;
    Editable = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            // Jede Zeile = ein Mandant mit seinem Bestand für diesen Artikel
            repeater(CrossCompanyLines)
            {
                field(CompanyName; Rec.CompanyName)
                {
                    ApplicationArea = All;
                    Caption = 'Company (Mandant)';
                    ToolTip = 'Name des Mandanten in diesem BC-System.';
                    // Einfärben: unter Meldebestand = rot, sonst neutral
                    StyleExpr = StockStyle;
                }
                field(ItemDescription; Rec.ItemDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Artikelbezeichnung beim jeweiligen Mandanten.';
                    StyleExpr = StockStyle;
                }
                field(Inventory; Rec.Inventory)
                {
                    ApplicationArea = All;
                    Caption = 'Inventory';
                    ToolTip = 'Aktueller Lagerbestand über alle Lagerorte beim Mandanten.';
                    StyleExpr = StockStyle;
                }
                field(UnitOfMeasure; Rec.UnitOfMeasure)
                {
                    ApplicationArea = All;
                    Caption = 'UoM';
                    ToolTip = 'Basismengeneinheit des Artikels beim jeweiligen Mandanten.';
                    StyleExpr = StockStyle;
                }
                field(ReorderPoint; Rec.ReorderPoint)
                {
                    ApplicationArea = All;
                    Caption = 'Reorder Point';
                    ToolTip = 'Meldebestand – sobald der Bestand darunter fällt, ist eine Bestellung empfohlen.';
                    StyleExpr = StockStyle;
                }
            }
        }
    }

    var
        // Zeilenstil: gesetzt pro Datensatz in OnAfterGetRecord
        StockStyle: Text;

    trigger OnAfterGetRecord()
    begin
        // Rot = Bestand unter Meldebestand (Nachbestellung empfohlen)
        // Gelb = Bestand = 0 aber kein Meldebestand gesetzt
        // Grün = Bestand über Meldebestand
        if Rec.Inventory <= 0 then
            StockStyle := 'Unfavorable'
        else
            if (Rec.ReorderPoint > 0) and (Rec.Inventory < Rec.ReorderPoint) then
                StockStyle := 'Attention'
            else
                StockStyle := 'Favorable';
    end;

    /// <summary>
    /// Wird von der Workspace-Page aufgerufen wenn ein Artikel gewählt wird.
    /// Liest den Bestand aus allen Mandanten und zeigt das Ergebnis an.
    /// </summary>
    procedure LoadCrossCompanyStock(pItemNo: Code[20])
    var
        Mgt: Codeunit pdeMD04Mgt;
    begin
        // Codeunit übernimmt das Durchlaufen aller Mandanten via ChangeCompany()
        Mgt.LoadCrossCompanyStock(pItemNo, Rec);

        // Cursor auf erste Zeile setzen
        if Rec.FindFirst() then;

        // FactBox-Anzeige aktualisieren
        CurrPage.Update(false);
    end;
}
