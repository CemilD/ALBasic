page 50009 cdeShortageBOMPage
{
    PageType = List;
    Caption = 'Stücklistenstruktur';
    SourceTable = cdeShortageItemBOMBuffer;
    // Temporär: Daten werden nur im RAM gehalten, nie gespeichert
    SourceTableTemporary = true;
    Editable = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(BOMTree)
            {
                IndentationColumn = Rec.Level;
                IndentationControls = Description;
                ShowAsTree = true;

                field(ItemNo; Rec.ItemNo)
                {
                    ApplicationArea = All;
                    Caption = 'Artikelnr.';
                    ToolTip = 'Artikelnummer der Stücklistenkomponente';
                    StyleExpr = ItemStyle;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Beschreibung';
                    ToolTip = 'Bezeichnung der Komponente';
                    StyleExpr = ItemStyle;
                }
                field(QtyPerParent; Rec.QtyPerParent)
                {
                    ApplicationArea = All;
                    Caption = 'Menge je';
                    ToolTip = 'Menge dieser Komponente pro übergeordneter Einheit';
                    StyleExpr = ItemStyle;
                }
                field(UOM; Rec.UOM)
                {
                    ApplicationArea = All;
                    Caption = 'ME';
                    ToolTip = 'Mengeneinheit der Komponente';
                    StyleExpr = ItemStyle;
                }
                field(Level; Rec.Level)
                {
                    ApplicationArea = All;
                    Caption = 'Ebene';
                    ToolTip = 'Stücklistenebene (0 = direkter Bestandteil des markierten Artikels)';
                    Visible = false;
                }
                field(ParentItemNo; Rec.ParentItemNo)
                {
                    ApplicationArea = All;
                    Caption = 'Übergeord. Artikel';
                    ToolTip = 'Artikelnummer des übergeordneten Elements';
                    Visible = false;
                }
            }
        }
    }

    var
        ItemStyle: Text;
        NextEntryNo: Integer;
        // Wird via SetItemNo vor Page.Run() gesetzt
        ItemNoFilter: Code[20];

    trigger OnOpenPage()
    begin
        if ItemNoFilter <> '' then
            LoadBOM(ItemNoFilter);
    end;

    trigger OnAfterGetRecord()
    begin
        if Rec.HasBOM then
            ItemStyle := 'Strong'
        else
            ItemStyle := 'Standard';
    end;

    /// <summary>
    /// Muss vor Page.Run() aufgerufen werden damit die Stückliste des gewünschten Artikels geladen wird.
    /// </summary>
    procedure SetItemNo(pItemNo: Code[20])
    begin
        ItemNoFilter := pItemNo;
    end;

    local procedure LoadBOM(pItemNo: Code[20])
    begin
        Rec.Reset();
        Rec.DeleteAll();
        NextEntryNo := 0;

        if pItemNo = '' then exit;

        LoadBOMLevel(pItemNo, 0, 5);
        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Rekursive Tiefensuche: Lädt alle Komponenten von pItemNo auf Ebene pLevel.
    /// Die Einfügereihenfolge (Tiefensuche) ergibt im Repeater automatisch die korrekte Baumdarstellung.
    /// </summary>
    local procedure LoadBOMLevel(pItemNo: Code[20]; pLevel: Integer; pMaxLevel: Integer)
    var
        Item: Record Item;
        BOMLine: Record "Production BOM Line";
        SubItem: Record Item;
    begin
        if pLevel > pMaxLevel then exit;
        if pItemNo = '' then exit;

        if not Item.Get(pItemNo) then exit;
        if Item."Production BOM No." = '' then exit;

        BOMLine.Reset();
        BOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        BOMLine.SetRange("Version Code", '');
        BOMLine.SetRange(Type, BOMLine.Type::Item);
        if not BOMLine.FindSet() then exit;

        repeat
            if BOMLine."No." <> '' then begin
                NextEntryNo += 1;

                Rec.Init();
                Rec.EntryNo := NextEntryNo;
                Rec.Level := pLevel;
                Rec.ParentItemNo := pItemNo;
                Rec.ItemNo := BOMLine."No.";
                Rec.Description := BOMLine.Description;
                Rec.QtyPerParent := BOMLine."Quantity per";
                Rec.UOM := BOMLine."Unit of Measure Code";

                if SubItem.Get(BOMLine."No.") then
                    Rec.HasBOM := SubItem."Production BOM No." <> ''
                else
                    Rec.HasBOM := false;

                Rec.Insert();

                if Rec.HasBOM then
                    LoadBOMLevel(BOMLine."No.", pLevel + 1, pMaxLevel);
            end;
        until BOMLine.Next() = 0;
    end;
}
