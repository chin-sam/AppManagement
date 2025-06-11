table 11155298 "IDYM Plan"
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
        field(10; "Product Id"; Text[50])
        {
            Caption = 'Product Id';
            DataClassification = SystemMetadata;
        }
        field(11; "Product Name"; Text[50])
        {
            Caption = 'Product Name';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("IDYM Product".Name where(Id = field("Product Id")));
        }
        field(12; Amount; Integer)
        {
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(13; Currency; Code[10])
        {
            Caption = 'Currency';
            DataClassification = SystemMetadata;
        }
        field(14; Interval; Option)
        {
            Caption = 'Interval';
            OptionMembers = day,week,month,year;
            OptionCaption = 'day,week,month,year';
            DataClassification = SystemMetadata;
        }
        field(15; "Interval Count"; Integer)
        {
            Caption = 'Interval count';
            DataClassification = SystemMetadata;
        }
        field(16; "Trial Period Interval"; Option)
        {
            Caption = 'Trial Interval';
            OptionMembers = day,week,month,year;
            OptionCaption = 'day,week,month,year';
            DataClassification = SystemMetadata;
        }
        field(17; "Trial Period"; Integer)
        {
            Caption = 'Trial Period';
            DataClassification = SystemMetadata;
        }
        field(18; Select; Boolean)
        {
            Caption = 'Select';
            DataClassification = SystemMetadata;
        }
        field(19; "Internal Invoice"; Integer)
        {
            Caption = 'Internal';
            DataClassification = SystemMetaData;
            Access = Internal;
        }
        field(20; Active; Boolean)
        {
            Caption = 'Active';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; Id, "Payment Provider")
        {
            Clustered = true;
        }
        key(ProductId; "Product Id") { }
        key(Select; Select) { }
        key(Key1; "Trial Period Interval", "Trial Period") { }
        key(Key2; "Product Id", "Trial Period Interval", "Trial Period", "Internal Invoice") { }
        key(Key3; Active, Currency, Interval) { }
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