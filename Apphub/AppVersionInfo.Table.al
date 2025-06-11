table 11155294 "IDYM App Version Info"
{
    Caption = 'App Version Info';
    DataClassification = CustomerContent;
    DataPerCompany = false;
    Access = Internal;

    fields
    {
        field(1; "App Id"; Guid)
        {
            Caption = 'App Id';
            DataClassification = CustomerContent;
        }
        field(2; "Latest Version"; Text[100])
        {
            Caption = 'Latest Version';
            DataClassification = CustomerContent;
        }
        field(3; "Oldest Major"; Integer)
        {
            Caption = 'Oldest Major';
            DataClassification = CustomerContent;
        }
        field(4; "Requested On"; DateTime)
        {
            Caption = 'Requested On';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK; "App Id")
        {
            Clustered = true;
        }
    }
}
