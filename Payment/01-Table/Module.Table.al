table 11155297 "IDYM Module"
{
    DataClassification = SystemMetadata;
    Access = Internal;
    Extensible = false;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
            NotBlank = true;
            Editable = false;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(10; Type; Option)
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
            Editable = false;
            OptionMembers = applicationarea,company;
            OptionCaption = 'applicationarea,company';
        }
        field(11; Value; Text[50])
        {
            Caption = 'Value';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(20; Optional; Boolean)
        {
            Caption = 'Optional';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(21; "Has Tiers"; Boolean)
        {
            Caption = 'Optional';
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = exist("IDYM Tier" where("App Id" = field("App Id"), "Module Id" = field(Id)));
        }
        field(50; "App Id"; Guid)
        {
            Caption = 'App Id';
            DataClassification = SystemMetadata;
            NotBlank = true;
            Editable = false;
        }
        field(100; Select; Boolean)
        {
            Caption = 'Select';
            DataClassification = SystemMetadata;
        }
        field(102; Active; Boolean)
        {
            Caption = 'Active';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }

    internal procedure GetModulePrice(Currency: Code[10]; OrderQuantity: Integer; PricePlanID: Guid) Price: Decimal
    var
        Tier: Record "IDYM Tier";
        AppPrice: Record "IDYM App Price";
        EmptyGuid: Guid;
    begin
        AppPrice.SetRange("App ID", "App Id");
        AppPrice.SetRange("Module Id", Id);
        AppPrice.SetFilter("Currency Code", '%1|%2', '', Currency);
        AppPrice.SetRange("Price Plan ID", PricePlanID);
        CalcFields("Has Tiers");
        if "Has Tiers" then begin
            GetTier(Tier, Id);
            AppPrice.SetRange("Tier ID", Tier.Id);
        end else
            AppPrice.SetRange("Tier ID", EmptyGuid);
        AppPrice.FindLast();
        Price += AppPrice."Total Price";
        Price += AppPrice."Unit Price";
    end;

    local procedure GetTier(var Tier: Record "IDYM Tier"; ModuleID: Guid) HasTier: Boolean
    begin
        Clear(Tier);
        Tier.SetRange("App Id", "App Id");
        Tier.SetRange("Module Id", ModuleID);
        Tier.SetRange("No Upper Limit", false);
        HasTier := Tier.FindLast();
        if not HasTier then begin
            Tier.SetRange("No Upper Limit", true);
            Tier.SetRange("Maximum Quantity", 0);
            HasTier := Tier.FindLast();
        end;
    end;

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