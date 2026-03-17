/// <summary>
/// Simple filter query: all PLI Import Log Lines with error statuses.
/// Aggregation (count per company) is done in Codeunit logic via Dictionary;
/// see PLI Errors By Company Part page.
/// </summary>
query 70100 "PLI Error Lines"
{
    QueryType = Normal;
    Caption = 'Fehler-Zeilen';

    elements
    {
        dataitem(LogLine; "PLI Import Log Line")
        {
            column(EntryNo; "Entry No.") { }
            column(CompanyName; "Company Name") { }
            column(Status; Status) { }
            column(ErrorMessage; "Error Message") { }
        }
    }
}
