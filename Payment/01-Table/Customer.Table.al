table 11155296 "IDYM Customer"
{
    DataClassification = CustomerContent;
    Access = Internal;
    fields
    {
        field(1; Id; Text[50])
        {
            Caption = 'Id';
            DataClassification = CustomerContent;
        }
        field(10; "Account Balance"; Integer)
        {
            Caption = 'Account Balance';
            DataClassification = CustomerContent;
        }
        field(11; "VAT Id"; Text[30])
        {
            Caption = 'VAT Id';
            DataClassification = CustomerContent;
        }
        field(12; Currency; Code[3])
        {
            Caption = 'Currency';
            DataClassification = CustomerContent;
        }
        field(13; Delinquent; Boolean)
        {
            Caption = 'Delinquent';
            DataClassification = CustomerContent;
        }
        field(14; Email; Text[80])
        {
            Caption = 'Email';
            DataClassification = CustomerContent;
        }
        field(15; Name; Text[100])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
        }
        field(16; Address; Text[100])
        {
            Caption = 'Address';
            DataClassification = CustomerContent;
        }
        field(17; "Address 2"; Text[100])
        {
            Caption = 'Address 2';
            DataClassification = CustomerContent;
        }
        field(18; "Postal Code"; Code[20])
        {
            Caption = 'Postal Code';
            DataClassification = CustomerContent;
        }
        field(19; City; Text[50])
        {
            Caption = 'City';
            DataClassification = CustomerContent;
        }
        field(20; State; Text[30])
        {
            Caption = 'State';
            DataClassification = CustomerContent;
        }
        field(21; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
            DataClassification = CustomerContent;
        }
        field(22; "Country/Region ISO Code"; Code[2])
        {
            Caption = 'Country/Region Code';
            FieldClass = FlowField;
            CalcFormula = lookup("Country/Region"."ISO Code" where(Code = field("Country/Region Code")));
            Editable = false;
        }
        field(23; Phone; Text[30])
        {
            Caption = 'Phone';
            DataClassification = CustomerContent;
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
        key(PK; Id)
        {
            Clustered = true;
        }
    }

    internal procedure IncludeVATAmount(): Boolean
    begin
        CalcFields("Country/Region ISO Code");
        if "Country/Region ISO Code" <> '' then
            exit("Country/Region ISO Code" = 'NL');
        exit("Country/Region Code" in ['NL', 'NLD']);
    end;
}