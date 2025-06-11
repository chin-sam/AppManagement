table 11155291 "IDYM Endpoint"
{
    Caption = 'Endpoint';
    DataClassification = CustomerContent;
    Access = Internal;

    fields
    {
        field(1; Service; Enum "IDYM Endpoint Service")
        {
            Caption = 'Service';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                AppHubUrlTxt: Label 'https://apphub-v2.azurewebsites.net/api/v2', Locked = true; //https://apphub-v2-test.azurewebsites.net/api/v2
                IdynFunctionsTxt: Label 'http://idynfunctions.azurewebsites.net/api', Locked = true;
                IdynAnalyticsTxt: Label 'https://idyn-analytics.azurewebsites.net/api', Locked = true;
                SendcloudUrlTxt: Label 'https://panel.sendcloud.sc/api/v2', Locked = true;
                TranssmartUrlTxt: Label 'https://api.transsmart.com', Locked = true;
                TranssmartAcceptanceUrlTxt: Label 'https://accept-api.transsmart.com', Locked = true;
                GoogleGeoCodeUrlTxt: Label 'https://maps.googleapis.com/maps/api/geocode/json', Locked = true;
                PayPalUrlTxt: Label 'https://api.paypal.com', Locked = true;
                PayPalAcceptanceUrlTxt: Label 'https://api-m.sandbox.paypal.com', Locked = true;
                PontoUrlTxt: Label 'https://api.myponto.com', Locked = true;
                CobaseUrlTxt: Label 'https://api.cobase.com/api/v1', Locked = true;
                CobaseAcceptanceUrlTxt: Label 'https://api-sandbox.cobase.com/api/v1', Locked = true;
                DeliveryHubUrlTxt: Label 'https://restapi.shipmentserver.com', Locked = true;
                DeliveryHubAcceptanceUrlTxt: Label 'https://demo.shipmentserver.com:8080', Locked = true;
                DeliveryHubDataUrlTxt: Label 'https://customer-api.consignorportal.com/ApiGateway/shipmentdata/operational', Locked = true;
                DeliveryHubDataAcceptanceUrlTxt: Label 'https://customer-api.consignorportal.com/ApiGateway/shipmentdata/operational', Locked = true;
                DocuSignUrlTxt: Label 'https://eu.docusign.net', Locked = true;
                DocuSignAcceptanceUrlTxt: Label 'https://demo.docusign.net', Locked = true;
                SignhostUrlTxt: Label 'https://api.signhost.com/api', Locked = true;
                EasyPostUrlTxt: Label 'https://api.easypost.com/v2', Locked = true;
                StripeUrlTxt: Label 'https://api.stripe.com/v1/', Locked = true;
                PrintNodeUrlTxt: Label 'https://api.printnode.com/', Locked = true;
                CargosonAcceptanceUrlTxt: Label 'https://cargoson-staging.herokuapp.com/api/', Locked = true;
                CargosonUrlTxt: Label 'https://www.cargoson.com/api/', Locked = true;
            begin
                case Service of
                    Service::Apphub:
                        Validate(Url, AppHubUrlTxt);
                    Service::IdynFunctions:
                        Validate(Url, IdynFunctionsTxt);
                    Service::IdynAnalytics:
                        Validate(Url, IdynAnalyticsTxt);
                    Service::Sendcloud:
                        Validate(Url, SendcloudUrlTxt);
                    Service::GoogleGeocode:
                        Validate(Url, GoogleGeoCodeUrlTxt);
                    Service::Transsmart:
                        begin
                            Validate(Url, TranssmartUrlTxt);
                            Validate("Acceptance Url", TranssmartAcceptanceUrlTxt);
                        end;
                    Service::DeliveryHub:
                        begin
                            Validate(Url, DeliveryHubUrlTxt);
                            Validate("Acceptance Url", DeliveryHubAcceptanceUrlTxt);
                        end;
                    Service::DeliveryHubData:
                        begin
                            Validate(Url, DeliveryHubDataUrlTxt);
                            Validate("Acceptance Url", DeliveryHubDataAcceptanceUrlTxt);
                        end;
                    Service::Paypal:
                        begin
                            Validate(Url, PayPalUrlTxt);
                            Validate("Acceptance Url", PayPalAcceptanceUrlTxt);
                        end;
                    Service::Ponto:
                        begin
                            Validate(Url, PontoUrlTxt);
                            Clear("Acceptance Url");
                        end;
                    Service::Cobase:
                        begin
                            Validate(Url, CobaseUrlTxt);
                            Validate("Acceptance Url", CobaseAcceptanceUrlTxt)
                        end;
                    Service::Docusign:
                        begin
                            Validate(Url, DocuSignUrlTxt);
                            Validate("Acceptance Url", DocuSignAcceptanceUrlTxt);
                        end;
                    Service::EasyPost:
                        begin
                            Validate(Url, EasyPostUrlTxt);
                            Validate("Acceptance Url", EasyPostUrlTxt);
                        end;
                    Service::Stripe:
                        begin
                            Validate(Url, StripeUrlTxt);
                            Validate("Acceptance Url", StripeUrlTxt);
                        end;
                    Service::PrintNode:
                        Validate(Url, PrintNodeUrlTxt);
                    Service::Cargoson:
                        begin
                            Validate(Url, CargosonUrlTxt);
                            Validate("Acceptance Url", CargosonAcceptanceUrlTxt);
                        end;
                    Service::Signhost:
                        begin
                            Validate(Url, SignhostUrlTxt);
                            Validate("Acceptance Url", SignhostUrlTxt);
                        end;
                end;
            end;
        }
        field(2; Usage; Enum "IDYM Endpoint Usage")
        {
            Caption = 'Usage';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                DeliveryHubUrlTxt: Label 'https://www.consignorportal.com/idsrv/connect/token', Locked = true;
                DocuSignAccountUrlTxt: Label 'https://account.docusign.com', Locked = true;
                DocuSignAccountAcceptanceUrlTxt: Label 'https://account-d.docusign.com', Locked = true;
            begin
                if (Service = Service::IdynFunctions) and (Usage = Usage::MD5Hash) then begin
                    TestField(Url);
                    if StrPos(Url, '/MD5Hash') = 0 then
                        Validate(Url, Url + '/MD5Hash');
                end;
                if (Service = Service::Paypal) and (Usage = Usage::GetToken) then begin
                    TestField(Url);
                    if StrPos(Url, '/v1/oauth2/token?grant_type=client_credentials') = 0 then
                        Validate(Url, Url + '/v1/oauth2/token?grant_type=client_credentials');
                    TestField("Acceptance Url");
                    if StrPos("Acceptance Url", '/v1/oauth2/token?grant_type=client_credentials') = 0 then
                        Validate("Acceptance Url", "Acceptance Url" + '/v1/oauth2/token?grant_type=client_credentials');
                end;
                if (Service = Service::Transsmart) and (Usage = Usage::GetToken) then begin
                    TestField(Url);
                    if StrPos(Url, '/login') = 0 then
                        Validate(Url, Url + '/login');
                    TestField("Acceptance Url");
                    if StrPos("Acceptance Url", '/login') = 0 then
                        Validate("Acceptance Url", "Acceptance Url" + '/login');
                end;
                if (Service in [Service::DeliveryHub, Service::DeliveryHubData]) and (Usage = Usage::GetToken) then begin
                    Validate(Url, DeliveryHubUrlTxt);
                    Validate("Acceptance Url", DeliveryHubUrlTxt);
                end;
                if (Service = Service::Sendcloud) and (Usage = Usage::GetToken) then begin
                    TestField(Url);
                    if StrPos(Url, '/oauth/token') = 0 then
                        Validate(Url, Url + '/oauth/token');
                    TestField("Acceptance Url");
                    if StrPos("Acceptance Url", '/oauth/token') = 0 then
                        Validate("Acceptance Url", "Acceptance Url" + '/oauth/token');
                end;
                if (Service = Service::Docusign) and (Usage = Usage::GetToken) then begin
                    Validate(Url, DocuSignAccountUrlTxt);
                    Validate("Acceptance Url", DocuSignAccountAcceptanceUrlTxt);
                end;
            end;
        }
        field(3; Url; Text[2048])
        {
            Caption = 'Url';
            DataClassification = CustomerContent;
        }
        field(4; "Acceptance Url"; Text[2048])
        {
            Caption = 'Acceptance Url';
            DataClassification = CustomerContent;
        }
        field(5; "App Id"; Guid)
        {
            Caption = 'App Id';
            DataClassification = CustomerContent;
        }
        field(6; "Authorization Type"; Enum "IDYM Authorization Type")
        {
            Caption = 'Authorization Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Authorization Type" <> "Authorization Type"::ApiKey then
                    Validate("API Key in Header", false);
            end;
        }
        field(10; "API Key Name"; Text[150])
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
        field(12; "API Key in Header"; Boolean)
        {
            Caption = 'API Key Value';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "API Key in Header" then
                    TestField("Authorization Type", "Authorization Type"::ApiKey);
            end;
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
        field(23; "Without Expiration"; Boolean) // to avoid data upgrade
        {
            Caption = 'Without Expiration';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK; Service, Usage)
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
        BearerEndpoint: Record "IDYM Endpoint";
        ModifyRecord: Boolean;
    begin
        ModifyRecord := IsNullGuid("API Key Value STID") or ("API Key Name" <> '');
        if not IsNullGuid("API Key Value STID") then begin
            if IsolatedStorage.Delete("API Key Value STID", DataScope::Company) then;
            Clear("API Key Value STID");
        end;
        Clear("Expiry Date/Time");
        Clear("Without Expiration");
        Clear("Bearer Token STID");
        Clear("Refresh Token STID");
        if "API Key Name" <> '' then
            Validate("API Key Name", '');
        if ModifyRecord then
            Modify();
        if Usage = Usage::GetToken then begin
            BearerEndpoint.SetRange(Service, Service);
            BearerEndpoint.SetRange("Authorization Type", BearerEndpoint."Authorization Type"::Bearer);
            if BearerEndpoint.FindSet() then
                repeat
                    BearerEndpoint.ResetCredentials();
                until BearerEndpoint.Next() = 0;
        end;
    end;
    #endregion

    #region [BearerToken]
    [NonDebuggable]
    internal procedure BearerTokenHasExpired(): Boolean
    begin
        if "Without Expiration" then
            exit(false);

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
        ModifyRecord := IsNullGuid("Bearer Token STID") or IsNullGuid("Refresh Token STID");
        if not IsNullGuid("Bearer Token STID") then begin
            if IsolatedStorage.Delete("Bearer Token STID", DataScope::Company) then;
            Clear("Bearer Token STID");
            Clear("Expiry Date/Time");
            Clear("Without Expiration");
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
}