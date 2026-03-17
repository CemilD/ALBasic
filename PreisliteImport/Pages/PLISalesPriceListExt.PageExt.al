pageextension 70110 "PLI Sales Price List Ext" extends "Sales Price List"
{
    actions
    {
        addlast(Processing)
        {
            action(PLIDownloadAsJson)
            {
                Caption = 'JSON herunterladen';
                ApplicationArea = All;
                Image = Export;
                ToolTip = 'Exportiert diese Preisliste (Kopf und alle Zeilen) als JSON-Datei für den PLI-Import.';

                trigger OnAction()
                begin
                    DownloadPriceListAsJson(Rec);
                end;
            }
        }
        addfirst(Promoted)
        {
            actionref(PLIDownloadAsJson_Promoted; PLIDownloadAsJson) { }
        }
    }

    local procedure DownloadPriceListAsJson(var PriceListHeader: Record "Price List Header")
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        DlFileName: Text;
    begin
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildPriceListJson(PriceListHeader));
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        DlFileName := PriceListHeader.Code + '.json';
        DownloadFromStream(InStream, 'JSON herunterladen', '', 'JSON-Dateien (*.json)|*.json', DlFileName);
    end;

    local procedure BuildPriceListJson(var PriceListHeader: Record "Price List Header"): Text
    var
        PriceListLine: Record "Price List Line";
        RootObj: JsonObject;
        MetaObj: JsonObject;
        HeaderObj: JsonObject;
        PricesArr: JsonArray;
        LineObj: JsonObject;
        JsonText: Text;
        EffCustNo: Code[20];
        EffCurrency: Code[10];
    begin
        // ── metadata ──────────────────────────────────────────────────────────────
        MetaObj.Add('version', '1.0');
        MetaObj.Add('type', 'SalesPricelist');
        MetaObj.Add('mandant', CompanyName());
        MetaObj.Add('created', Format(Today(), 0, '<Year4>-<Month,2>-<Day,2>'));
        if PriceListHeader."Starting Date" <> 0D then
            MetaObj.Add('validFrom', Format(PriceListHeader."Starting Date", 0, '<Year4>-<Month,2>-<Day,2>'))
        else
            MetaObj.Add('validFrom', '');
        if PriceListHeader."Ending Date" <> 0D then
            MetaObj.Add('validTo', Format(PriceListHeader."Ending Date", 0, '<Year4>-<Month,2>-<Day,2>'))
        else
            MetaObj.Add('validTo', '');
        RootObj.Add('metadata', MetaObj);

        // ── priceListHeader block ─────────────────────────────────────────────────
        HeaderObj.Add('code', PriceListHeader.Code);
        HeaderObj.Add('description', PriceListHeader.Description);
        HeaderObj.Add('sourceType', MapSourceTypeToString(PriceListHeader."Source Type"));
        HeaderObj.Add('sourceNo', PriceListHeader."Source No.");
        HeaderObj.Add('currency', PriceListHeader."Currency Code");
        if PriceListHeader."Starting Date" <> 0D then
            HeaderObj.Add('validFrom', Format(PriceListHeader."Starting Date", 0, '<Year4>-<Month,2>-<Day,2>'))
        else
            HeaderObj.Add('validFrom', '');
        if PriceListHeader."Ending Date" <> 0D then
            HeaderObj.Add('validTo', Format(PriceListHeader."Ending Date", 0, '<Year4>-<Month,2>-<Day,2>'))
        else
            HeaderObj.Add('validTo', '');
        HeaderObj.Add('vatBusPostingGroup', PriceListHeader."VAT Bus. Posting Gr. (Price)");
        HeaderObj.Add('priceIncludesVat', PriceListHeader."Price Includes VAT");
        HeaderObj.Add('allowUpdatingDefaults', PriceListHeader."Allow Updating Defaults");
        HeaderObj.Add('allowInvoiceDisc', PriceListHeader."Allow Invoice Disc.");
        HeaderObj.Add('allowLineDisc', PriceListHeader."Allow Line Disc.");
        HeaderObj.Add('amountType', Format(PriceListHeader."Amount Type"));
        RootObj.Add('priceListHeader', HeaderObj);

        // ── prices array ──────────────────────────────────────────────────────────
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        PriceListLine.SetRange("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.SetRange("Asset Type", PriceListLine."Asset Type"::Item);
        if PriceListLine.FindSet() then
            repeat
                Clear(LineObj);
                // customerNo: bevorzuge Zeile, fallback auf Kopf
                if PriceListLine."Source No." <> '' then
                    EffCustNo := PriceListLine."Source No."
                else
                    EffCustNo := PriceListHeader."Source No.";
                // currency: bevorzuge Zeile, fallback auf Kopf
                if PriceListLine."Currency Code" <> '' then
                    EffCurrency := PriceListLine."Currency Code"
                else
                    EffCurrency := PriceListHeader."Currency Code";

                LineObj.Add('customerNo', EffCustNo);
                LineObj.Add('itemNo', PriceListLine."Asset No.");
                LineObj.Add('unitOfMeasure', PriceListLine."Unit of Measure Code");
                LineObj.Add('minimumQuantity', PriceListLine."Minimum Quantity");
                LineObj.Add('unitPrice', PriceListLine."Unit Price");
                LineObj.Add('currency', EffCurrency);
                LineObj.Add('workTypeCode', PriceListLine."Work Type Code");
                LineObj.Add('allowLineDisc', PriceListLine."Allow Line Disc.");
                LineObj.Add('lineDiscountPct', PriceListLine."Line Discount %");
                LineObj.Add('allowInvoiceDisc', PriceListLine."Allow Invoice Disc.");
                LineObj.Add('priceIncludesVat', PriceListLine."Price Includes VAT");
                LineObj.Add('vatBusPostingGroup', PriceListLine."VAT Bus. Posting Gr. (Price)");
                if PriceListLine."Starting Date" <> 0D then
                    LineObj.Add('startingDate', Format(PriceListLine."Starting Date", 0, '<Year4>-<Month,2>-<Day,2>'))
                else
                    LineObj.Add('startingDate', '');
                if PriceListLine."Ending Date" <> 0D then
                    LineObj.Add('endingDate', Format(PriceListLine."Ending Date", 0, '<Year4>-<Month,2>-<Day,2>'))
                else
                    LineObj.Add('endingDate', '');
                PricesArr.Add(LineObj);
            until PriceListLine.Next() = 0;

        RootObj.Add('prices', PricesArr);
        RootObj.WriteTo(JsonText);
        exit(JsonText);
    end;

    local procedure MapSourceTypeToString(SourceType: Enum "Price Source Type"): Text
    begin
        case SourceType of
            "Price Source Type"::Customer:
                exit('Customer');
            "Price Source Type"::"All Customers":
                exit('AllCustomers');
            "Price Source Type"::"Customer Price Group":
                exit('CustomerPriceGroup');
            "Price Source Type"::"Customer Disc. Group":
                exit('CustomerDiscGroup');
            else
                exit('');
        end;
    end;
}
