table 11155299 "IDYM Price Plan"
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
        field(10; Interval; Option)
        {
            Caption = 'Interval';
            DataClassification = CustomerContent;
            OptionMembers = Day,Week,Month,Year;
            OptionCaption = 'Day,Week,Month,Year';
            Editable = false;
        }
        field(11; "Interval Count"; Integer)
        {
            Caption = 'Interval count';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(20; "Trial Period Interval"; Option)
        {
            Caption = 'Trial Interval';
            DataClassification = CustomerContent;
            Editable = false;
            OptionMembers = Day,Week,Month,Year;
            OptionCaption = 'Day,Week,Month,Year';
        }
        field(21; "Trial Period"; Integer)
        {
            Caption = 'Trial Period';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50; "App Id"; Guid)
        {
            Caption = 'App Id';
            DataClassification = SystemMetadata;
            NotBlank = true;
            Editable = false;

            trigger OnValidate()
            var
                AppInfo: ModuleInfo;
            begin
                NavApp.GetModuleInfo("App Id", AppInfo);
                Validate("App Name", CopyStr(AppInfo.Name, 1, MaxStrLen("App Name")));
            end;
        }
        field(51; "App Name"; Text[50])
        {
            Caption = 'App Name';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(100; Select; Boolean)
        {
            Caption = 'Select';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                PricePlan: Record "IDYM Price Plan";
            begin
                if Rec.Select then begin
                    PricePlan.SetRange(Select, true);
                    PricePlan.SetFilter(Id, '<>%1', Rec.Id);
                    if PricePlan.FindFirst() then begin
                        PricePlan.Select := false;
                        PricePlan.SetUnrestricedAccess();
                        PricePlan.Modify();
                    end;
                end;
            end;
        }
        field(101; "Internal Invoice"; Integer)
        {
            Caption = 'Internal';
            DataClassification = SystemMetaData;
            Access = Internal;
            Editable = false;
        }
        field(102; Active; Boolean)
        {
            Caption = 'Active';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        #region OLDPaypalButton
        field(200; "Payment Status"; Enum "IDYM Payment Status")
        {
            Access = Internal;
            DataClassification = SystemMetadata;
            Caption = 'Payment Status';
            Editable = false;
        }
        field(201; "Payment Id"; Text[100])
        {
            Access = Internal;
            DataClassification = SystemMetadata;
            Caption = 'Payment Id';
            Editable = false; //to do make external...
        }
        field(202; "Subscription Id"; Text[100])
        {
            Access = Internal;
            DataClassification = SystemMetadata;
            Caption = 'Subscription Id';
            Editable = false; //to do make external...

            trigger OnValidate()
            var
                PricePlan: Record "IDYM Price Plan";
            begin
                if "Subscription Id" <> '' then begin
                    PricePlan.SetRange("Subscription Id", "Subscription Id");
                    PricePlan.SetFilter(Id, '<>%1', Id);
                    if PricePlan.FindFirst() then begin
                        PricePlan."Subscription Id" := '';
                        PricePlan."Payment Id" := '';
                        Clear(PricePlan."Payment Status");
                        PricePlan.SetUnrestricedAccess();
                        PricePlan.Modify();
                    end;
                end;
            end;
        }
        field(203; Id_Int; Integer)
        {
            Access = Internal;
            Editable = false;
            Caption = 'Id';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        #endregion
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
        key(Select; Select) { }
        key(Key1; "Trial Period Interval", "Trial Period") { }
        key(Key2; Id_Int) { }
    }

    internal procedure GetPricePlanPrice(Currency: Code[10]; var VAT: Decimal) Price: Decimal
    var
        Tier: Record "IDYM Tier";
        AppPrice: Record "IDYM App Price";
        EmptyGuid: Guid;
        HasTier: Boolean;
    begin
        HasTier := GetTier(Tier, EmptyGuid);
        AppPrice.SetRange("App ID", "App Id");
        if HasTier then
            AppPrice.SetRange("Tier ID", Tier.Id);

        AppPrice.SetRange("Price Plan ID", Id);
        AppPrice.SetFilter("Currency Code", '%1|%2', '', Currency);
        AppPrice.SetRange("Module Id", EmptyGuid);
        AppPrice.FindLast();
        VAT := AppPrice."VAT %";

        UsedTierId := AppPrice."Tier ID";

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

    internal procedure GetTierId(): Guid
    begin
        exit(UsedTierId);
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

    var
        UsedTierId: Guid;
}