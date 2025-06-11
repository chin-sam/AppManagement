table 11155293 "IDYM Endpoint Sub Setting"
{
    Caption = 'Endpoint Sub Setting';
    DataClassification = CustomerContent;
    Access = Internal;

    fields
    {
        field(1; Service; Enum "IDYM Endpoint Service")
        {
            Caption = 'Service';
            DataClassification = CustomerContent;
            TableRelation = "IDYM Endpoint".Service;
            NotBlank = true;
        }
        field(2; Usage; Enum "IDYM Endpoint Usage")
        {
            Caption = 'Usage';
            DataClassification = CustomerContent;
            TableRelation = "IDYM Endpoint".Usage where(Service = field(Service));
            NotBlank = true;
        }
        field(3; Type; Enum "IDYM Endpoint Sub Type")
        {
            Caption = 'Endpoint Sub Type';
            DataClassification = CustomerContent;
        }
        field(4; "No."; Code[50])
        {
            Caption = 'Endpoint Sub No.';
            DataClassification = CustomerContent;
            TableRelation = if (Type = const(Username)) User."User Name";
            ValidateTableRelation = false;
        }
        field(10; "API Key Name"; Text[100])
        {
            Caption = 'API Key Name';
            DataClassification = CustomerContent;
        }
        field(11; "API Key Value STID"; Guid)
        {
            Caption = 'API Key Value';
            DataClassification = CustomerContent;
            ExtendedDatatype = Masked;
        }
        field(20; "Bearer Token STID"; Guid)
        {
            Caption = 'Bearer Token';
            DataClassification = CustomerContent;
            ExtendedDatatype = Masked;
        }
        field(21; "Refresh Token STID"; Guid)
        {
            Caption = 'Refresh Token';
            DataClassification = CustomerContent;
            ExtendedDatatype = Masked;
        }
        field(22; "Expiry Date/Time"; DateTime)
        {
            Caption = 'Expiry Date/Time';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK; Service, Usage, Type, "No.")
        {
            Clustered = true;
        }
    }

    #region [ApiKey]
    [NonDebuggable]
    internal procedure HasApiKeyValue(): Boolean
    var
        UnusedReturn: Text;
    begin
        if IsNullGuid("API Key Value STID") then
            exit(false);
        exit(IsolatedStorage.Get("API Key Value STID", Datascope::Company, UnusedReturn)); //Guid can be stored in setup, but IsolatedStorage data doesn't exist
    end;

    [NonDebuggable]
    internal procedure SetApiKeyValue(Password: Text)
    begin
        if IsNullGuid("API Key Value STID") then begin
            "API Key Value STID" := CreateGuid();
            Modify();
        end;
        if EncryptionEnabled() and EncryptionKeyExists() and (StrLen(Password) <= 215) then
            IsolatedStorage.SetEncrypted("API Key Value STID", Password, Datascope::Company)
        else
            IsolatedStorage.Set("API Key Value STID", Password, Datascope::Company);
    end;

    [NonDebuggable]
    internal procedure GetApiKeyValue(): Text
    var
        Password: Text;
    begin
        TestField("API Key Value STID");
        IsolatedStorage.Get("API Key Value STID", Datascope::Company, Password);
        exit(Password);
    end;

    internal procedure ResetCredentials()
    var
        ModifyRecord: Boolean;
    begin
        ModifyRecord := IsNullGuid("API Key Value STID") or ("API Key Name" <> '');
        if not IsNullGuid("API Key Value STID") then begin
            if IsolatedStorage.Delete("API Key Value STID", DataScope::Company) then;
            Clear("API Key Value STID");
            Clear("Expiry Date/Time");
        end;
        if "API Key Name" <> '' then
            Validate("API Key Name", '');
        if ModifyRecord then
            Modify();
    end;
    #endregion

    #region [BearerToken]
    [NonDebuggable]
    internal procedure BearerTokenHasExpired(): Boolean
    begin
        if "Expiry Date/Time" = 0DT then
            exit(true);

        exit(GetCurrentDateTimeInUTC() + 2000 > "Expiry Date/Time");
    end;

    [NonDebuggable]
    internal procedure HasBearerToken(): Boolean
    var
        UnusedReturn: Text;
    begin
        if IsNullGuid("Bearer Token STID") then
            exit(false);
        exit(IsolatedStorage.Get("Bearer Token STID", Datascope::Company, UnusedReturn)); //Guid can be stored in setup, but IsolatedStorage data doesn't exist
    end;

    [NonDebuggable]
    internal procedure SetBearerToken(BearerToken: Text; BearerTokenValidityDuration: Integer)
    begin
        if IsNullGuid("Bearer Token STID") then
            "Bearer Token STID" := CreateGuid();

        if EncryptionEnabled() and EncryptionKeyExists() and (StrLen(BearerToken) <= 215) then
            IsolatedStorage.SetEncrypted("Bearer Token STID", BearerToken, Datascope::Company)
        else
            IsolatedStorage.Set("Bearer Token STID", BearerToken, Datascope::Company);
        "Expiry Date/Time" := GetCurrentDateTimeInUTC() + (BearerTokenValidityDuration * 1000);
        Modify();
    end;

    [NonDebuggable]
    internal procedure GetBearerToken(): Text
    var
        BearerToken: Text;
    begin
        TestField("Bearer Token STID");
        IsolatedStorage.Get("Bearer Token STID", Datascope::Company, BearerToken);
        exit(BearerToken);
    end;

    internal procedure ResetBearerToken()
    var
        ModifyRecord: Boolean;
    begin
        ModifyRecord := not IsNullGuid("Bearer Token STID") or not IsNullGuid("Refresh Token STID");
        if not IsNullGuid("Bearer Token STID") then begin
            if IsolatedStorage.Delete("Bearer Token STID", DataScope::Company) then;
            Clear("Bearer Token STID");
            Clear("Expiry Date/Time");
        end;
        if not IsNullGuid("Refresh Token STID") then begin
            if IsolatedStorage.Delete("Refresh Token STID", DataScope::Company) then;
            Clear("Refresh Token STID");
        end;
        if ModifyRecord then
            Modify();
    end;

    local procedure GetCurrentDateTimeInUTC(): DateTime
    var
        TypeHelper: Codeunit "Type Helper";
        DateTimeUTCTxt: Text;
    begin
        DateTimeUTCTxt := TypeHelper.GetCurrUTCDateTimeAsText();
        exit(TypeHelper.EvaluateUTCDateTime(DateTimeUTCTxt));
    end;
    #endregion

    #region [RefreshToken]
    [NonDebuggable]
    internal procedure HasRefreshToken(): Boolean
    var
        UnusedReturn: Text;
    begin
        if IsNullGuid("Refresh Token STID") then
            exit(false);
        exit(IsolatedStorage.Get("Refresh Token STID", Datascope::Company, UnusedReturn)); //Guid can be stored in setup, but IsolatedStorage data doesn't exist
    end;

    [NonDebuggable]
    internal procedure SetRefreshToken(RefreshToken: Text)
    begin
        if IsNullGuid("Refresh Token STID") then
            "Refresh Token STID" := CreateGuid();
        if EncryptionEnabled() and EncryptionKeyExists() and (StrLen(RefreshToken) <= 215) then
            IsolatedStorage.SetEncrypted("Refresh Token STID", RefreshToken, Datascope::Company)
        else
            IsolatedStorage.Set("Refresh Token STID", RefreshToken, Datascope::Company);
    end;

    [NonDebuggable]
    internal procedure GetRefreshToken(): Text
    var
        RefreshToken: Text;
    begin
        TestField("Refresh Token STID");
        IsolatedStorage.Get("Refresh Token STID", Datascope::Company, RefreshToken);
        exit(RefreshToken);
    end;
    #endregion

    [NonDebuggable]
    internal procedure CopyTokenDataFromEndpointSubSetting(EndpointSubSetting: Record "IDYM Endpoint Sub Setting")
    var
        ModifyRecord: Boolean;
    begin
        if EndpointSubSetting.HasRefreshToken() then begin
            SetBearerToken(EndpointSubSetting.GetBearerToken(), 0);
            "Expiry Date/Time" := EndpointSubSetting."Expiry Date/Time";
            ModifyRecord := true;
        end;

        if EndpointSubSetting.HasRefreshToken() then begin
            SetRefreshToken(EndpointSubSetting.GetRefreshToken());
            ModifyRecord := true;
        end;

        if ModifyRecord then
            Modify();
    end;
}