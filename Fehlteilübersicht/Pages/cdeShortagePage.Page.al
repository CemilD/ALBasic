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

                field(CompanyFilterField; CompanyFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Mandant';
                    ToolTip = 'Mandant, dessen Fehlteile angezeigt werden sollen. Vorbelegt mit dem aktuellen Mandanten.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Company: Record Company;
                    begin
                        // Page::Companies = Standard-Mandantenliste (ID 357)
                        if Page.RunModal(Page::Companies, Company) = ACTION::LookupOK then begin
                            CompanyFilter := Company.Name;
                            Text := CompanyFilter;
                            // FA-Filter zurücksetzen – FAs sind mandantenspezifisch
                            ProdOrderFilter := '';
                            // OnLookup löst kein OnValidate aus → LoadData() hier explizit aufrufen
                            LoadData();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        // Bei Mandantenwechsel FA-Filter leeren und Daten neu laden
                        ProdOrderFilter := '';
                        LoadData();
                    end;
                }

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
                        TargetCompany: Text[30];
                    begin
                        // Ziel-Mandant bestimmen: gewählter Mandant oder aktueller
                        if CompanyFilter <> '' then
                            TargetCompany := CompanyFilter
                        else
                            TargetCompany := CopyStr(CompanyName(), 1, 30);

                        ProdOrder.ChangeCompany(TargetCompany);
                        ProdOrder.Reset();
                        ProdOrder.SetRange(Status, ProdOrder.Status::Released);
                        Clear(ProdOrderList);

                        ProdOrderList.SetTableView(ProdOrder);
                        ProdOrderList.LookupMode(true);

                        // Wenn bereits ein Filter gesetzt ist, Cursor auf ersten vorher
                        // gewählten FA positionieren, damit der Benutzer die Auswahl nur anpassen muss
                        if ProdOrderFilter <> '' then begin
                            FirstNo := cdeFilterMgt.GetFirstValueFromFilter(ProdOrderFilter);
                            FirstProdOrder.ChangeCompany(TargetCompany);
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

        // Infobox rechts: Zeitschiene + Stücklistenstruktur + Mandantenbestand
        area(FactBoxes)
        {
            part(cdeTimelinePart; cdeShortageTimelinePart)
            {
                ApplicationArea = All;
                Caption = 'Zeitschiene';
            }
            part(cdeItemBOMPart; cdeShortageItemBOMPart)
            {
                ApplicationArea = All;
                Caption = 'Stücklistenstruktur';
            }
            part(cdeCrossCompanyPart; cdeCrossCompanyPart)
            {
                ApplicationArea = All;
                Caption = 'Mandantenbestand';
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
            action(ShowBOMStructure)
            {
                ApplicationArea = All;
                Caption = 'Stücklistenstruktur';
                ToolTip = 'Öffnet die Stücklistenstruktur des aktuell markierten Artikels (wie in der Artikelkarte)';
                Image = BOM;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = Rec.ItemNo <> '';

                trigger OnAction()
                var
                    Item: Record Item;
                    BOMPage: Page cdeShortageBOMPage;
                begin
                    if not Item.Get(Rec.ItemNo) then exit;
                    // Prüfen ob für diesen Artikel überhaupt eine Fertigungsstückliste hinterlegt ist
                    if Item."Production BOM No." = '' then begin
                        Message('Für Artikel %1 - %2 ist keine Stücklistenstruktur vorhanden.', Item."No.", Item.Description);
                        exit;
                    end;
                    // ItemNo vor Run() setzen → OnOpenPage liest den Wert und lädt genau diesen Artikel
                    BOMPage.SetItemNo(Rec.ItemNo);
                    BOMPage.Run();
                end;
            }
            action("Where-Used")
            {
                AccessByPermission = TableData "Production BOM Header" = R;
                ApplicationArea = Manufacturing;
                Caption = 'Where-Used';
                Image = Track;
                ToolTip = 'Zeigt an, in welchen Fertigungsstücklisten dieser Artikel verwendet wird.';

                trigger OnAction()
                var
                    Item: Record Item;
                    WhereUsedPage: Page "Prod. BOM Where-Used";
                begin
                    if not Item.Get(Rec.ItemNo) then exit;
                    WhereUsedPage.SetItem(Item, WorkDate());
                    WhereUsedPage.Run();
                end;
            }
        }
    }

    var
        ProdOrderFilter: Text;
        CompanyFilter: Text[30];
        VariantFilter: Text;
        // RowStyle wird pro Zeile in OnAfterGetRecord gesetzt
        RowStyle: Text;

    trigger OnOpenPage()
    begin
        // Standard: aktueller Mandant vorbelegen, damit der Benutzer sofort den richtigen Kontext sieht
        if CompanyFilter = '' then
            CompanyFilter := CopyStr(CompanyName(), 1, 30);
    end;

    trigger OnAfterGetRecord()
    begin
        // Rot = kein Bestand vorhanden, Gelb = Teilbestand vorhanden
        if Rec.AvailableQty <= 0 then
            RowStyle := 'Unfavorable'
        else
            RowStyle := 'Attention';
    end;

    trigger OnAfterGetCurrRecord()
    var
        ProdOrder: Record "Production Order";
        StartingDate: Date;
    begin
        // FA-Startdatum für die Zeitschiene ermitteln
        if ProdOrder.Get(ProdOrder.Status::Released, Rec.ProdOrderNo) then
            StartingDate := ProdOrder."Starting Date"
        else
            StartingDate := Today();

        // Zeitschiene für den aktuell markierten Artikel aktualisieren
        CurrPage.cdeTimelinePart.Page.LoadTimeline(Rec.ItemNo, Rec.LocationCode, ProdOrderFilter, StartingDate);

        // Stücklistenstruktur für den aktuell markierten Artikel laden
        CurrPage.cdeItemBOMPart.Page.LoadBOM(Rec.ItemNo);

        // Mandantenbestand für den aktuell markierten Artikel laden
        // Neue Mandanten erscheinen automatisch, da die Company-Tabelle dynamisch gelesen wird
        CurrPage.cdeCrossCompanyPart.Page.LoadCrossCompanyStock(Rec.ItemNo);
    end;

    local procedure LoadData()
    var
        cdeShortageListMgt: Codeunit cdeShortageListMgt;
    begin
        // Fehlteile in den temporären Source-Table-Puffer laden
        // CompanyFilter leer = aktueller Mandant
        cdeShortageListMgt.LoadShortages(ProdOrderFilter, CompanyFilter, Rec);

        // Cursor auf ersten Datensatz setzen
        if Rec.FindFirst() then;

        // Seite neu zeichnen ohne Datensatz zu speichern
        CurrPage.Update(false);
    end;
}

