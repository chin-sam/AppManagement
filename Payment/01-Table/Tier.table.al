table 11155303 "IDYM Tier"
{
    DataClassification = SystemMetadata;
    Access = Internal;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
            Editable = false;
            NotBlank = true;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(10; "Minimum Quantity"; Decimal)
        {
            DataClassification = SystemMetadata;
            Caption = 'Minimum Quantity';
            Editable = false;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(11; "Maximum Quantity"; Decimal)
        {
            DataClassification = SystemMetadata;
            Caption = 'Maximum Quantity';
            Editable = false;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(12; "No Upper Limit"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'No Upper Limit';
            Editable = false;
        }
        field(50; "App Id"; Guid)
        {
            Caption = 'App Id';
            DataClassification = SystemMetadata;
            Editable = false;
            NotBlank = true;
        }
        field(51; "Module Id"; Guid)
        {
            Caption = 'Parent Id';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "IDYM Module" where("App Id" = field("App Id"));
        }
        // field(100; Select; Boolean)
        // {
        //     Caption = 'Select';
        //     DataClassification = CustomerContent;
        // }
        // field(102; Active; Boolean)
        // {
        //     Caption = 'Active';
        //     DataClassification = CustomerContent;
        //     Editable = false;
        // }
    }

    keys
    {
        key(PK; Id)
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