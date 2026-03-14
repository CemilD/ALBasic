codeunit 50004 cdeShortageListMgt
{
    /// <summary>
    /// Lädt alle Fehlteile für die gewählten Fertigungsaufträge in den temporären Puffer.
    /// Fehlteile = FA-Komponenten, bei denen der verfügbare Bestand den Bedarf nicht deckt.
    /// </summary>
    procedure LoadShortages(ProdOrderFilter: Text; var ShortageBuffer: Record cdeShortageListTableBuffer)
    var
        ProdOrderComp: Record "Prod. Order Component";
        AvailableQty: Decimal;
    begin
        // Bestehende Puffer-Einträge löschen, damit die Liste neu aufgebaut wird
        ShortageBuffer.Reset();
        ShortageBuffer.DeleteAll();

        // Ohne Filter keine Daten laden
        if ProdOrderFilter = '' then
            exit;

        // Alle Komponenten der freigegebenen FAs gemäß Filter einlesen
        ProdOrderComp.Reset();
        ProdOrderComp.SetRange(Status, ProdOrderComp.Status::Released);
        ProdOrderComp.SetFilter("Prod. Order No.", ProdOrderFilter);

        if ProdOrderComp.FindSet() then
            repeat
                // Verfügbaren Bestand des Artikels am Lagerort zum Bedarfstermin berechnen
                AvailableQty := CalcAvailableQty(ProdOrderComp);

                // Nur Fehlteile eintragen: verfügbarer Bestand deckt den verbleibenden Bedarf nicht
                if ProdOrderComp."Remaining Qty. (Base)" > AvailableQty then begin
                    ShortageBuffer.Init();

                    // Primärschlüssel: FA-Nr. + FA-Zeilennr. + Komponentenzeilennr.
                    ShortageBuffer.ProdOrderNo := ProdOrderComp."Prod. Order No.";
                    ShortageBuffer.ProdOrderLineNo := ProdOrderComp."Prod. Order Line No.";
                    ShortageBuffer.LineNo := ProdOrderComp."Line No.";

                    // Artikeldaten
                    ShortageBuffer.ItemNo := ProdOrderComp."Item No.";
                    ShortageBuffer.Description := ProdOrderComp.Description;

                    // Bedarfsinformationen aus der FA-Komponente
                    ShortageBuffer.DueDate := ProdOrderComp."Due Date";
                    ShortageBuffer.RequiredQty := ProdOrderComp."Remaining Quantity";
                    ShortageBuffer.UnitOfMeasure := ProdOrderComp."Unit of Measure Code";

                    // Lagerort für Rückverfolgung
                    // Hinweis: "Prod. Order Component" hat kein direktes Vorgangsfeld –
                    // OperationNo bleibt leer (Feld ist in der FA-Routing-Zeile, nicht in der Komponente)
                    ShortageBuffer.LocationCode := ProdOrderComp."Location Code";

                    // Aktuell verfügbarer Bestand am Lagerort (Basis-ME) zum Vergleich
                    ShortageBuffer.AvailableQty := AvailableQty;

                    ShortageBuffer.Insert();
                end;
            until ProdOrderComp.Next() = 0;
    end;

    /// <summary>
    /// Berechnet den verfügbaren Bestand eines Artikels am Lagerort zum Bedarfstermin.
    /// Gibt 0 zurück wenn der Artikel nicht gefunden wurde.
    /// </summary>
    local procedure CalcAvailableQty(ProdOrderComp: Record "Prod. Order Component"): Decimal
    var
        Item: Record Item;
    begin
        // Artikel laden – wenn nicht gefunden, Bestand = 0 (= immer Fehlteil)
        if not Item.Get(ProdOrderComp."Item No.") then
            exit(0);

        // Bestand am spezifischen Lagerort bis zum Bedarfstermin filtern
        Item.SetRange("Location Filter", ProdOrderComp."Location Code");
        Item.SetRange("Date Filter", ProdOrderComp."Due Date");

        // Inventory als FlowField berechnen lassen
        Item.CalcFields(Inventory);

        exit(Item.Inventory);
    end;
}
