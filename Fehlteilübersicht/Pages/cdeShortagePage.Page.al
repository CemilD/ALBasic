page 50002 cdeShortagePage
{
    Caption = 'CDE Fehlteilübersicht';
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Tasks;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    AboutTitle = 'CDE Shortage List';
    AboutText = 'Use this page to review the list of items with shortages for a specific production order. The list is based on the current inventory and the demand from the production order.';
    SourceTable = "cdeShortageListTableBuffer";
    // SourceTableTemporary = true → Daten werden nur im RAM gehalten, nie gespeichert
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Filter';

                field(ProdOrderFilter; ProdOrderFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Fertigungsauftrag Filter';
                    ToolTip = 'Wählen Sie einen oder mehrere freigegebene Fertigungsaufträge aus.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ProdOrder: Record "Production Order";
                        FirstProdOrder: Record "Production Order";
                        ProdOrderList: Page "Production Order List";
                        cdeFilterMgt: Codeunit cdeSelectionFilterMgt;
                        FirstNo: Text;
                    begin
                        ProdOrder.Reset();
                        ProdOrder.SetRange(Status, ProdOrder.Status::Released);
                        Clear(ProdOrderList);

                        ProdOrderList.SetTableView(ProdOrder);
                        ProdOrderList.LookupMode(true);

                        // Wenn bereits ein Filter gesetzt ist, Cursor auf ersten vorher
                        // gewählten FA positionieren, damit der Benutzer die Auswahl nur anpassen muss
                        if ProdOrderFilter <> '' then begin
                            FirstNo := cdeFilterMgt.GetFirstValueFromFilter(ProdOrderFilter);
                            if FirstProdOrder.Get(FirstProdOrder.Status::Released, FirstNo) then
                                ProdOrderList.SetRecord(FirstProdOrder);
                        end;

                        if ProdOrderList.RunModal() = ACTION::LookupOK then begin
                            ProdOrderList.SetSelectionFilter(ProdOrder);
                            // Eigene Funktion verwenden um exakten | -Filter zu erzeugen (kein ..-Bereich)
                            ProdOrderFilter := cdeFilterMgt.GetExactFilterFromRecord(ProdOrder);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        // Wenn Filter geleert wird, auch die Tabelle leeren
                        if ProdOrderFilter = '' then
                            LoadData();
                    end;
                }
            }

            // Repeater zeigt alle Fehlteile der gewählten FAs
            repeater(ShortageLines)
            {
                field(ProdOrderNo; Rec.ProdOrderNo)
                {
                    ApplicationArea = All;
                    Caption = 'FA-Nr.';
                    ToolTip = 'Nummer des Fertigungsauftrags';
                    // StyleExpr färbt die Zeile je nach Verfügbarkeit
                    StyleExpr = RowStyle;
                }
                field(ItemNo; Rec.ItemNo)
                {
                    ApplicationArea = All;
                    Caption = 'Material';
                    ToolTip = 'Artikelnummer des fehlenden Bauteils';
                    StyleExpr = RowStyle;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Materialkurztext';
                    ToolTip = 'Beschreibung des Artikels';
                    StyleExpr = RowStyle;
                }
                field(DueDate; Rec.DueDate)
                {
                    ApplicationArea = All;
                    Caption = 'Bedarfstermin';
                    ToolTip = 'Datum, an dem der Artikel für die Produktion benötigt wird';
                    StyleExpr = RowStyle;
                }
                field(RequiredQty; Rec.RequiredQty)
                {
                    ApplicationArea = All;
                    Caption = 'Bedarfsmenge';
                    ToolTip = 'Verbleibende benötigte Menge für diesen Fertigungsauftrag';
                    StyleExpr = RowStyle;
                }
                field(UnitOfMeasure; Rec.UnitOfMeasure)
                {
                    ApplicationArea = All;
                    Caption = 'ME';
                    ToolTip = 'Mengeneinheit der Bedarfsmenge';
                    StyleExpr = RowStyle;
                }
                field(OperationNo; Rec.OperationNo)
                {
                    ApplicationArea = All;
                    Caption = 'Vorgang';
                    ToolTip = 'Vorgangsnummer des zugehörigen Arbeitsgangs';
                    StyleExpr = RowStyle;
                }
                field(LocationCode; Rec.LocationCode)
                {
                    ApplicationArea = All;
                    Caption = 'Lagerort';
                    ToolTip = 'Lagerort, an dem der Artikel benötigt wird';
                    StyleExpr = RowStyle;
                }
                field(AvailableQty; Rec.AvailableQty)
                {
                    ApplicationArea = All;
                    Caption = 'Bestätigte Menge';
                    ToolTip = 'Aktuell verfügbarer Bestand am Lagerort zum Bedarfstermin';
                    StyleExpr = RowStyle;
                }
            }
        }

        // Zeitschiene rechts: zeigt 6 Wochenblöcke für den aktuell selektierten Artikel
        area(FactBoxes)
        {
            part(cdeTimelinePart; cdeShortageTimelinePart)
            {
                ApplicationArea = All;
                Caption = 'Zeitschiene';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(LoadShortages)
            {
                ApplicationArea = All;
                Caption = 'Fehlteile laden';
                ToolTip = 'Lädt alle Fehlteile für die ausgewählten Fertigungsaufträge';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    LoadData();
                end;
            }
        }
    }

    var
        ProdOrderFilter: Text;
        VariantFilter: Text;
        // RowStyle wird pro Zeile in OnAfterGetRecord gesetzt
        RowStyle: Text;

    trigger OnAfterGetRecord()
    var
        ProdOrder: Record "Production Order";
        StartingDate: Date;
    begin
        // Rot = kein Bestand vorhanden, Gelb = Teilbestand vorhanden
        if Rec.AvailableQty <= 0 then
            RowStyle := 'Unfavorable'
        else
            RowStyle := 'Attention';

        // FA-Startdatum für die Zeitschiene ermitteln
        // Gesucht wird der früheste FA aus dem Filter für den aktuellen Artikel
        if ProdOrder.Get(ProdOrder.Status::Released, Rec.ProdOrderNo) then
            StartingDate := ProdOrder."Starting Date"
        else
            StartingDate := Today();

        // Zeitschiene rechts für den aktuell selektierten Artikel neu laden
        // Referenzpunkt = FA-Arbeitsbeginn, Anzahl Wochen aus Produktionseinrichtung
        CurrPage.cdeTimelinePart.Page.LoadTimeline(Rec.ItemNo, Rec.LocationCode, ProdOrderFilter, StartingDate);
    end;

    local procedure LoadData()
    var
        cdeShortageListMgt: Codeunit cdeShortageListMgt;
    begin
        // Fehlteile in den temporären Source-Table-Puffer laden
        cdeShortageListMgt.LoadShortages(ProdOrderFilter, Rec);

        // Cursor auf ersten Datensatz setzen
        if Rec.FindFirst() then;

        // Seite neu zeichnen ohne Datensatz zu speichern
        CurrPage.Update(false);
    end;
}

