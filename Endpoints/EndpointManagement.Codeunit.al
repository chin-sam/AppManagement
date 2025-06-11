codeunit 11155292 "IDYM Endpoint Management"
{
    Permissions = tabledata "IDYM Endpoint" = rimd;

    trigger OnRun()
    begin
    end;

    [NonDebuggable]
    internal procedure RegisterCredentials(Service: Enum "IDYM Endpoint Service"; Usage: Enum "IDYM Endpoint Usage"; AppId: Guid; AuthorizationType: Enum "IDYM Authorization Type"; BearerToken: Text; BearerTokenValidityDuration: Integer)
    begin
        // NOTE: User predefined API key which is used as a bearer token (Usage = Default, AuthorizationType = Bearer)
        if not (AuthorizationType in [AuthorizationType::Bearer]) then
            Error(InvalidAuthorizationTypeErr, AuthorizationType, Endpoint.FieldCaption("API Key Name"), Endpoint.FieldCaption("API Key Value STID"));
        if not Endpoint.Get(Service, Usage) then begin
            EndPoint.Init();
            Endpoint.Validate(Service, Service);
            Endpoint.Validate(Usage, Usage);
            Endpoint.Insert(true);
        end;
        EndPoint.Validate("App Id", Appid);
        Endpoint.Validate("Authorization Type", AuthorizationType);
        Endpoint.Validate("Without Expiration", (BearerTokenValidityDuration = 0));
        Endpoint.SetBearerToken(BearerToken, BearerTokenValidityDuration);
        Endpoint.Modify();
    end;

    [NonDebuggable]
    internal procedure RegisterCredentials(Service: Enum "IDYM Endpoint Service"; Usage: Enum "IDYM Endpoint Usage"; AppId: Guid; AuthorizationType: Enum "IDYM Authorization Type"; KeyName: Text[150]; KeyValue: Text)
    begin
        RegisterCredentials(Service, Usage, AppId, AuthorizationType, KeyName, KeyValue, false);
    end;

    [NonDebuggable]
    internal procedure RegisterCredentials(Service: Enum "IDYM Endpoint Service"; Usage: Enum "IDYM Endpoint Usage"; AppId: Guid; AuthorizationType: Enum "IDYM Authorization Type"; KeyName: Text[150]; KeyValue: Text; APIKeyInHeader: Boolean)
    var
        BearerEndpoint: Record "IDYM Endpoint";
    begin
        if not (AuthorizationType in [AuthorizationType::ApiKey, AuthorizationType::Basic, AuthorizationType::Anonymous]) then
            Error(InvalidAuthorizationTypeErr, AuthorizationType, Endpoint.FieldCaption("API Key Name"), Endpoint.FieldCaption("API Key Value STID"));
        if not Endpoint.Get(Service, Usage) then begin
            EndPoint.Init();
            Endpoint.Validate(Service, Service);
            Endpoint.Validate(Usage, Usage);
            Endpoint.Insert(true);
        end;
        EndPoint.Validate("App Id", Appid);
        Endpoint.Validate("Authorization Type", AuthorizationType);
        Endpoint.Validate("API Key Name", KeyName);
        Endpoint.Validate("API Key In Header", APIKeyInHeader);
        EndPoint.SetApiKeyValue(KeyValue);
        Endpoint.Modify();

        if Endpoint.Usage = Endpoint.Usage::GetToken then begin
            BearerEndpoint.SetRange(Service, Service);
            BearerEndpoint.SetRange("Authorization Type", BearerEndpoint."Authorization Type"::Bearer);
            if BearerEndpoint.FindSet() then
                repeat
                    BearerEndpoint.ResetCredentials();
                until BearerEndpoint.Next() = 0;
        end;
    end;

    [NonDebuggable]
    internal procedure RegisterCredentials(Service: Enum "IDYM Endpoint Service"; Usage: Enum "IDYM Endpoint Usage"; AppId: Guid; AuthorizationType: Enum "IDYM Authorization Type"; SubType: Enum "IDYM Endpoint Sub Type"; "Sub No.": Code[50]; KeyName: Text[100]; KeyValue: Text)
    var
        BearerEndpoint: Record "IDYM Endpoint";
        EndpointSubSetting: Record "IDYM Endpoint Sub Setting";
        BearerEndpointSubSetting: Record "IDYM Endpoint Sub Setting";
    begin
        if not (AuthorizationType in [AuthorizationType::ApiKey, AuthorizationType::Basic, AuthorizationType::Anonymous]) then
            Error(InvalidAuthorizationTypeErr, AuthorizationType, Endpoint.FieldCaption("API Key Name"), Endpoint.FieldCaption("API Key Value STID"));
        RegisterEndpoint(Service, Usage, AuthorizationType, AppId);
        if not EndpointSubSetting.Get(Service, Usage, SubType, "Sub No.") then begin
            EndpointSubSetting.Init();
            EndpointSubSetting.Validate(Service, Service);
            EndpointSubSetting.Validate(Usage, Usage);
            EndpointSubSetting.Validate(Type, SubType);
            EndpointSubSetting.Validate("No.", "Sub No.");
            EndpointSubSetting.Insert(true);
        end;
        EndpointSubSetting.Validate("API Key Name", KeyName);
        EndpointSubSetting.SetApiKeyValue(KeyValue);
        EndpointSubSetting.Modify();

        if EndpointSubSetting.Usage = EndpointSubSetting.Usage::GetToken then begin
            BearerEndpoint.SetRange(Service, Service);
            BearerEndpoint.SetRange("Authorization Type", BearerEndpoint."Authorization Type"::Bearer);
            if BearerEndpoint.FindSet() then
                repeat
                    if BearerEndpointSubSetting.Get(BearerEndpoint.Service, BearerEndpoint.Usage, SubType, "Sub No.") then
                        BearerEndpointSubSetting.ResetBearerToken();
                until BearerEndpoint.Next() = 0;
        end;
    end;

    [NonDebuggable]
    internal procedure RegisterEndpoint(Service: Enum "IDYM Endpoint Service"; Usage: Enum "IDYM Endpoint Usage"; AuthorizationType: Enum "IDYM Authorization Type"; AppId: Guid)
    begin
        if not Endpoint.Get(Service, Usage) then begin
            EndPoint.Init();
            Endpoint.Validate(Service, Service);
            Endpoint.Validate(Usage, Usage);
            Endpoint.Insert(true);
        end;
        EndPoint.Validate("App Id", Appid);
        Endpoint.Validate("Authorization Type", AuthorizationType);
        EndPoint.Modify();
    end;

    [NonDebuggable]
    internal procedure RegisterEndpoint(Service: Enum "IDYM Endpoint Service"; Usage: Enum "IDYM Endpoint Usage"; AuthorizationType: Enum "IDYM Authorization Type"; AppId: Guid; SubType: Enum "IDYM Endpoint Sub Type"; "Sub No.": Code[50])
    var
        EndpointSubSetting: Record "IDYM Endpoint Sub Setting";
    begin
        RegisterEndpoint(Service, Usage, AuthorizationType, AppId);
        if not EndpointSubSetting.Get(Service, Usage, SubType, "Sub No.") then begin
            EndpointSubSetting.Init();
            EndpointSubSetting.Validate(Service, Service);
            EndpointSubSetting.Validate(Usage, Usage);
            EndpointSubSetting.Validate(Type, SubType);
            EndpointSubSetting.Validate("No.", "Sub No.");
            EndpointSubSetting.Insert(true);
        end;
    end;

    internal procedure UpdateEndpointUrl(Service: Enum "IDYM Endpoint Service"; Usage: Enum "IDYM Endpoint Usage"; Url: Text)
    begin
        Endpoint.Get(Service, Usage);
        Endpoint.Validate(Url, Url);
        Endpoint.Modify();
    end;

    internal procedure ClearCredentials(Service: Enum "IDYM Endpoint Service"; Usage: Enum "IDYM Endpoint Usage")
    begin
        if Endpoint.Get(Service, Usage) then
            Endpoint.ResetCredentials();
    end;

    internal procedure ClearCredentials(Service: Enum "IDYM Endpoint Service"; Usage: Enum "IDYM Endpoint Usage"; SubType: Enum "IDYM Endpoint Sub Type"; "Sub No.": Code[50])
    var
        EndpointSubSetting: Record "IDYM Endpoint Sub Setting";
    begin
        if EndpointSubSetting.Get(Service, Usage, SubType, "Sub No.") then
            EndpointSubSetting.ResetCredentials();
    end;

    internal procedure RemoveCredentials(Service: Enum "IDYM Endpoint Service"; Usage: Enum "IDYM Endpoint Usage")
    begin
        if Endpoint.Get(Service, Usage) then
            Endpoint.Delete(true);
    end;

    internal procedure RemoveCredentials(Service: Enum "IDYM Endpoint Service"; Usage: Enum "IDYM Endpoint Usage"; SubType: Enum "IDYM Endpoint Sub Type"; "Sub No.": Code[50])
    var
        EndpointSubSetting: Record "IDYM Endpoint Sub Setting";
    begin
        if EndpointSubSetting.Get(Service, Usage, SubType, "Sub No.") then
            EndpointSubSetting.Delete(true);
    end;

    var
        Endpoint: Record "IDYM Endpoint";
        InvalidAuthorizationTypeErr: Label 'Authorization Type %1 cannot be used in combination with %2 or %3', Comment = '%1 = AuthorizationType, %2=Fieldcaption API Key Name, %3=Fieldcaption API Key Value';
}