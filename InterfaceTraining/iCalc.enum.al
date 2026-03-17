enum 50000 Calc implements ICalc
{
    Extensible = true;

    value(0; Addition)
    {
        Caption = 'Addition (+)';
        Implementation = ICalc = AddCalc;
    }
    value(1; Subtraktion)
    {
        Caption = 'Subtraktion (-)';
        Implementation = ICalc = SubtractCalc;
    }
    value(2; Multiplikation)
    {
        Caption = 'Multiplikation (x)';
        Implementation = ICalc = MultiplyCalc;
    }
    value(3; Division)
    {
        Caption = 'Division (/)';
        Implementation = ICalc = DivideCalc;
    }
}