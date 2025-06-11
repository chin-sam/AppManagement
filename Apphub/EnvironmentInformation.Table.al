table 11155305 "IDYM Environment Information"
{
    Caption = 'Environment Information';
    DataClassification = CustomerContent;
    DataPerCompany = false;
    Access = Internal;

    fields
    {
        field(1; "Environment Id"; Guid)
        {
            Caption = 'Environment Id';
            DataClassification = SystemMetadata;
        }
        field(2; "Environment Name"; Text[100])
        {
            Caption = 'Environment Name';
        }
    }
    keys
    {
        key(PK; "Environment Id")
        {
            Clustered = true;
        }
    }
}
