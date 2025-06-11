table 11155295 "IDYM App Price"
{
    DataClassification = SystemMetadata;
    Access = Internal;
    Extensible = false;

    fields
    {
        field(1; "App ID"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'App ID';
            Editable = false;
            NotBlank = true;

            trigger OnValidate()
            var
                ModuleInfo: ModuleInfo;
            begin
                if NavApp.GetModuleInfo("App ID", ModuleInfo) then
                    Validate("App Name", CopyStr(ModuleInfo.Name, 1, MaxStrLen("App Name")));
            end;
        }
        field(2; "Tier ID"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Tier ID';
            Editable = false;
            NotBlank = true;
            TableRelation = "IDYM Tier".Id where("App Id" = field("App ID"), "Module Id" = field("Module Id"));
        }
        field(3; "Price Plan ID"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Price Plan ID';
            Editable = false;
            NotBlank = true;
            TableRelation = "IDYM Price Plan".Id where("App Id" = field("App ID"));
        }
        field(4; "Module Id"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Module ID';
            Editable = false;
            TableRelation = "IDYM Module".Id where("App Id" = field("App ID"));
        }
        field(5; "Currency Code"; Code[10])
        {
            DataClassification = SystemMetadata;
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(6; "Starting Date"; Date)
        {
            DataClassification = SystemMetadata;
            Caption = 'Starting Date';
            Editable = false;

            trigger OnValidate()
            var
                StartDateBeforeEndDateErr: Label '%1 cannot be after %2', Comment = '%1 = Fieldcaption of Start Date, %2 = Fieldcaption of Ending Date';
            begin
                if ("Starting Date" > "Ending Date") and ("Ending Date" <> 0D) then
                    Error(StartDateBeforeEndDateErr, FieldCaption("Starting Date"), FieldCaption("Ending Date"));
            end;
        }
        field(10; "App Name"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'App Name';
            Editable = false;
        }
        field(11; "Tier Name"; Text[100])
        {
            FieldClass = FlowField;
            Caption = 'Tier Name';
            CalcFormula = lookup("IDYM Tier".Description where("App Id" = field("App ID"), Id = field("Tier ID")));
            Editable = false;
        }
        field(12; "Price Plan Name"; Text[100])
        {
            FieldClass = FlowField;
            Caption = 'Price Plan Name';
            CalcFormula = lookup("IDYM Price Plan".Description where("App Id" = field("App ID"), Id = field("Price Plan ID")));
            Editable = false;
        }
        field(13; "Module Name"; Text[100])
        {
            FieldClass = FlowField;
            Caption = 'Module Name';
            CalcFormula = lookup("IDYM Module".Description where("App Id" = field("App ID"), Id = field("Module ID")));
            Editable = false;
        }
        field(20; "Unit Price"; Decimal)
        {
            DataClassification = SystemMetadata;
            Caption = 'Unit Price';
            Editable = false;
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            MinValue = 0;
        }
        field(21; "Total Price"; Decimal)
        {
            DataClassification = SystemMetadata;
            Caption = 'Total Price';
            Editable = false;
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            MinValue = 0;
        }
        field(22; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            Editable = false;

            trigger OnValidate()
            begin
                if CurrFieldNo = 0 then
                    exit;

                Validate("Starting Date");
            end;
        }
        field(30; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "App ID", "Tier ID", "Price Plan ID", "Module Id", "Starting Date", "Currency Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "App Name", "Tier Name", "Price Plan Name", "Module Name", "Currency Code", "Total Price")
        {
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