codeunit 50000 cdeKVPMgt
{
    procedure GetBodyText(var CDEKVPTableMyTable: Record CDEKVPTableMyTable) BodyText: Text
    var
        BodyInStream: InStream;
    begin
        CDEKVPTableMyTable.CalcFields(Body);
        CDEKVPTableMyTable.Body.CreateInStream(BodyInStream, TextEncoding::UTF8);
        BodyInStream.Read(BodyText);
    end;

    local procedure SetBodyTextData(var CDEKVPTableMyTable: Record CDEKVPTableMyTable; BodyText: Text)
    var
        BodyOutStream: OutStream;
    begin
        Clear(CDEKVPTableMyTable.Body);

        if BodyText = '' then
            exit;

        CDEKVPTableMyTable.Body.CreateOutStream(BodyOutStream, TextEncoding::UTF8);
        BodyOutStream.Write(BodyText);
    end;

    procedure SetBody(var CDEKVPTableMyTable: Record CDEKVPTableMyTable; BodyText: Text)
    begin
        SetBodyTextData(CDEKVPTableMyTable, BodyText);
        CDEKVPTableMyTable.Modify();
    end;
}