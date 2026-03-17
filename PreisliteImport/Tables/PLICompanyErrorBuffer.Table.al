/// <summary>
/// Temporary buffer table for aggregated error counts per company.
/// Used exclusively by page 70109 "PLI Errors By Company Part" (SourceTableTemporary = true).
/// No records are ever persisted to the database.
/// </summary>
table 70102 "PLI Company Error Buffer"
{
    Caption = 'PLI Fehler pro Mandant Puffer';
    DataClassification = SystemMetadata;
    TableType = Normal;

    fields
    {
        field(1; "Company Name"; Text[30])
        {
            Caption = 'Mandant';
        }
        field(2; "Error Count"; Integer)
        {
            Caption = 'Anzahl Fehler';
        }
    }

    keys
    {
        key(PK; "Company Name")
        {
            Clustered = true;
        }
    }
}
