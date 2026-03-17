codeunit 50008 MultiplyCalc implements ICalc
{
    procedure Calculate(Num1: Decimal; Num2: Decimal): Decimal
    begin
        exit(Num1 * Num2);
    end;
}
