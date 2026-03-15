codeunit 50003 cdeSelectionFilterMgt
{
    /// <summary>
    /// Erstellt einen exakten Filterausdruck (mit | statt ..) aus einer Page-Selektion.
    /// Verhindert, dass nicht ausgewählte Datensätze durch einen Bereichsfilter eingeschlossen werden.
    /// </summary>
    procedure GetExactSelectionFilter(var ProdOrderPage: Page "Production Order List"; FieldNo: Integer): Text
    var
        ProdOrder: Record "Production Order";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FilterText: Text;
    begin
        // Alle markierten Zeilen der Page in den ProdOrder-Record übertragen
        ProdOrderPage.SetSelectionFilter(ProdOrder);

        if ProdOrder.FindSet() then
            repeat
                // Trennzeichen | zwischen den Werten setzen (nicht vor dem ersten)
                if FilterText <> '' then
                    FilterText += '|';

                // RecordRef wird benötigt, um dynamisch auf ein Feld per FieldNo zuzugreifen
                RecRef.GetTable(ProdOrder);

                // FieldRef zeigt auf das gewünschte Feld des aktuellen Datensatzes
                FieldRef := RecRef.Field(FieldNo);

                // Format() wandelt den Variant-Wert in Text um, damit er in den Filterstring passt
                FilterText += Format(FieldRef.Value);
            until ProdOrder.Next() = 0;

        // Fertigen Filterausdruck zurückgeben, z.B. '101002|101003|101005'
        exit(FilterText);
    end;

    /// <summary>
    /// Gibt den ersten FA-Wert aus einem Filter-Text zurück (z.B. '101002' aus '101002|101003|101005').
    /// Wird verwendet um beim erneuten Öffnen des Lookups den Cursor auf den ersten vorher gewählten FA zu setzen.
    /// </summary>
    procedure GetFirstValueFromFilter(FilterText: Text): Text
    var
        PipePos: Integer;
    begin
        if FilterText = '' then
            exit('');

        // Position des ersten | suchen
        PipePos := StrPos(FilterText, '|');

        // Wenn | gefunden: Text davor ist der erste Wert, sonst ist der gesamte Text der einzige Wert
        if PipePos > 0 then
            exit(CopyStr(FilterText, 1, PipePos - 1))
        else
            exit(FilterText);
    end;

    /// <summary>
    /// Allgemeine Version: Erstellt einen exakten | -Filter aus einem gefilterten Record.
    /// Verwendung: Nach SetSelectionFilter() aufrufen.
    /// </summary>
    procedure GetExactFilterFromRecord(var ProdOrder: Record "Production Order"): Text
    var
        FilterText: Text;
    begin
        // Über alle gefilterten (= markierten) Datensätze iterieren
        if ProdOrder.FindSet() then
            repeat
                // Trennzeichen | zwischen den Werten setzen (nicht vor dem ersten)
                if FilterText <> '' then
                    FilterText += '|';

                // FA-Nummer direkt anhängen – kein Bereich (..), nur exakte Werte
                FilterText += ProdOrder."No.";
            until ProdOrder.Next() = 0;

        // Fertigen Filterausdruck zurückgeben, z.B. '101002|101003|101005'
        exit(FilterText);
    end;
}
