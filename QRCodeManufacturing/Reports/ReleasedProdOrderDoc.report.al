report 50000 CDEReleasedProdOrderDoc
{
    ApplicationArea = Manufacturing;
    UsageCategory = Documents;
    Caption = 'CDE Prod. Order Document';
    DefaultRenderingLayout = "./QRCodeManufacturing/Layouts/CDEProdOrderDoc.rdlc";

    dataset
    {
        dataitem(ProductionOrder; "Production Order")
        {
            DataItemTableView = sorting(Status, "No.");
            RequestFilterFields = Status, "No.", "Source Type", "Source No.";

            column(StatusProdOrder; Status)
            {
                Caption = 'Status', Comment = 'Deu = Status';
            }
            column(prodOrderNoCount; ProductionOrder.COUNT)
            {
                Caption = 'Production Order No. Count', Comment = 'Deu = "Anzahl der FA-Nummern"';
            }
            column(NoProdOrder; "No.")
            {
                Caption = 'Production Order No.', Comment = 'Deu = "FA- Nummer"';
            }
            column(QRProdOrderNo; QRProdOrderNo)
            {
                Caption = 'QR Code for Production Order No.';
            }
            column(CommentProductionOrder; Comment)
            {
                Caption = 'Comment', Comment = 'Deu = Bemerkung';
            }
            column(DueDateProductionOrder; "Due Date")
            {
                Caption = 'Due Date', Comment = 'Deu = "Fälligkeitsdatum"';
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(TodayFormatted; Format(Today, 0, 4))
                {
                }
                column(CompanyName; COMPANYPROPERTY.DisplayName())
                {
                }
                column(ProdOrderTableCaptionFilt; ProductionOrder.TableCaption + ':' + ProdOrderFilter)
                {
                }
                column(ProdOrderFilter; ProdOrderFilter)
                {
                }
            }
            dataitem(ProdOrderRoutingLine; "Prod. Order Routing Line")
            {
                DataItemLink = Status = field(Status), "Prod. Order No." = field("No.");
                DataItemTableView = sorting(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.");

                column(Description; Description)
                {
                    Caption = 'Description', Comment = 'Deu = "Beschreibung"';
                }
                column(ProdRoutingLineCount; ProdOrderRoutingLine.COUNT)
                {
                    Caption = 'Production Order Routing Line Count', Comment = 'Deu = "Anzahl der FA-Arbeitspläne"';
                }
                column(EndingDate_ProdOrderRoutingLine; "Ending Date")
                {
                    Caption = 'Ending Date', Comment = 'Deu = "Endet am"';
                }
                column(EndingTime_ProdOrderRoutingLine; "Ending Time")
                {
                    Caption = 'Ending Time', Comment = 'Deu = "Endet um"';
                }
                column(LocationCode_ProdOrderRoutingLine; "Location Code")
                {
                    Caption = 'Location Code', Comment = 'Deu = "Lagerort"';
                }
                column(LotSize_ProdOrderRoutingLine; "Lot Size")
                {
                    Caption = 'Lot Size', Comment = 'Deu = "Losgröße"';
                }
                column(RoutingNo_ProdOrderRoutingLine; "Routing No.")
                {
                    Caption = 'Routing No.', Comment = 'Deu = "Arbeitsplan-Nr."';
                }
                column(QRCodeRoutingLine; QRCodeRoutingLine)
                {
                    Caption = 'QR Code for Routing No.';
                }
                column(StartingTime_ProdOrderRoutingLine; "Starting Time")
                {
                    Caption = 'Starting Time', Comment = 'Deu = "Beginnt um"';
                }
                column(StartingDate_ProdOrderRoutingLine; "Starting Date")
                {
                    Caption = 'Starting Date', Comment = 'Deu = "Beginnt am"';
                }
            }
            trigger OnAfterGetRecord()
            var
                ProdOderRoutingLine: Record "Prod. Order Routing Line";
            begin
                ProdORderRoutingLine.SetRange(Status, Status::Released);
                ProdORderRoutingLine.SetRange("Prod. Order No.", "No.");
                if ProdORderRoutingLine.IsEmpty() then
                    CurrReport.Skip();

                //QR Code will be generated 
                QRCodeGenerater();
            end;

            trigger OnPreDataItem()
            begin
                ProdOrderFilter := GetFilters();
            end;
        }
    }
    requestpage
    {
        AboutTitle = 'About Prod. Order - Job Card';
        AboutText = 'Details out the components and capacity required to fulfil a Production Order. Use it to provide a printable report that your team can use to execute the manufacturing job.';

        layout
        {
        }

        actions
        {
        }
    }

    rendering
    {
        layout("./QRCodeManufacturing/Layouts/CDEProdOrderDoc.rdlc")
        {
            Type = RDLC;
            LayoutFile = './QRCodeManufacturing/Layouts/CDEProdOrderDoc.rdlc';
        }
    }

    local procedure joinStringLines(): Text
    begin
        // Format: "<FA-Nr.><Separator><Routing-Nr.>"
        // Zum Splitten: Text.Split(GetSeparator()) verwenden
        exit(StrSubstNo('%1%2%3', ProductionOrder."No.", GetSeparator(), ProdOrderRoutingLine."Routing No."));
    end;

    local procedure GetSeparator(): Text
    begin
        exit('#'); // Trennzeichen – hier ändern falls nötig
    end;

    local procedure QRCodeGenerater()
    var
        BarcodeSmybology2D: Enum "Barcode Symbology 2D";
        BarcodeFrontPovider: Interface "Barcode Font Provider 2D";
        QRCodeStrNo: Text;
        QRCodeStrRoutingLine: Text;
    begin
        BarcodeSmybology2D := Enum::"Barcode Symbology 2D"::"QR-Code";
        BarcodeFrontPovider := Enum::"Barcode Font Provider 2D"::IDAutomation2D;
        QRCodeStrNo := ProductionOrder."No.";
        QRCodeStrRoutingLine := ProdOrderRoutingLine."Routing No.";

        QRprodOrderNo := BarcodeFrontPovider.EncodeFont(QRCodeStrNo, BarcodeSmybology2D);
        // QRCodeRoutingLine := BarcodeFrontPovider.EncodeFont(QRCodeStrRoutingLine, BarcodeSmybology2D);


    end;

    var
        ProdOrderFilter: Text;
        QRprodOrderNo: Text;
        QRCodeRoutingLine: Text;
        count1: Integer;
        count2: Integer;

    // Beispiel zum Lesen/Splitten:
    // Parts := joinStringLines().Split(GetSeparator());
    // ProdOrderNo  := Parts.Get(1);
    // RoutingNo    := Parts.Get(2);
}