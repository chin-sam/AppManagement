table 11155300 "IDYM Product"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    Extensible = false;
    DataPerCompany = false;
    fields
    {
        field(1; Id; Text[50])
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
        field(2; "Payment Provider"; Enum "IDYM Payment Provider")
        {
            Caption = 'Provider';
            DataClassification = SystemMetadata;
        }
        field(10; Name; Text[50])
        {
            Caption = 'Name';
            DataClassification = SystemMetadata;
        }
        field(11; "Product Guid"; Guid)
        {
            Caption = 'Product Guid';
            DataClassification = SystemMetadata;
        }
        field(100; "Stripe Token Id"; Text[50])
        {
            Caption = 'Stripe Token Id';
            Access = Internal;
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; Id, "Payment Provider")
        {
            Clustered = true;
        }
    }

    internal procedure SetUnrestricedAccess()
    begin
        UnrestricedAccess := true;
    end;

    internal procedure HasUnrestricedAccess(): Boolean
    begin
        exit(UnrestricedAccess);
    end;

    protected var
        UnrestricedAccess: Boolean;
}