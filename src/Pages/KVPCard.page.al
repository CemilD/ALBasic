page 50001 cdeKVPCard
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = CDEKVPTableMyTable;

    layout
    {
        area(Content)
        {
            group(KVPHeader)
            {
                ShowCaption = false;
                Caption = ' ';
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Subject field.';
                }
                field("Owner"; Rec."Owner")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the owner of the KVP record.';
                }
                field(KVPid; Rec.KVPid)
                {
                    ToolTip = 'Specifies the value of the KVPid field.', Comment = '%';
                }

            }
            group(KVPText)
            {
                field("KVP Editor"; BodyText)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the content of the email.';
                    MultiLine = true;
                    Caption = 'KVP Vorschlag';
                    ExtendedDatatype = RichContent;

                    trigger OnValidate()
                    begin
                        cdeKVPMgt.SetBody(Rec, BodyText);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        BodyText := cdeKVPMgt.GetBodyText(Rec);
    end;

    var
        BodyText: Text;
        cdeKVPMgt: Codeunit cdeKVPMgt;
}