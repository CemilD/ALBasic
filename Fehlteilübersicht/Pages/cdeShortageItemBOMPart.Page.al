page 50008 cdeShortageItemBOMPart
{
    PageType = ListPart;
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
                // Rec.Level steuert die Einrücktiefe im Baum
                IndentationColumn = Rec.Level;
                // Description-Spalte erhält die Einrückung und das Aufklapp-Symbol
                IndentationControls = Description;
                ShowAsTree = true;

                field(ItemNo; Rec.ItemNo)
                {
                    ApplicationArea = All;
                    Caption = 'Artikelnr.';
                    ToolTip = 'Artikelnummer der Stücklistenkomponente. Klicken zum Öffnen der Stücklistenstruktur.';
                    StyleExpr = ItemStyle;

                    trigger OnDrillDown()
                    var
                        DrillItem: Record Item;
                        BOMBuffer: Record "BOM Buffer";
                    begin
                        // Stücklistenstruktur des angeklickten Artikels öffnen (wie in der Artikelkarte)
                        if not DrillItem.Get(Rec.ItemNo) then exit;
                        if DrillItem."Production BOM No." = '' then begin
                            Message('Für Artikel %1 - %2 ist keine Stücklistenstruktur vorhanden.', DrillItem."No.", DrillItem.Description);
                            exit;
                        end;
                        BOMBuffer.SetRange("No.", DrillItem."No.");
                        Page.Run(Page::"BOM Cost Shares", BOMBuffer);
                    end;
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
            }
        }
    }

    var
        // Fett = Artikel hat selbst eine Stückliste (Elternknoten), Standard = Blattknoten
        ItemStyle: Text;
        NextEntryNo: Integer;

    trigger OnAfterGetRecord()
    begin
        if Rec.HasBOM then
            ItemStyle := 'Strong'
        else
            ItemStyle := 'Standard';
    end;

    /// <summary>
    /// Wird von der Fehlteilübersicht aufgerufen wenn der Benutzer eine andere Zeile markiert.
    /// Lädt die Fertigungsstückliste des angegebenen Artikels rekursiv (alle Ebenen, max. 5).
    /// Artikel mit eigener Stückliste werden fett dargestellt und können im Baum aufgeklappt werden.
    /// </summary>
    procedure LoadBOM(pItemNo: Code[20])
    begin
        // Bestehende Einträge leeren
        Rec.Reset();
        Rec.DeleteAll();
        NextEntryNo := 0;

        // Ohne Artikel keine Stückliste anzeigen
        if pItemNo = '' then begin
            CurrPage.Update(false);
            exit;
        end;

        // Stücklistenbaum rekursiv aufbauen, Startebene 0, max. 5 Ebenen tief
        LoadBOMLevel(pItemNo, 0, 5);

        CurrPage.Update(false);
    end;

    /// <summary>
    /// Rekursive Hilfsprozedur: Lädt alle BOM-Komponenten von pItemNo auf Ebene pLevel.
    /// Falls eine Komponente selbst eine Stückliste hat, wird sie ebenfalls expandiert (Tiefensuche).
    /// Die Einfügereihenfolge (Tiefensuche) ergibt im Repeater automatisch die richtige Baumdarstellung.
    /// </summary>
    local procedure LoadBOMLevel(pItemNo: Code[20]; pLevel: Integer; pMaxLevel: Integer)
    var
        Item: Record Item;
        BOMLine: Record "Production BOM Line";
        SubItem: Record Item;
    begin
        if pLevel > pMaxLevel then
            exit;
        if pItemNo = '' then
            exit;

        // Artikel laden und Fertigungsstückliste prüfen
        if not Item.Get(pItemNo) then
            exit;
        if Item."Production BOM No." = '' then
            exit;

        // Alle Komponentenzeilen der Basisversion dieser Stückliste laden
        BOMLine.Reset();
        BOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        BOMLine.SetRange("Version Code", '');
        BOMLine.SetRange(Type, BOMLine.Type::Item);
        if not BOMLine.FindSet() then
            exit;

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

                // Prüfen ob diese Komponente selbst eine Fertigungsstückliste besitzt
                if SubItem.Get(BOMLine."No.") then
                    Rec.HasBOM := SubItem."Production BOM No." <> ''
                else
                    Rec.HasBOM := false;

                Rec.Insert();

                // Unterkomponenten direkt darunter einfügen (Tiefensuche → korrekte Baumreihenfolge)
                if Rec.HasBOM then
                    LoadBOMLevel(BOMLine."No.", pLevel + 1, pMaxLevel);
            end;
        until BOMLine.Next() = 0;
    end;
}
