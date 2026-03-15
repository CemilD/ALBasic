page 50006 pdeMD04MaterialInfoPart
{
    PageType = CardPart;
    Caption = 'Material Info';
    // SourceTable Item: wird automatisch via SubPageLink auf die aktuelle Zeile verknüpft
    SourceTable = Item;
    Editable = false;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
                Caption = 'Item No.';
                ToolTip = 'Artikelnummer des analysierten Materials.';
            }
            field(Description; Rec.Description)
            {
                ApplicationArea = All;
                Caption = 'Description';
                ToolTip = 'Artikelbezeichnung.';
            }
            field("Base Unit of Measure"; Rec."Base Unit of Measure")
            {
                ApplicationArea = All;
                Caption = 'Base UoM';
                ToolTip = 'Basismengeneinheit dieses Artikels.';
            }
            field("Item Category Code"; Rec."Item Category Code")
            {
                ApplicationArea = All;
                Caption = 'Item Category';
                ToolTip = 'Artikelkategorie für die Klassifizierung.';
            }
            field(Inventory; Rec.Inventory)
            {
                ApplicationArea = All;
                Caption = 'Current Inventory';
                // FlowField: wird in OnAfterGetRecord via CalcFields berechnet
                ToolTip = 'Aktueller Lagerbestand über alle Lagerorte.';
            }
            field("Net Change"; Rec."Net Change")
            {
                ApplicationArea = All;
                Caption = 'Net Change (Year)';
                // FlowField: Nettoveränderung im aktuellen Jahr
                ToolTip = 'Nettoveränderung im laufenden Geschäftsjahr.';
            }
            field("Reorder Point"; Rec."Reorder Point")
            {
                ApplicationArea = All;
                Caption = 'Reorder Point';
                ToolTip = 'Mindestbestand, ab dem eine Nachbestellung ausgelöst wird.';
            }
            field("Safety Stock Quantity"; Rec."Safety Stock Quantity")
            {
                ApplicationArea = All;
                Caption = 'Safety Stock';
                ToolTip = 'Sicherheitsbestand als Reserve bei ungeplanten Bedarfsschwankungen.';
            }
            field("Lead Time Calculation"; Rec."Lead Time Calculation")
            {
                ApplicationArea = All;
                Caption = 'Lead Time';
                ToolTip = 'Standardbeschaffungszeit für diesen Artikel.';
            }
            field("Vendor No."; Rec."Vendor No.")
            {
                ApplicationArea = All;
                Caption = 'Vendor';
                ToolTip = 'Standardlieferant für diesen Artikel.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        // FlowFields explizit neu berechnen damit aktuelle Werte angezeigt werden
        Rec.CalcFields(Inventory, "Net Change");
    end;
}
