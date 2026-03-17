enum 70100 "PLI Import Status"
{
    Extensible = true;
    Caption = 'PLI Import Status';

    value(0; " ") { Caption = ' '; }
    value(1; Success) { Caption = 'Success'; }
    value(2; "Partial") { Caption = 'Partial'; }
    value(3; Failed) { Caption = 'Failed'; }
    value(4; Running) { Caption = 'Running'; }
}
