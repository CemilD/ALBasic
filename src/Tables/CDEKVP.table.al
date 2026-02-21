table 50000 CDEKVPTableMyTable
{

    fields
    {
        field(1; KVPid; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(2; Subject; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Betreff', Comment = 'DEU=Betreff';
        }
        field(3; Body; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Inhalt', Comment = 'DEU=Inhalt';
        }
        field(4; Editable; Boolean)
        {
            InitValue = true;
            Access = Internal;
            DataClassification = SystemMetadata;
        }
        field(5; "HTML Formatted Body"; Boolean)
        {
            Access = Internal;
            DataClassification = SystemMetadata;
            InitValue = true;
        }
        field(6; "No. of Modifies"; Integer)
        {
            Access = Internal;
            InitValue = 0;
            DataClassification = SystemMetadata;
        }
        field(7; "External Id"; Text[2048])
        {
            Access = Internal;
            DataClassification = CustomerContent;
        }
        field(8; "Owner"; Code[20])
        {
            Access = Internal;
            DataClassification = CustomerContent;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
            Caption = 'Submitted By', Comment = 'DEU= Eingereicht durch';
        }
        field(9; SourceNo; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Fertigungsauftragsnr.', Comment = 'DEU=Fertigungsauftragsnr.';
        }
        field(10; ItemNo; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Artikelnummer', Comment = 'DEU=Artikelnummer';
            TableRelation = Item."No.";

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if ItemNo <> '' then begin
                    if Item.Get(ItemNo) then
                        ItemDescription := Item.Description
                end
            end;
        }
        field(11; ItemDescription; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Artikelbeschreibung', Comment = 'DEU=Artikelbeschreibung';
        }
    }
    keys
    {
        key(Key1; KVPid, ItemNo)
        {
            Clustered = true;
        }
    }
    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
        KVPseriesCode: Code[20];
    begin
        KVPseriesCode := 'KVP';

        if KVPid = '' then begin
            //NoSeriesRecord.Get();
            KVPid := NoSeries.GetNextNo(KVPseriesCode);
        end;
    end;
}
