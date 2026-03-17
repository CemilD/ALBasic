page 50032 CalcPage
{
    PageType = Card;
    Caption = 'Taschenrechner';
    UsageCategory = Tasks;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Eingabe)
            {
                Caption = 'Eingabe';

                field(Zahl1; Zahl1)
                {
                    ApplicationArea = All;
                    Caption = 'Zahl 1';
                    trigger OnValidate()
                    begin
                        Berechnen();
                    end;
                }
                field(Zahl2; Zahl2)
                {
                    ApplicationArea = All;
                    Caption = 'Zahl 2';
                    trigger OnValidate()
                    begin
                        Berechnen();
                    end;
                }
                field(Rechenart; Rechenart)
                {
                    ApplicationArea = All;
                    Caption = 'Rechenart';
                    trigger OnValidate()
                    begin
                        Berechnen();
                    end;
                }
            }
            group(Ergebnis)
            {
                Caption = 'Ergebnis';

                field(Resultat; Resultat)
                {
                    ApplicationArea = All;
                    Caption = 'Ergebnis';
                    Editable = false;
                    Style = Strong;
                }
            }
        }
    }

    var
        Zahl1: Decimal;
        Zahl2: Decimal;
        Rechenart: Enum Calc;
        Resultat: Decimal;

    local procedure Berechnen()
    var
        ICalcImpl: Interface ICalc;
    begin
        ICalcImpl := Rechenart;
        Resultat := ICalcImpl.Calculate(Zahl1, Zahl2);
    end;
}
