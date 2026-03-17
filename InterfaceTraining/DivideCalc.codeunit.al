codeunit 50009 DivideCalc implements ICalc
{
    procedure Calculate(Num1: Decimal; Num2: Decimal): Decimal
    begin
        if Num2 = 0 then
            Error('Division durch 0 ist nicht erlaubt.');
        exit(Num1 / Num2);
    end;
}
