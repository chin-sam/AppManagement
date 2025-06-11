table 11155289 "IDYM App License Key"
{
    Caption = 'IDYM App License Key';
    DataClassification = CustomerContent;
    Access = Internal;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; "App Id"; Guid)
        {
            Caption = 'App Id';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                ModuleInfo: ModuleInfo;
            begin
                if not IsNullGuid("App ID") then begin
                    if NavApp.GetModuleInfo("App ID", ModuleInfo) then
                        Validate("App Name", CopyStr(ModuleInfo.Name, 1, MaxStrLen("App Name")))
                end else
                    Clear("App Name");
            end;
        }
        field(3; "Property Key"; Text[100])
        {
            Caption = 'Property Key';
            DataClassification = CustomerContent;
            Access = Internal;
        }
        field(4; "Property Value"; Text[100])
        {
            Caption = 'Property Value';
            DataClassification = EndUserIdentifiableInformation;
            Access = Internal;
        }
        field(10; "License Key"; Text[50])
        {
            Caption = 'License Key';
            DataClassification = CustomerContent;
            Access = Internal;

            trigger OnValidate()
            begin
                if "License Key" <> '' then
                    Validate("Requested On", CurrentDateTime)
                else
                    Clear("Requested On");
            end;
        }
        field(11; "Requested On"; DateTime)
        {
            Caption = 'Requested On';
            DataClassification = CustomerContent;
        }
        field(12; "Resume License Check On"; DateTime)
        {
            Caption = 'Resume Licence Check On';
            DataClassification = CustomerContent;
            Access = Internal;
        }
        field(13; "License Grace Period Start"; DateTime)
        {
            Caption = 'License Check Grace Period (Start)';
            DataClassification = SystemMetadata;
            Access = Internal;
        }
        field(20; "Parent App Entry No."; Integer)
        {
            Caption = 'Parent App Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "IDYM App License Key"."Entry No.";
            Access = Internal;
        }
        field(21; "Licensed App Id"; Guid)
        {
            Caption = 'Licensed App Id';
            DataClassification = CustomerContent;
        }
        field(50; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            DataClassification = SystemMetadata;
            Access = Internal;
        }
        #region Payment Status
        field(60; "Payment Status"; Enum "IDYM Payment Status")
        {
            Access = Internal;
            DataClassification = SystemMetadata;
            Caption = 'Payment Status';
            Editable = false;
        }
        field(61; "Payment Provider"; Enum "IDYM Payment Provider")
        {
            Access = Internal;
            DataClassification = SystemMetadata;
            Caption = 'Payment Provider';
            Editable = false;
        }
        field(62; "Payment Id"; Text[100])
        {
            Access = Internal;
            DataClassification = SystemMetadata;
            Caption = 'Payment Id';
            Editable = false;
        }
        field(11135104; "Order Id"; Text[100])
        {
            Access = Internal;
            DataClassification = CustomerContent;
            Caption = 'Order Id';
            Editable = false;
        }
        #endregion
        field(100; "App Name"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'App Name';
            Editable = false;
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Key1; "License Key")
        {
        }
        key(Key2; "App Id", "Property Key", "Property Value")
        {
        }
    }
}