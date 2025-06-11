codeunit 11155289 "IDYM HTTP Helper"
{
    procedure Authenticate(EndpointService: Enum "IDYM Endpoint Service"; EndpointUsage: Enum "IDYM Endpoint Usage"): Boolean
    var
        Endpoint: Record "IDYM Endpoint";
        BearerToken: Text;
        ExpiryDuration: Integer;
    begin
        Endpoint.Get(EndpointService, EndpointUsage);
        case Endpoint."Authorization Type" of
            "IDYM Authorization Type"::Bearer:
                begin
                    if Endpoint.BearerTokenHasExpired() then begin
                        BearerToken := GetBearerTokenWithRefresh(EndPoint, ExpiryDuration);
                        Endpoint.SetBearerToken(BearerToken, ExpiryDuration);
                    end;
                    exit(Endpoint.HasBearerToken());
                end;
        end;
    end;

    procedure Authenticate(EndpointService: Enum "IDYM Endpoint Service"; EndpointUsage: Enum "IDYM Endpoint Usage"; EndpointSubType: Enum "IDYM Endpoint Sub Type"; SubNo: Code[50]): Boolean
    var
        Endpoint: Record "IDYM Endpoint";
        EndpointSubSetting: Record "IDYM Endpoint Sub Setting";
        BearerToken: Text;
        ExpiryDuration: Integer;
    begin
        Endpoint.Get(EndpointService, EndpointUsage);
        EndpointSubSetting.Get(EndpointService, EndpointUsage, EndpointSubType, SubNo);
        case Endpoint."Authorization Type" of
            "IDYM Authorization Type"::Bearer:
                begin
                    if EndpointSubSetting.BearerTokenHasExpired() then begin
                        BearerToken := GetBearerTokenWithRefresh(EndpointSubSetting, ExpiryDuration);
                        EndpointSubSetting.SetBearerToken(BearerToken, ExpiryDuration);
                    end;
                    exit(EndpointSubSetting.HasBearerToken());
                end;
        end;
    end;

    procedure Execute(var RESTParameters: Record "IDYM REST Parameters" temporary; EndpointService: Enum "IDYM Endpoint Service"; EndpointUsage: Enum "IDYM Endpoint Usage") StatusCode: Integer
    var
        Endpoint: Record "IDYM Endpoint";
        EndpointSubSetting: Record "IDYM Endpoint Sub Setting";
        Base64Convert: Codeunit "Base64 Convert";
        IDYMHttpClient: HttpClient;
        IDYMHttpHeaders: HttpHeaders;
        IDYMHttpRequestMessage: HttpRequestMessage;
        IDYMHttpResponseMessage: HttpResponseMessage;
        IDYMHttpContent: HttpContent;
        ContentHttpHeaders: HttpHeaders;
        BearerToken: Text;
        HttpClientCertificate: Text;
        ExpiryDuration: Integer;
        //ErrorMsg: Text;
        //ErrorCode: Integer;
        BasicTxt: Label 'Basic %1', Locked = true;
        BearerTxt: Label 'Bearer %1', Locked = true;
        UserPasswordTxt: Label '%1:%2', Locked = true;
    begin
        Endpoint.Get(EndpointService, EndpointUsage);
        SetRequestMethod(RESTParameters, IDYMHttpRequestMessage);

        if RESTParameters."Acceptance Environment" then begin
            Endpoint.TestField("Acceptance Url");
            IDYMHttpRequestMessage.SetRequestUri(CreateUri(Endpoint."Acceptance Url", RESTParameters.Path))
        end else begin
            Endpoint.TestField(Url);
            IDYMHttpRequestMessage.SetRequestUri(CreateUri(Endpoint.Url, RESTParameters.Path));
        end;
        IDYMHttpRequestMessage.GetHeaders(IDYMHttpHeaders);

        if RESTParameters."Sub No." <> '' then begin
            EndpointSubSetting.Get(EndpointService, EndpointUsage, RESTParameters."Sub Type", RESTParameters."Sub No.");
            case Endpoint."Authorization Type" of
                "IDYM Authorization Type"::Basic:
                    IDYMHttpHeaders.Add('Authorization', StrSubstNo(BasicTxt, Base64Convert.ToBase64(StrSubstNo(UserPasswordTxt, EndpointSubSetting."API Key Name", EndpointSubSetting.GetApiKeyValue()))));
                "IDYM Authorization Type"::Bearer:
                    begin
                        if not EndpointSubSetting.HasBearerToken() or EndpointSubSetting.BearerTokenHasExpired() then begin
                            BearerToken := GetBearerTokenWithRefresh(EndpointSubSetting, ExpiryDuration);
                            EndpointSubSetting.SetBearerToken(BearerToken, ExpiryDuration);
                        end;
                        IDYMHttpHeaders.Add('Authorization', StrSubstNo(BearerTxt, EndpointSubSetting.GetBearerToken()));
                    end;
                "IDYM Authorization Type"::ApiKey:
                    if Endpoint."API Key in Header" then begin
                        if not EndpointSubSetting.HasApiKeyValue() then
                            EndpointSubSetting.FieldError("API Key Value STID", APIKeyValueNotFoundErr);
                        IDYMHttpHeaders.Add(EndpointSubSetting."API Key Name", EndpointSubSetting.GetApiKeyValue());
                    end;
            end;
        end else
            case Endpoint."Authorization Type" of
                "IDYM Authorization Type"::Basic:
                    IDYMHttpHeaders.Add('Authorization', StrSubstNo(BasicTxt, Base64Convert.ToBase64(StrSubstNo(UserPasswordTxt, Endpoint."API Key Name", Endpoint.GetApiKeyValue()))));
                "IDYM Authorization Type"::Bearer:
                    begin
                        if not EndPoint.HasBearerToken() or EndPoint.BearerTokenHasExpired() then begin
                            BearerToken := GetBearerTokenWithRefresh(EndPoint, ExpiryDuration);
                            Endpoint.SetBearerToken(BearerToken, ExpiryDuration);
                        end;
                        IDYMHttpHeaders.Add('Authorization', StrSubstNo(BearerTxt, Endpoint.GetBearerToken()));
                    end;
                "IDYM Authorization Type"::ApiKey:
                    if Endpoint."API Key in Header" then begin
                        if not Endpoint.HasApiKeyValue() then
                            Endpoint.FieldError("API Key Value STID", APIKeyValueNotFoundErr);
                        IDYMHttpHeaders.Add(Endpoint."API Key Name", Endpoint.GetApiKeyValue());
                    end;
            end;

        if RESTParameters.Accept <> '' then
            IDYMHttpHeaders.Add('Accept', RESTParameters.Accept);

        //NOTE: Could be used to populate RequestHttpHeaderValues from child apps
        // Check commit details
        RESTParameters.GetAdditionalRequestHttpHeaders(RequestHttpHeaderValues);
        foreach RequestHttpHeaderName in RequestHttpHeaderValues.Keys() do begin
            RequestHttpHeaderValues.Get(RequestHttpHeaderName, RequestHttpHeaderValue);
            IDYMHttpHeaders.Add(RequestHttpHeaderName, RequestHttpHeaderValue);
        end;

        if Endpoint.Service = Endpoint.Service::Sendcloud then
            IDYMHttpHeaders.Add('Sendcloud-Partner-Id', GetSendcloudPartnerId());

        if RESTParameters.HasRequestContent() then
            RESTParameters.GetRequestContent(IDYMHttpContent);
        if RESTParameters.HasRequestContent() or (RESTParameters."Content-Type" <> '') then begin
            IDYMHttpContent.GetHeaders(ContentHttpHeaders);
            if ContentHttpHeaders.Contains('Content-Type') then
                ContentHttpHeaders.Remove('Content-Type');
            if RESTParameters."Content-Type" <> '' then
                ContentHttpHeaders.Add('Content-Type', RESTParameters."Content-Type")
            else
                ContentHttpHeaders.Add('Content-Type', 'application/json');
            IDYMHttpRequestMessage.Content := IDYMHttpContent;
        end;

        HttpClientCertificate := RESTParameters.GetHttpClientCertificate();
        if HttpClientCertificate <> '' then
            IDYMHttpClient.AddCertificate(HttpClientCertificate);

        if not IDYMHttpClient.Send(IDYMHttpRequestMessage, IDYMHttpResponseMessage) then
            // TODO: Generic error message / error handling, extra parameter to allow error message
            // Error Handling on error codes
            ;
        IDYMHttpHeaders := IDYMHttpResponseMessage.Headers();
        RESTParameters.SetResponseHeaders(IDYMHttpHeaders);
        IDYMHttpContent := IDYMHttpResponseMessage.Content();
        RESTParameters.SetResponseContent(IDYMHttpContent);

        RESTParameters."Status Code" := IDYMHttpResponseMessage.HttpStatusCode;
        exit(IDYMHttpResponseMessage.HttpStatusCode);
    end;

    local procedure CreateUri(BaseUrl: Text; Path: Text): Text
    begin
        Path := Path.Replace('{', '');
        Path := Path.Replace('}', '');
        if Path.Contains('http://') or Path.Contains('https://') then
            exit(Path);
        if BaseUrl.EndsWith('/') then
            BaseUrl := BaseUrl.TrimEnd('/');
        if (Path <> '') and not Path.StartsWith('?') and not Path.StartsWith('/') then
            Path := '/' + Path;
        exit(BaseUrl + Path);
    end;

    internal procedure SetRequestMethod(var RESTParameters: Record "IDYM REST Parameters" temporary; var IDYMHttpRequestMessage: HttpRequestMessage)
    var
    begin
        case RESTParameters.RestMethod of
            RESTParameters.RestMethod::GET:
                IDYMHttpRequestMessage.Method := 'GET';
            RESTParameters.RestMethod::PATCH:
                IDYMHttpRequestMessage.Method := 'PATCH';
            RESTParameters.RestMethod::DELETE:
                IDYMHttpRequestMessage.Method := 'DELETE';
            RESTParameters.RestMethod::POST:
                IDYMHttpRequestMessage.Method := 'POST';
            RESTParameters.RestMethod::PUT:
                IDYMHttpRequestMessage.Method := 'PUT';
        end;
    end;

    [Obsolete('Replaced with GetBearerTokenWithRefresh')]
    internal procedure GetBearerToken(Endpoint: Record "IDYM Endpoint"; var ExpiryInMS: Integer) BearerToken: Text
    var
        OldRefreshToken: Text;
        RefreshToken: Text;
    begin
        if Endpoint.HasRefreshToken() then
            RefreshToken := Endpoint.GetRefreshToken();
        OldRefreshToken := RefreshToken;
        OnGetBearerToken(Endpoint, BearerToken, RefreshToken, ExpiryInMS);
    end;

    internal procedure GetBearerTokenWithRefresh(var Endpoint: Record "IDYM Endpoint"; var ExpiryInMS: Integer) BearerToken: Text
    var
        OldRefreshToken: Text;
        RefreshToken: Text;
    begin
        if Endpoint.HasRefreshToken() then
            RefreshToken := Endpoint.GetRefreshToken();
        OldRefreshToken := RefreshToken;
        OnGetBearerToken(Endpoint, BearerToken, RefreshToken, ExpiryInMS);
        if (RefreshToken <> '') and (RefreshToken <> OldRefreshToken) then
            Endpoint.SetRefreshToken(RefreshToken);
    end;

    internal procedure GetBearerToken(EndpointSubSetting: Record "IDYM Endpoint Sub Setting"; var ExpiryInMS: Integer) BearerToken: Text
    var
        OldRefreshToken: Text;
        RefreshToken: Text;
    begin
        if EndpointSubSetting.HasRefreshToken() then
            RefreshToken := EndpointSubSetting.GetRefreshToken();
        OldRefreshToken := RefreshToken;
        OnGetSubBearerToken(EndpointSubSetting, BearerToken, RefreshToken, ExpiryInMS);
        if (RefreshToken <> '') and (RefreshToken <> OldRefreshToken) then
            EndpointSubSetting.SetRefreshToken(RefreshToken);
    end;

    internal procedure GetBearerTokenWithRefresh(var EndpointSubSetting: Record "IDYM Endpoint Sub Setting"; var ExpiryInMS: Integer) BearerToken: Text
    var
        OldRefreshToken: Text;
        RefreshToken: Text;
    begin
        if EndpointSubSetting.HasRefreshToken() then
            RefreshToken := EndpointSubSetting.GetRefreshToken();
        OldRefreshToken := RefreshToken;
        OnGetSubBearerToken(EndpointSubSetting, BearerToken, RefreshToken, ExpiryInMS);
        if (RefreshToken <> '') and (RefreshToken <> OldRefreshToken) then
            EndpointSubSetting.SetRefreshToken(RefreshToken);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBearerToken(Endpoint: Record "IDYM Endpoint"; var BearerToken: Text; var RefreshToken: Text; var ExpiryInMS: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSubBearerToken(EndpointSubSetting: Record "IDYM Endpoint Sub Setting"; var BearerToken: Text; var RefreshToken: Text; var ExpiryInMS: Integer)
    begin
    end;

    #region [Parse Error]
    internal procedure ParseError(RESTParameters: Record "IDYM REST Parameters"; var ErrorCode: Integer; var ErrorMessage: Text; ThrowError: Boolean)
    var
        IDYMJSONHelper: Codeunit "IDYM JSON Helper";
        ErrorObject: JsonToken;
        UnknownErr: Label 'An unknown error occured.';
    begin
        if not TryGetResponseObject(RESTParameters, ErrorObject) or not ErrorObject.IsObject() then
            ErrorMessage := RESTParameters.GetResponseBodyAsString();
        if (ErrorMessage = '') and ErrorObject.IsObject then
            if not ErrorObject.AsObject().Contains('errorCode') then
                ErrorMessage := RESTParameters.GetResponseBodyAsString();

        if (ErrorMessage = '') and ErrorObject.IsObject then
            ErrorCode := IDYMJSONHelper.GetIntegerValue(ErrorObject.AsObject(), 'errorCode');

        if ErrorMessage = '' then
            ErrorMessage := UnknownErr;

        if ThrowError then
            Error(ErrorMessage);
    end;

    [NonDebuggable]
    local procedure GetSendcloudPartnerId(): Guid;
    begin
        exit('65972e97-1ec2-4f27-b095-5cab9dccbf9e');
    end;

    [TryFunction]
    local procedure TryGetResponseObject(RestParameters: Record "IDYM REST Parameters"; var ErrorObject: JsonToken)
    begin
        ErrorObject := RestParameters.GetResponseBodyAsJSON();
    end;
    #endregion

    var
        APIKeyValueNotFoundErr: Label 'The key value cannot be found in the Isolated Storage. This is probably caused by a copy company. Please reset the credentials for the integration.', Comment = '%1 = fieldname API Key Value';
        RequestHttpHeaderValues: Dictionary of [Text, Text];
        RequestHttpHeaderName: Text;
        RequestHttpHeaderValue: Text;
}
