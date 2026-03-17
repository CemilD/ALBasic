enum 70101 "PLI Line Import Status"
{
    Extensible = true;
    Caption = 'PLI Line Import Status';

    value(0; " ") { Caption = ' '; }
    value(1; Imported) { Caption = 'Imported'; }
    value(2; Updated) { Caption = 'Updated'; }
    value(3; Error) { Caption = 'Error'; }
    value(4; Skipped) { Caption = 'Skipped'; }
}
