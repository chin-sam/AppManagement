codeunit 11155290 "IDYM Apphub"
{
    Permissions = tabledata Company = r,
        tabledata "Company Information" = r,
        tabledata "IDYM App License Key" = rimd,
        tabledata "IDYM App Version Info" = rimd,
        tabledata "IDYM REST Parameters" = rimd;

    #region [App]
    internal procedure GetLicenseAppEntryNo(AppId: Guid; ParentAppId: Guid; UnitPrice: Decimal) EntryNo: Integer
    var
        AppLicenseKey: Record "IDYM App License Key";
        AppEntryNo: Integer;
    begin
        AppEntryNo := GetLicenseAppEntryNo(AppId, '');
        Clear(AppUserName);
        AppLicenseKey.Get(AppEntryNo);
        if not IsNullGuid(ParentAppId) then
            AppLicenseKey.Validate("Parent App Entry No.", GetLicenseAppEntryNo(ParentAppId));
        AppLicenseKey.Validate("Unit Price", UnitPrice);
        AppLicenseKey.Modify();
        exit(AppEntryNo);
    end;

    internal procedure GetLicenseAppEntryNo(AppId: Guid) EntryNo: Integer
    begin
        exit(GetLicenseAppEntryNo(AppId, ''));
    end;

    internal procedure GetLicenseAppEntryNo(AppId: Guid; NewLicenseKey: Text[50]) EntryNo: Integer
    var
        AppLicenseKey: Record "IDYM App License Key";
    begin
        AppLicenseKey.SetRange("App Id", AppId);
        if AppUserName <> '' then begin
            AppLicenseKey.SetRange("Property Key", 'username');
            AppLicenseKey.SetRange("Property Value", AppUserName);
        end else
            AppLicenseKey.SetRange("Property Key", '');
        if not AppLicenseKey.FindFirst() then begin
            AppLicenseKey.Init();
            AppLicenseKey.Validate("App Id", AppId);
            AppLicenseKey.Validate("License Key", NewLicenseKey);
            if AppUserName <> '' then begin
                AppLicenseKey.Validate("Property Key", 'username');
                AppLicenseKey.Validate("Property Value", AppUserName);
            end;
            AppLicenseKey.Insert();
        end else
            if NewLicenseKey <> '' then begin
                AppLicenseKey.Validate("License Key", NewLicenseKey);
                AppLicenseKey.Modify();
            end;
        NewLicenseRegistration := true;
        exit(AppLicenseKey."Entry No.");
    end;

    internal procedure EnableAppPerUser()
    var
        User: Record User;
    begin
        User.SetRange("User Security ID", UserSecurityId());
        User.FindFirst();
        if User."Full Name" <> '' then
            AppUserName := User."Full Name"
        else
            AppUserName := User."User Name";
    end;

    internal procedure SetUnregisteredAppName(AppName: Text[50])
    begin
        UnregisteredAppName := AppName;
    end;

    internal procedure RegisterApp(AppId: Guid; ParentAppId: Guid; PropertyKey: Text; PropertyValue: Text; var LicenseKey: Text[50]; var ErrorCode: Integer; var ErrorMessage: Text; ThrowError: Boolean): Boolean
    begin
        exit(RegisterApp(AppId, ParentAppId, '', PropertyKey, PropertyValue, LicenseKey, ErrorCode, ErrorMessage, ThrowError));
    end;

    internal procedure RegisterApp(AppId: Guid; ParentAppId: Guid; ParentLicenseKey: Text[50]; PropertyKey: Text; PropertyValue: Text; var LicenseKey: Text[50]; var ErrorCode: Integer; var ErrorMessage: Text; ThrowError: Boolean): Boolean
    var
        TempRESTParameters: Record "IDYM REST Parameters" temporary;
        ResponseToken: JsonToken;
    begin
        TempRESTParameters.Init();
        TempRESTParameters.RestMethod := TempRESTParameters.RestMethod::POST;
        TempRESTParameters.Path := AppUrlLbl;
        TempRESTParameters.SetRequestContent(SetRegisterAppRequestContent(AppId, ParentAppId, ParentLicenseKey, PropertyKey, PropertyValue));

        ErrorCode := ExecuteHubCall(TempRESTParameters);
        if ErrorCode <> 200 then begin
            ParseError(TempRESTParameters, ErrorCode, ErrorMessage, AppId, ThrowError);
            exit(false);
        end;
        ErrorCode := 0;
        ResponseToken := TempRESTParameters.GetResponseBodyAsJSON();
        LicenseKey := CopyStr(JSONHelper.GetTextValue(ResponseToken.AsObject(), 'licenseKey'), 1, MaxStrLen(LicenseKey));
        exit(LicenseKey <> '');
    end;

    internal procedure RegisterApp(AppId: Guid; ParentAppId: Guid; PropertyKey: Text; PropertyValue: Text; ThrowError: Boolean; PaymentID: Text; Amount: Decimal; var LicenseKey: Text[50]; var ErrorCode: Integer; var ErrorMessage: Text): Boolean
    var
        TempRESTParameters: Record "IDYM REST Parameters" temporary;
        ResponseToken: JsonToken;
        RequestJsonObject: JsonObject;
    begin
        TempRESTParameters.Init();
        TempRESTParameters.RestMethod := TempRESTParameters.RestMethod::POST;
        TempRESTParameters.Path := AppUrlLbl;
        RequestJsonObject := SetRegisterAppRequestContent(AppId, ParentAppId, '', PropertyKey, PropertyValue);
        AddPaymentInfo(RequestJsonObject, 'Paypal', PaymentID, Amount);
        TempRESTParameters.SetRequestContent(RequestJsonObject);

        ErrorCode := ExecuteHubCall(TempRESTParameters);
        if ErrorCode <> 200 then begin
            ParseError(TempRESTParameters, ErrorCode, ErrorMessage, AppId, ThrowError);
            exit(false);
        end;
        ErrorCode := 0;
        ResponseToken := TempRESTParameters.GetResponseBodyAsJSON();
        LicenseKey := CopyStr(JSONHelper.GetTextValue(ResponseToken.AsObject(), 'licenseKey'), 1, MaxStrLen(LicenseKey));
        exit(LicenseKey <> '');
    end;

    local procedure SetRegisterAppRequestContent(AppId: Guid; ParentAppId: Guid; ParentLicenseKey: Text[50]; PropertyKey: Text; PropertyValue: Text): JsonObject
    var
        AppInfo: ModuleInfo;
        AppObject: JsonObject;
        ParentAppObject: JsonObject;
        PropertyObject: JsonObject;
    begin
        JSONHelper.AddValue(AppObject, 'id', Format(AppId));
        if not NavApp.GetModuleInfo(AppId, AppInfo) then begin
            if UnregisteredAppName <> '' then
                JSONHelper.AddValue(AppObject, 'name', UnregisteredAppName);
            NavApp.GetCurrentModuleInfo(AppInfo);
        end else
            JSONHelper.AddValue(AppObject, 'name', AppInfo.Name());
        JSONHelper.AddValue(AppObject, 'publisher', AppInfo.Publisher());
        if not IsNullGuid(ParentAppId) then begin
            JSONHelper.AddValue(ParentAppObject, 'appId', ParentAppId);
            if ParentLicenseKey <> '' then
                JSONHelper.AddValue(ParentAppObject, 'licenseKey', ParentLicenseKey);
            JSONHelper.Add(AppObject, 'parentApp', ParentAppObject);
        end;
        JSONHelper.AddValue(PropertyObject, 'propertyKey', PropertyKey);
        JSONHelper.AddValue(PropertyObject, 'propertyValue', PropertyValue);
        JSONHelper.Add(AppObject, 'properties', PropertyObject);

        exit(AppObject);
    end;

    // //GetCallerModuleInfo() available for BC20 and up
    // internal procedure NewAppVersionNotification(ShowError: Boolean)
    // var
    //     AppInfo: ModuleInfo;
    // begin
    //     NavApp.GetCallerModuleInfo(AppInfo);
    //     NewAppVersionNotification(AppInfo.Id, ShowError);
    // end;

    internal procedure EnableAppPerUser(UserName: Text[100])
    begin
        AppUserName := UserName;
    end;

    internal procedure SetSkipLicenseCheck(DurationInMs: Integer)
    begin
        SkipLicenseCheckDuration := DurationInMs;
    end;

    internal procedure SetPostponeWriteTransactions()
    begin
        PostponeWriteTransactions := true;
    end;

    local procedure AddPaymentInfo(var RequestJsonObject: JsonObject; PaymentProvider: Text; PaymentID: Text; Amount: Decimal)
    var
        PaymentObject: JsonObject;
    begin
        JSONHelper.AddValue(PaymentObject, 'method', PaymentProvider);
        JSONHelper.AddValue(PaymentObject, 'id', PaymentID);
        JSONHelper.AddValue(PaymentObject, 'amount', Format(Amount, 0, 9));
        JSONHelper.Add(RequestJsonObject, 'payment', PaymentObject);
    end;
    #endregion

    #region [App Version]
    internal procedure NewAppVersionNotification(AppId: Guid; ShowError: Boolean)
    var
        OldestMajorSupported: Integer;
        ErrorMessage: Text;
        VersionString: Text;
        AppVersionNotificationMsg: Text;
        BcNotSupportedLbl: Label 'This Business Central version is not actively supported anymore for %1. No new major releases will be done for BC%2.', Comment = '%1 = App Name, %2 = BC Major';
        AppNotSupportedLbl: Label 'A new major release (%1.%2) is available for %3. This version (%4.%5) is no longer actively supported.', Comment = '%1 = BC Major, %2 = Latest App Minor, %3 = App Name, %4 = Current App Major, %5 = Current App Minor';
        AppNewVersionLbl: Label 'A new version (%1) is available for %2. The current version is %3', Comment = '%1 = Latest Version, %2 = App Name, %3 = Current Version';
        ErrorResponseLbl: Label '%1 version check returned the following error: %2', Comment = '%1 = App Name, %2 = Error Message';
        AppVersionNotificationMsgTok: Label 'fad3f869-363d-454a-ae6d-d284fee3b282', Locked = true;
        LatestVersion: Version;
        AppInfo: ModuleInfo;
    begin
        // if EnvironmentInformation.IsSaaS() then
        //     exit;
        if GetLatestAppVersion(AppId, VersionString, OldestMajorSupported, ErrorMessage) then begin
            NavApp.GetModuleInfo(AppId, AppInfo);
            if not Evaluate(LatestVersion, VersionString) then
                exit;
            LatestVersion := Version.Create(AppInfo.AppVersion.Major, LatestVersion.Minor, LatestVersion.Build, LatestVersion.Revision);
            case true of
                AppInfo.AppVersion.Major < OldestMajorSupported:
                    AppVersionNotificationMsg := StrSubstNo(BcNotSupportedLbl, AppInfo.Name, AppInfo.AppVersion.Major);
                LatestVersion.Minor - AppInfo.AppVersion.Minor >= 2:
                    AppVersionNotificationMsg := StrSubstNo(AppNotSupportedLbl, LatestVersion.Major, LatestVersion.Minor, AppInfo.Name, AppInfo.AppVersion.Major, AppInfo.AppVersion.Minor);
                // Version.Create(AppInfo.AppVersion.Major, AppInfo.AppVersion.Minor, AppInfo.AppVersion.Build, 0) < Version.Create(LatestVersion.Major, LatestVersion.Minor, LatestVersion.Build, 0):
                //     AppVersionNotificationMsg := StrSubstNo(AppNewVersionLbl, LatestVersion, AppInfo.Name, AppInfo.AppVersion);
                AppInfo.AppVersion < LatestVersion:
                    AppVersionNotificationMsg := StrSubstNo(AppNewVersionLbl, LatestVersion, AppInfo.Name, AppInfo.AppVersion);
            end;
        end else
            if ShowError and (ErrorMessage <> '') then
                AppVersionNotificationMsg := StrSubstNo(ErrorResponseLbl, AppInfo.Name, ErrorMessage);
        if AppVersionNotificationMsg <> '' then
            NotificationMgt.SendNotification(AppVersionNotificationMsgTok, AppVersionNotificationMsg);
    end;

    local procedure GetLatestAppVersion(AppId: Guid; var VersionString: Text; var OldestMajorSupported: Integer; var ErrorMessage: Text): Boolean
    var
        TempRESTParameters: Record "IDYM REST Parameters" temporary;
        ResponseToken: JsonToken;
        ErrorCode: Integer;
        AppVersionUrlLbl: Label 'App/Version?id=%1', Locked = true;
    begin
        if GetStoredLatestAppVersion(AppId, VersionString, OldestMajorSupported) then
            exit(true);
        TempRESTParameters.Init();
        TempRESTParameters.RestMethod := TempRESTParameters.RestMethod::GET;
        TempRESTParameters.Path := CopyStr(StrSubstNo(AppVersionUrlLbl, AppId), 1, MaxStrLen(TempRESTParameters.Path));
        ErrorCode := ExecuteHubCall(TempRESTParameters);
        case ErrorCode of
            200:
                begin
                    ResponseToken := TempRESTParameters.GetResponseBodyAsJSON();
                    VersionString := JSONHelper.GetTextValue(ResponseToken.AsObject(), 'version');
                    OldestMajorSupported := JSONHelper.GetIntegerValue(ResponseToken.AsObject(), 'bcMajor');
                    SetStoredLatestAppVersion(AppId, VersionString, OldestMajorSupported);
                    exit(true);
                end;
            403, 500 .. 511: //service unavailable
                exit(false);
            else begin
                if TryGetResponseObject(TempRESTParameters, ResponseToken) then
                    ErrorMessage := JSONHelper.GetTextValue(ResponseToken.AsObject(), 'message')
                else
                    ErrorMessage := TempRESTParameters.GetResponseBodyAsString();
                exit(false);
            end;
        end;
    end;

    local procedure GetStoredLatestAppVersion(AppId: Guid; var VersionString: Text; var OldestMajorSupported: Integer): Boolean
    var
        AppVersionInfo: Record "IDYM App Version Info";
    begin
        // App Version Info not stored locally, send request to app portal
        if not AppVersionInfo.Get(AppId) then
            exit(false);
        // Previous requested older then 4 hours, send request to app portal
        if AppVersionInfo."Requested On" < CurrentDateTime() - (4 * 60 * 60 * 1000) then
            exit(false);
        // Previous data is available and was updated in the last 4 hours, use local info
        VersionString := AppVersionInfo."Latest Version";
        OldestMajorSupported := AppVersionInfo."Oldest Major";
        exit(true);
    end;

    local procedure SetStoredLatestAppVersion(AppId: Guid; VersionString: Text; OldestMajorSupported: Integer)
    var
        AppVersionInfo: Record "IDYM App Version Info";
    begin
        if not AppVersionInfo.Get(AppId) then begin
            AppVersionInfo.Init();
            AppVersionInfo."App Id" := AppId;
            if not AppVersionInfo.Insert() then
                exit;
        end;
        AppVersionInfo."Latest Version" := CopyStr(VersionString, 1, MaxStrLen(AppVersionInfo."Latest Version"));
        AppVersionInfo."Oldest Major" := OldestMajorSupported;
        AppVersionInfo."Requested On" := CurrentDateTime();
        if AppVersionInfo.Modify() then;
    end;
    #endregion

    #region [License]
    internal procedure GetTrialLicenseKey(AppId: Guid; var LicenseKey: Text[50]; ThrowError: Boolean; var ErrorCode: Integer; var ErrorMessage: Text): Boolean
    var
        TempRESTParameters: Record "IDYM REST Parameters" temporary;
        EnvironmentId: Guid;
        TrialKeyFullPathLbl: Label '%1?AppId=%2&TenantId=%3&IsTrial=true', Comment = '%1 = Path, %2 = AppId, %3 = TenantId', Locked = true;
    begin
        if not GetEnvironmentId(EnvironmentId, false) then
            exit(false);
        TempRESTParameters.Init();
        TempRESTParameters.RestMethod := TempRESTParameters.RestMethod::GET;
        TempRESTParameters.Path := CopyStr(StrSubstNo(TrialKeyFullPathLbl, TrialLicenseKeyUrlLbl, DelChr(Format(AppId), '=', '{}'), DelChr(Format(EnvironmentId), '=', '{}')), 1, MaxStrLen(TempRESTParameters.Path));
        ErrorCode := ExecuteHubCall(TempRESTParameters);
        if ErrorCode <> 200 then begin
            ParseError(TempRESTParameters, ErrorCode, ErrorMessage, AppId, ThrowError);
            exit(false);
        end;
        GetTrialLicenseKeyCode(TempRESTParameters, true, true, LicenseKey);
        exit(true);
    end;

    internal procedure NewTrialLicenseKey(AppId: Guid; var LicenseKey: Text[50]; ThrowError: Boolean; var ErrorCode: Integer; var ErrorMessage: Text): Boolean
    var
        TempRESTParameters: Record "IDYM REST Parameters" temporary;
        ProcessAborted: Boolean;
        TrialKeyAbortedLbl: Label 'The request for a trial key was aborted by the user.';
    begin
        TempRESTParameters.Init();
        TempRESTParameters.RestMethod := TempRESTParameters.RestMethod::POST;
        TempRESTParameters.Path := CopyStr(TrialLicenseKeyUrlLbl, 1, MaxStrLen(TempRESTParameters.Path));
        TempRESTParameters.SetRequestContent(SetRequestContentNewTrialKey(AppId, ProcessAborted));
        if ProcessAborted then begin
            NewTrialKeyNotification(9, TrialKeyAbortedLbl, true);
            exit(false);
        end;

        ErrorCode := ExecuteHubCall(TempRESTParameters);
        if ErrorCode <> 200 then begin
            ParseError(TempRESTParameters, ErrorCode, ErrorMessage, AppId, ThrowError);
            exit(false);
        end;
        GetTrialLicenseKeyCode(TempRESTParameters, false, false, LicenseKey);
        ErrorCode := 0;
        exit(true);
    end;

    local procedure SetRequestContentNewTrialKey(AppId: Guid; var ProcessAborted: Boolean): JsonObject
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
        EnvironmentInformation: Codeunit "Environment Information";
        TenantInformation: Codeunit "Tenant Information";
        TrialKeyObject: JsonObject;
        TenantObject: JsonObject;
        LeadObject: JsonObject;
        ContactObject: JsonObject;
        EnvironmentId: Guid;
        IsProduction: Boolean;
        TrialDescriptionLbl: Label 'Trial: %1', Comment = '%1 = Company Name', Locked = true;
    begin
        IsProduction := EnvironmentInformation.IsProduction();
        ProcessAborted := not GetTrialContactInformation(IsProduction, ContactObject);
        if ProcessAborted then
            exit;
        GetEnvironmentId(EnvironmentId, true);

        JSONHelper.AddValue(TrialKeyObject, 'appId', DelChr(Format(AppId), '=', '{}'));
        JSONHelper.AddValue(TrialKeyObject, 'description', StrSubstNo(TrialDescriptionLbl, CompanyName()));
        JSONHelper.AddValue(TenantObject, 'id', DelChr(Format(EnvironmentId), '=', '{}'));
        // Tenant/Environment Information
        if EnvironmentInformation.IsSaaS() then begin
            JSONHelper.AddValue(TenantObject, 'tenantId', AzureADTenant.GetAadTenantId());
            JSONHelper.AddValue(TenantObject, 'domainName', AzureADTenant.GetAadTenantDomainName());
        end else
            JSONHelper.AddValue(TenantObject, 'tenantId', TenantInformation.GetTenantId());
        JSONHelper.AddValue(TenantObject, 'tenantDisplayName', TenantInformation.GetTenantDisplayName());
        JSONHelper.AddValue(TenantObject, 'applicationFamily', EnvironmentInformation.GetApplicationFamily());
        JSONHelper.AddValue(TenantObject, 'environmentName', EnvironmentInformation.GetEnvironmentName());
        JSONHelper.AddValue(TenantObject, 'companyName', CompanyName());
        JSONHelper.AddValue(TenantObject, 'isProduction', IsProduction);
        JSONHelper.AddValue(TenantObject, 'isSandbox', EnvironmentInformation.IsSandbox());
        JSONHelper.AddValue(TenantObject, 'isSaas', EnvironmentInformation.IsSaaS());
        JSONHelper.Add(TrialKeyObject, 'tenant', TenantObject);
        // Lead Information
        JSONHelper.AddValue(LeadObject, 'appId', DelChr(Format(AppId), '=', '{}'));
        JSONHelper.AddValue(LeadObject, 'actionCode', 'INS');
        JSONHelper.AddValue(LeadObject, 'offerTitle', 'approveit');
        JSONHelper.AddValue(LeadObject, 'leadSource', 'TRIAL');
        // Contact Information
        JSONHelper.Add(LeadObject, 'userDetails', ContactObject);
        JSONHelper.Add(TrialKeyObject, 'lead', LeadObject);
        exit(TrialKeyObject);
    end;

    local procedure GetTrialContactInformation(IsProduction: Boolean; var ContactObject: JsonObject): Boolean
    var
        Company: Record Company;
        AppContactCard: Page "IDYM App Contact Card";
    begin
        if not GuiAllowed() then
            exit(false);
        Company.Get(CompanyName());
        AppContactCard.InitContactInformation(IsProduction and not Company."Evaluation Company");
        AppContactCard.RunModal();
        if AppContactCard.IsProcessCancelled() then
            exit(false);
        AppContactCard.GetContactInformation(ContactObject);
        exit(true);
    end;

    local procedure GetTrialLicenseKeyCode(TempRESTParameters: Record "IDYM REST Parameters" temporary; FromApiResult: Boolean; NotifyOnError: Boolean; var LicenseKey: Text[50])
    var
        TrialToken: JsonToken;
        LicenseObject: JsonObject;
    begin
        if not TryGetResponseObject(TempRESTParameters, TrialToken) then
            exit;
        if FromApiResult then begin
            LicenseObject := JSONHelper.GetObject(TrialToken, 'licenseKey');
            NewTrialKeyNotification(TrialToken, NotifyOnError);
        end else
            LicenseObject := TrialToken.AsObject();
        LicenseKey := CopyStr(JSONHelper.GetTextValue(LicenseObject, 'code'), 1, MaxStrLen(LicenseKey));
    end;

    local procedure GetEnvironmentId(var EnvironmentId: Guid; CreateNew: Boolean): Boolean
    var
        EnvironmentInfo: Record "IDYM Environment Information";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if not EnvironmentInfo.FindFirst() then begin
            if not CreateNew then
                exit(false);
            EnvironmentInfo.Init();
            EnvironmentInfo."Environment Id" := CreateGuid();
            EnvironmentInfo."Environment Name" := CopyStr(EnvironmentInformation.GetEnvironmentName(), 1, MaxStrLen(EnvironmentInfo."Environment Name"));
            EnvironmentInfo.Insert();
        end;
        EnvironmentId := EnvironmentInfo."Environment Id";
        exit(true);
    end;

    local procedure NewTrialKeyNotification(TrialToken: JsonToken; NotifyOnError: Boolean)
    var
        ErrorCode: Integer;
        ErrorMessage: Text;
        FullNotificationLbl: Label '%1 Please contact %2 for more information.', Comment = '%1 = Error Message, %2 = Email Address';
    begin
        GetErrorInfoFromResponse(TrialToken, ErrorCode, ErrorMessage);
        NewTrialKeyNotification(ErrorCode, StrSubstNo(FullNotificationLbl, ErrorMessage, 'sales@idyn.nl'), NotifyOnError);
    end;

    local procedure NewTrialKeyNotification(ErrorCode: Integer; NotificationMessage: Text; NotifyOnError: Boolean)
    begin
        if not NotifyOnError then
            exit;
        if ErrorCode = 0 then
            exit;

        NotificationMgt.SendNotification(GetTrialKeyNotificationId(), NotificationMessage);
    end;

    // to do: activate for BC20 and up:
    // internal procedure CheckLicense(LicenseKeyEntryNo: Integer; AppId: Guid; Units: Integer; var ErrorMessage: Text; var ErrorCode: Integer; ThrowError: Boolean): Boolean
    // var
    //     AppLicenseKey: Record "IDYM App License Key";
    //     AppInfo: ModuleInfo;
    // begin
    //     AppLicenseKey.Get(LicenseKeyEntryNo);
    //     NavApp.GetCallerModuleInfo(AppInfo);
    //     exit(CheckLicense(AppLicenseKey."License Key", AppInfo.Id, Units, ErrorMessage, ErrorCode, ThrowError));
    // end;

    // internal procedure CheckLicense(LicenseKey: Text[50]; Units: Integer; var ErrorMessage: Text; var ErrorCode: Integer; ThrowError: Boolean): Boolean
    // var
    //     AppInfo: ModuleInfo;
    // begin
    //     NavApp.GetCallerModuleInfo(AppInfo);
    //     exit(CheckLicense(LicenseKey, AppInfo.Id, Units, ErrorMessage, ErrorCode, ThrowError));
    // end;

    internal procedure CheckLicense(LicenseKeyEntryNo: Integer; Units: Integer; var ErrorMessage: Text; var ErrorCode: Integer; ThrowError: Boolean): Boolean
    var
        AppLicenseKey: Record "IDYM App License Key";
    begin
        AppLicenseKey.Get(LicenseKeyEntryNo);
        AppLicenseKey.TestField("Licensed App Id");
        exit(CheckLicense(AppLicenseKey."Entry No.", AppLicenseKey."Licensed App Id", Units, ErrorMessage, ErrorCode, ThrowError, false));
    end;

    internal procedure CheckLicense(LicenseKeyEntryNo: Integer; AppId: Guid; Units: Integer; var ErrorMessage: Text; var ErrorCode: Integer; ThrowError: Boolean): Boolean
    begin
        exit(CheckLicense(LicenseKeyEntryNo, AppId, Units, ErrorMessage, ErrorCode, ThrowError, false));
    end;

    internal procedure CheckLicense(LicenseKeyEntryNo: Integer; AppId: Guid; Units: Integer; var ErrorMessage: Text; var ErrorCode: Integer; ThrowError: Boolean; ForceOnline: Boolean): Boolean
    var
        AppLicenseKey: Record "IDYM App License Key";
        ApphubSubscription: Record "IDYM Apphub Subscription";
        TempRESTParameters: Record "IDYM REST Parameters" temporary;
        PaymentDue: DateTime;
        ProcessAsSuccessful: Boolean;
        LicenseKeyUrlLbl: Label 'LicenseKey/Check?licenseKeyCode=%1&units=%2&appId=%3', Locked = true;
        LicenseCheckUnavailableMsg: Label 'The service that checks the idyn license keys is currently unavailable (returned error code %1). For the coming hours the license check is suspended and the idyn apps can still be used, but please inform idyn to ensure that the apps remain available.', Comment = '%1 = HTTP Status code';
    begin
        AppLicenseKey.Get(LicenseKeyEntryNo);
        if not IsNullGuid(AppLicenseKey."Licensed App Id") and (AppId <> AppLicenseKey."Licensed App Id") then
            exit(false);
        if not ForceOnline then
            if AppLicenseKey."Resume License Check On" >= CurrentDateTime() then
                exit(true);
        RecallLicenseNotifications();
        OnCheckLicense(AppId, Units);
        LogVersionInfo(AppId, AppLicenseKey."License Key", Units, 'IDYNVERSIONINFO', 'Check License: Log Version Info');
        TempRESTParameters.Init();
        TempRESTParameters.RestMethod := TempRESTParameters.RestMethod::GET;
        TempRESTParameters.Path := CopyStr(StrSubstNo(LicenseKeyUrlLbl, AppLicenseKey."License Key", Units, AppId), 1, MaxStrLen(TempRESTParameters.Path));

        ErrorCode := ExecuteHubCall(TempRESTParameters);
        case ErrorCode of
            200 .. 202:
                begin
                    if not RefreshSubscriptions(AppId, AppLicenseKey."License Key", PaymentDue) then begin
                        ApphubSubscription.SetRange("License Key", AppLicenseKey."License Key");
                        if ApphubSubscription.FindFirst() then
                            if UpdateLicenseWithMissedPayment(ApphubSubscription, PaymentDue, ThrowError) then begin //stamp error 14 on license then CheckLicense again
                                ErrorMessage := '';
                                ErrorCode := 0;
                                Sleep(1000);
                                CheckLicense(LicenseKeyEntryNo, AppId, Units, ErrorMessage, ErrorCode, ThrowError, ForceOnline);
                                exit(false);
                            end;
                    end;
                    ErrorCode := 0;
                    ResetSubmittedOnApphubSubscription(AppLicenseKey."License Key");
                    if not PostponeWriteTransactions then
                        ProcessSuccessfulLicenseCheck(AppLicenseKey, AppId);
                    exit(true);
                end;
            403, 500 .. 511: //service unavailable
                begin
                    if not PostponeWriteTransactions and (AppLicenseKey."License Grace Period Start" = 0DT) then begin
                        AppLicenseKey.Validate("License Grace Period Start", CurrentDateTime);
                        AppLicenseKey.Modify();
                    end;
                    if not NewLicenseRegistration then begin
                        ThrowError := AppLicenseKey."License Grace Period Start" <> 0DT;
                        if ThrowError then
                            ThrowError := CurrentDateTime - AppLicenseKey."License Grace Period Start" > 28800000; //throw error when license cannot be checked for 8 hours
                        ParseError(TempRESTParameters, AppLicenseKey, ErrorCode, ErrorMessage, AppId, ThrowError);
                    end else
                        ParseError(TempRESTParameters, AppLicenseKey, ErrorCode, ErrorMessage, AppId, true);
                    if GuiAllowed() then
                        NotificationMgt.SendNotification(GetLicenseCheckUnavailableId(), StrSubStNo(LicenseCheckUnavailableMsg, ErrorCode));
                    exit(false);
                end;
            else begin
                ProcessAsSuccessful := ParseError(TempRESTParameters, AppLicenseKey, ErrorCode, ErrorMessage, AppId, ThrowError);
                if not ProcessAsSuccessful then begin
                    if not PostponeWriteTransactions and (AppLicenseKey."License Grace Period Start" <> 0DT) then begin
                        Clear(AppLicenseKey."License Grace Period Start");
                        AppLicenseKey.Modify();
                    end;
                    exit(false);
                end else begin
                    if not PostponeWriteTransactions then
                        ProcessSuccessfulLicenseCheck(AppLicenseKey, AppId);
                    exit(true);
                end;
            end;
        end;
    end;

    internal procedure CheckLicense(LicenseKey: Text[50]; AppId: Guid; Units: Integer; var ErrorMessage: Text; var ErrorCode: Integer; ThrowError: Boolean): Boolean
    begin
        exit(CheckLicense(LicenseKey, AppId, Units, ErrorMessage, ErrorCode, ThrowError, false));
    end;

    internal procedure CheckLicense(LicenseKey: Text[50]; AppId: Guid; Units: Integer; var ErrorMessage: Text; var ErrorCode: Integer; ThrowError: Boolean; ForceOnline: Boolean): Boolean
    var
        AppLicenseKey: Record "IDYM App License Key";
    begin
        AppLicenseKey.SetRange("License Key", LicenseKey);
        if AppLicenseKey.FindFirst() then
            exit(CheckLicense(AppLicenseKey."Entry No.", AppId, Units, ErrorMessage, ErrorCode, ThrowError, ForceOnline));
    end;

    internal procedure CheckLicenseProperty(AppId: Guid; LicenseKey: Text[50]; PropertyKey: Text; PropertyValue: Text; ThrowError: Boolean; var ErrorCode: Integer; var ErrorMessage: Text): Boolean
    var
        AppLicenseKey: Record "IDYM App License Key";
        TempRESTParameters: Record "IDYM REST Parameters" temporary;
        ProcessAsSuccessful: Boolean;
        LicenseKeyUrlLbl: Label 'LicenseKey/CheckProperty?appId=%1&licenseKeyCode=%2&propertyKey=%3&propertyValue=%4', Locked = true;
        LicenseCheckUnavailableMsg: Label 'The service that checks the idyn license keys is currently unavailable (returned error code %1). For the coming hours the license check is suspended and the idyn apps can still be used, but please inform idyn to ensure that the apps remain available.', Comment = '%1 = HTTP Status code';
    begin
        AppLicenseKey.SetRange("License Key", LicenseKey);
        if not AppLicenseKey.FindFirst() then
            exit(false);
        if not IsNullGuid(AppLicenseKey."Licensed App Id") and (AppId <> AppLicenseKey."Licensed App Id") then
            exit(false);
        if AppLicenseKey."Resume License Check On" >= CurrentDateTime() then
            exit(true);

        TempRESTParameters.Init();
        TempRESTParameters.RestMethod := TempRESTParameters.RestMethod::GET;
        TempRESTParameters.Path := CopyStr(StrSubstNo(LicenseKeyUrlLbl, AppId, LicenseKey, PropertyKey, PropertyValue), 1, MaxStrLen(TempRESTParameters.Path));

        ErrorCode := ExecuteHubCall(TempRESTParameters);
        case ErrorCode of
            200:
                begin
                    ErrorCode := 0;
                    if not PostponeWriteTransactions then
                        ProcessSuccessfulLicenseCheck(AppLicenseKey, AppId);
                    exit(true);
                end;
            403, 500 .. 511: //license check unavailable
                begin
                    if not PostponeWriteTransactions and (AppLicenseKey."License Grace Period Start" = 0DT) then begin
                        AppLicenseKey.Validate("License Grace Period Start", CurrentDateTime);
                        AppLicenseKey.Modify();
                    end;
                    if not NewLicenseRegistration then begin
                        ThrowError := AppLicenseKey."License Grace Period Start" <> 0DT;
                        if ThrowError then
                            ThrowError := CurrentDateTime - AppLicenseKey."License Grace Period Start" > 28800000; //throw error when license cannot be checked for 8 hours
                        ParseHubError(TempRESTParameters, AppLicenseKey, ErrorCode, ErrorMessage, AppId, ThrowError);
                    end else
                        ParseHubError(TempRESTParameters, AppLicenseKey, ErrorCode, ErrorMessage, AppId, true);
                    if GuiAllowed() then
                        NotificationMgt.SendNotification(GetLicenseCheckUnavailableId(), StrSubStNo(LicenseCheckUnavailableMsg, ErrorCode));
                    exit(false);
                end;
            else begin
                ProcessAsSuccessful := ParseHubError(TempRESTParameters, AppLicenseKey, ErrorCode, ErrorMessage, AppId, ThrowError);
                if not ProcessAsSuccessful then begin
                    if not PostponeWriteTransactions and (AppLicenseKey."License Grace Period Start" <> 0DT) then begin
                        Clear(AppLicenseKey."License Grace Period Start");
                        AppLicenseKey.Modify();
                    end;
                    exit(false);
                end else begin
                    if not PostponeWriteTransactions then
                        ProcessSuccessfulLicenseCheck(AppLicenseKey, AppId);
                    exit(true);
                end;
            end;
        end;
    end;

    // internal procedure GetLicenseStatus(LicenseKey: Text[50]; var Status: Text; var Style: Text): Boolean
    // var
    //     AppInfo: ModuleInfo;
    // begin
    //     NavApp.GetCallerModuleInfo(AppInfo);
    //     exit(GetLicenseStatus(AppInfo.Id, LicenseKey, Status, Style));
    // end;

    internal procedure GetLicenseStatus(AppId: Guid; LicenseKey: Text[50]; var Status: Text; var Style: Text): Boolean
    begin
        exit(GetLicenseStatus(AppId, LicenseKey, Status, Style, false));
    end;

    internal procedure GetLicenseStatus(AppId: Guid; LicenseKey: Text[50]; var Status: Text; var Style: Text; ForceOnline: Boolean): Boolean
    var
        ErrorMessage: Text;
        ErrCode: Integer;
    begin
        Clear(ReturnErrorCode);
        if CheckLicense(LicenseKey, AppId, 0, ErrorMessage, ErrCode, false, ForceOnline) then begin
            Status := GetSuccessStatusAndStyle(Style);
            exit(true);
        end;
        ReturnErrorCode := ErrCode;
        Status := GetStatusAndStyleForErrCode(ErrCode, Style);
        exit(false);
    end;

    internal procedure GetStatusAndStyleForErrCode(ErrCode: Integer; var OutputStyle: Text) Status: Text
    var
        LicenseKeyInvalidMsg: Label 'Invalid';
        LicenseKeyDisabledMsg: Label 'Inactive';
        LicenseKeyExpiredMsg: Label 'Expired';
        LicenseKeyBlockedMsg: Label 'Blocked';
        LicenseKeyExceededMsg: Label 'Exceeded';
        ServerNotMsg: Label 'Server not available';
    begin
        case ErrCode of
            4:
                begin
                    Status := LicenseKeyInvalidMsg;
                    OutputStyle := 'Unfavorable';
                end;
            5:
                begin
                    Status := LicenseKeyInvalidMsg;
                    OutputStyle := 'Unfavorable';
                end;
            6:
                begin
                    Status := LicenseKeyDisabledMsg;
                    OutputStyle := 'Unfavorable';
                end;
            7:
                begin
                    Status := LicenseKeyExpiredMsg;
                    OutputStyle := 'Unfavorable';
                end;
            13:
                begin
                    Status := LicenseKeyExceededMsg;
                    OutputStyle := 'Unfavorable';
                end;
            14, 16:
                begin
                    Status := LicenseKeyBlockedMsg;
                    OutputStyle := 'Unfavorable';
                end;
            403, 500 .. 511:
                begin
                    Status := ServerNotMsg;
                    OutputStyle := 'Ambiguous';
                end;
            else begin
                Status := LicenseKeyInvalidMsg;
                OutputStyle := 'Unfavorable';
            end;
        end;
    end;

    internal procedure GetSuccessStatusAndStyle(var OutputStyle: Text) Status: Text
    begin
        OutputStyle := 'Favorable';
        Status := 'Valid';
    end;

    [Obsolete('Added add parameter to NewLicenseProperty', '21.0')]
    internal procedure NewLicenseProperty(AppId: Guid; LicenseKey: Text[50]; PropertyKey: Text; PropertyValues: List of [Text]; ThrowError: Boolean; var ErrorCode: Integer; var ErrorMessage: Text): Boolean
    begin
    end;

    internal procedure NewLicenseProperty(AppId: Guid; AppLicenseKey: Record "IDYM App License Key"; PropertyKey: Text; PropertyValues: List of [Text]; ThrowError: Boolean; var ErrorCode: Integer; var ErrorMessage: Text): Boolean
    var
        TempRESTParameters: Record "IDYM REST Parameters" temporary;
        LicenseKeyUrlLbl: Label 'LicenseKey/Property', Locked = true;
    begin
        TempRESTParameters.Init();
        TempRESTParameters.RestMethod := TempRESTParameters.RestMethod::POST;
        TempRESTParameters.Path := CopyStr(LicenseKeyUrlLbl, 1, MaxStrLen(TempRESTParameters.Path));
        TempRESTParameters.SetRequestContent(SetRequestContentNewLicenseProperty(AppId, AppLicenseKey."License Key", PropertyKey, PropertyValues));

        ErrorCode := ExecuteHubCall(TempRESTParameters);
        if ErrorCode <> 200 then begin
            ParseError(TempRESTParameters, AppLicenseKey, ErrorCode, ErrorMessage, AppId, ThrowError);
            exit(false);
        end;
        ErrorCode := 0;
        exit(true);
    end;

    local procedure ProcessSuccessfulLicenseCheck(var AppLicenseKey: Record "IDYM App License Key"; AppId: Guid)
    var
        ModifyRecord: Boolean;
    begin
        ModifyRecord := (AppLicenseKey."License Grace Period Start" <> 0DT) or (SkipLicenseCheckDuration <> 0);
        if AppLicenseKey."License Grace Period Start" <> 0DT then
            Clear(AppLicenseKey."License Grace Period Start");
        if SkipLicenseCheckDuration <> 0 then
            AppLicenseKey.Validate("Resume License Check On", CurrentDateTime() + SkipLicenseCheckDuration);
        ModifyRecord := IsNullGuid(AppLicenseKey."Licensed App Id");
        if ModifyRecord then begin
            AppLicenseKey."Licensed App Id" := AppId;
            AppLicenseKey.Modify();
        end;
    end;

    [NonDebuggable]
    local procedure UpdateLicenseWithMissedPayment(ApphubSubscription: Record "IDYM Apphub Subscription"; PaymentDueDate: DateTime; ThrowError: Boolean) Successful: Boolean
    var
        TempRESTParameters: Record "IDYM REST Parameters" temporary;
        ErrorCode: Integer;
        LicensePaymentUrlLbl: Label 'Subscription', Locked = true;
        LicensePaymentMatchingUnavailableMsg: Label 'The service that checks the apphub license is currently unavailable (returned error code %1): %2.', Comment = '%1 = HTTP Status code, %2 = error message';
    begin
        TempRESTParameters.Init();
        TempRESTParameters.RestMethod := TempRESTParameters.RestMethod::POST;
        TempRESTParameters.Path := LicensePaymentUrlLbl;
        TempRESTParameters.SetRequestContent(CreateApphubLicenseBlockedJsonObject(ApphubSubscription, PaymentDueDate));
        ErrorCode := ExecuteHubCall(TempRESTParameters);
        Successful := ErrorCode in [200 .. 201];
        if not Successful then begin
            if ThrowError or not GuiAllowed() then
                Error(LicensePaymentMatchingUnavailableMsg, ErrorCode, TempRESTParameters.GetResponseBodyAsString());
            NotificationMgt.SendNotification(GetLicenseCheckUnavailableId(), StrSubStNo(LicensePaymentMatchingUnavailableMsg, ErrorCode, TempRESTParameters.GetResponseBodyAsString()));
        end;
    end;

    [NonDebuggable]
    local procedure CreateApphubLicenseBlockedJsonObject(ApphubSubscription: Record "IDYM Apphub Subscription"; PaymentDueDate: DateTime) LicenseKeyObject: JsonObject
    begin
        JSONHelper.AddValue(LicenseKeyObject, 'id', DelChr(Format(ApphubSubscription."Id"), '=', '{}'));
        JSONHelper.AddValue(LicenseKeyObject, 'appId', DelChr(Format(ApphubSubscription."App Id"), '=', '{}'));
        JSONHelper.AddValue(LicenseKeyObject, 'licenseKey', ApphubSubscription."License Key");
        JSONHelper.AddValue(LicenseKeyObject, 'paymentMissed', true);
        JSONHelper.AddValue(LicenseKeyObject, 'paymentBlocked', PaymentDueDate);
        JSONHelper.AddValue(LicenseKeyObject, 'paymentDue', CreateDateTime(Today, 0T));
    end;

    local procedure SetRequestContentNewLicenseProperty(AppId: Guid; LicenseKey: Text[50]; PropertyKey: Text; PropertyValues: List of [Text]): JsonObject
    var
        LicenseKeyObject: JsonObject;
        LicenseKeyPropertyObject: JsonObject;
        LicenseKeyPropertiesArray: JsonArray;
        PropertyValue: Text;
    begin
        JSONHelper.AddValue(LicenseKeyObject, 'appId', Format(AppId));
        JSONHelper.AddValue(LicenseKeyObject, 'licenseKey', LicenseKey);

        foreach PropertyValue in PropertyValues do begin
            JSONHelper.AddValue(LicenseKeyPropertyObject, 'propertyKey', PropertyKey);
            JSONHelper.AddValue(LicenseKeyPropertyObject, 'propertyValue', PropertyValue);
            JSONHelper.Add(LicenseKeyPropertiesArray, LicenseKeyPropertyObject);
        end;
        if LicenseKeyPropertiesArray.Count() > 0 then
            JSONHelper.Add(LicenseKeyObject, 'properties', LicenseKeyPropertiesArray);

        exit(LicenseKeyObject);
    end;

    internal procedure RemoveAppLicenseKey(EntryNo: Integer)
    var
        AppLicenseKey: Record "IDYM App License Key";
    begin
        AppLicenseKey.Get(EntryNo);
        AppLicenseKey.Delete(true);
    end;

    internal procedure RemoveUnusedAppLicenses(RemovePaidLicenses: Boolean)
    var
        AppLicenseKey: Record "IDYM App License Key";
        User: Record User;
        AppInfo: ModuleInfo;
        ToRemove: Boolean;
        TempUninstalledAppsQst: Label 'All the licenses for apps that are currently not installed will be removed. Are you sure that are no apps that are temporarily uninstalled that are still being used?';
    begin
        if RemovePaidLicenses then
            if not Confirm(TempUninstalledAppsQst) then
                Error('');
        AppLicenseKey.SetFilter("Parent App Entry No.", '<>0');
        if AppLicenseKey.FindSet(true) then
            repeat
                if RemovePaidLicenses or (AppLicenseKey."License Key" = '') then begin
                    ToRemove := not NavApp.GetModuleInfo(AppLicenseKey."App Id", AppInfo);
                    if not ToRemove then
                        if (AppLicenseKey."Property Key" = 'username') and (AppLicenseKey."Property Value" <> '') then begin
                            User.SetRange("Full Name", CopyStr(AppLicenseKey."Property Value", 1, MaxStrLen(User."Full Name")));
                            ToRemove := not User.FindFirst();
                            if not ToRemove then
                                ToRemove := User.State = User.State::Disabled;
                        end;
                    if ToRemove then
                        AppLicenseKey.Delete(true);
                end;
            until AppLicenseKey.Next() = 0;
    end;

    procedure SetErrorUnitName(NewUnitName: Text)
    begin
        ErrorUnitName := NewUnitName;
    end;

    procedure GetErrorCode(): Integer
    begin
        exit(ReturnErrorCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckLicense(AppId: Guid; var Units: Integer)
    begin
    end;
    #endregion

    #region [Lead]
    internal procedure RegisterLead(AppId: Guid; OfferTitle: Text): Boolean
    var
        TempRESTParameters: Record "IDYM REST Parameters" temporary;
        StatusCode: Integer;
        LeadLbl: Label '/lead', Locked = true;
    begin
        OnSetOfferTitle(AppId, OfferTitle);
        TempRESTParameters.Init();
        TempRESTParameters.RestMethod := TempRESTParameters.RestMethod::POST;
        TempRESTParameters.Path := CopyStr(LeadLbl, 1, MaxStrLen(TempRESTParameters.Path));
        TempRESTParameters.SetRequestContent(SetRegisterLeadRequestContent(AppId, OfferTitle));
        StatusCode := ExecuteHubCall(TempRESTParameters);
        if StatusCode <> 200 then
            exit(false);
        exit(true)
    end;

    local procedure SetRegisterLeadRequestContent(AppId: Guid; OfferTitle: Text): JsonObject
    var
        CompanyInformation: Record "Company Information";
        Lead: JsonObject;
        UserDetails: JsonObject;
    begin
        JSONHelper.AddValue(Lead, 'actionCode', 'INS');
        JSONHelper.AddValue(Lead, 'appId', Format(AppId));
        JSONHelper.AddValue(Lead, 'offerTitle', OfferTitle);
        JSONHelper.AddValue(Lead, 'leadSource', 'app');
        if CompanyInformation.Get() then begin
            JSONHelper.AddValue(UserDetails, 'company', CompanyInformation.Name);
            JSONHelper.AddValue(UserDetails, 'country', CompanyInformation."Country/Region Code");
            JSONHelper.AddValue(UserDetails, 'email', CompanyInformation."E-Mail");
            JSONHelper.AddValue(UserDetails, 'firstName', CompanyInformation."Contact Person");
            JSONHelper.AddValue(UserDetails, 'lastName', '');
            JSONHelper.AddValue(UserDetails, 'phone', CompanyInformation."Phone No.");
            JSONHelper.AddValue(UserDetails, 'title', '');
        end;
        JSONHelper.Add(Lead, 'userDetails', UserDetails);
        exit(lead);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetOfferTitle(MainAppid: Guid; var OfferTitle: Text)
    begin
    end;
    #endregion

    #region [Tenant]
    internal procedure RegisterTenant(var ErrorMessage: Text; var ErrorCode: Integer): Boolean
    var
        TempRESTParameters: Record "IDYM REST Parameters" temporary;
        EnvironmentInformation: Codeunit "Environment Information";
        AzureADTenant: Codeunit "Azure AD Tenant";
        AppInfo: ModuleInfo;
        TenantLbl: Label '/tenant', Locked = true;
    begin
        if not (EnvironmentInformation.IsSaaS() and (AzureADTenant.GetAadTenantId().StartsWith('ms'))) then
            exit;
        NavApp.GetCurrentModuleInfo(AppInfo);
        TempRESTParameters.Init();
        TempRESTParameters.RestMethod := TempRESTParameters.RestMethod::POST;
        TempRESTParameters.Path := CopyStr(TenantLbl, 1, MaxStrLen(TempRESTParameters.Path));
        TempRESTParameters.SetRequestContent(SetRegisterTenantRequestContent());
        ErrorCode := ExecuteHubCall(TempRESTParameters);
        if ErrorCode = 200 then
            ErrorCode := 0
        else
            ParseError(TempRESTParameters, ErrorCode, ErrorMessage, AppInfo.Id, false);
        exit(ErrorCode = 0);
    end;

    [NonDebuggable]
    local procedure SetRegisterTenantRequestContent(): JsonObject
    var
        CompanyInformation: Record "Company Information";
        TenantInformation: Codeunit "Tenant Information";
        AzureADTenant: Codeunit "Azure AD Tenant";
        EnvironmentInformation: Codeunit "Environment Information";
        Tenant: JsonObject;
        Company: JsonObject;
    begin
        JSONHelper.AddValue(Tenant, 'tenantId', TenantInformation.GetTenantId());
        JSONHelper.AddValue(Tenant, 'aadTenantId', AzureADTenant.GetAadTenantId());
        JSONHelper.AddValue(Tenant, 'aadTenantDomainName', AzureADTenant.GetAadTenantDomainName());
        JSONHelper.AddValue(Tenant, 'tenantDisplayName', TenantInformation.GetTenantDisplayName());
        JSONHelper.AddValue(Tenant, 'applicationFamily', EnvironmentInformation.GetApplicationFamily());
        JSONHelper.AddValue(Tenant, 'environmentName', EnvironmentInformation.GetEnvironmentName());
        JSONHelper.AddValue(Tenant, 'isProduction', EnvironmentInformation.IsProduction());
        JSONHelper.AddValue(Tenant, 'isSandbox', EnvironmentInformation.IsSandbox());
        JSONHelper.AddValue(Tenant, 'isOnPrem', EnvironmentInformation.IsOnPrem());
        JSONHelper.AddValue(Tenant, 'isSaaS', EnvironmentInformation.IsSaaS());
        JSONHelper.AddValue(Tenant, 'isFinancials', EnvironmentInformation.IsFinancials());

        if CompanyInformation.Get() then begin
            JSONHelper.AddValue(Company, 'tenantId', TenantInformation.GetTenantId());
            JSONHelper.AddValue(Company, 'Name', CompanyInformation.Name);
            JSONHelper.AddValue(Company, 'Name2', CompanyInformation."Name 2");
            JSONHelper.AddValue(Company, 'Address', CompanyInformation.Address);
            JSONHelper.AddValue(Company, 'Address2', CompanyInformation."Address 2");
            JSONHelper.AddValue(Company, 'City', CompanyInformation.City);
            JSONHelper.AddValue(Company, 'PostCode', CompanyInformation."Post Code");
            JSONHelper.AddValue(Company, 'Country', CompanyInformation."Country/Region Code");
            JSONHelper.AddValue(Company, 'PhoneNo', CompanyInformation."Phone No.");
            JSONHelper.AddValue(Company, 'Email', CompanyInformation."E-Mail");
            JSONHelper.AddValue(Company, 'Website', CompanyInformation."Home Page");
        end;
        JSONHelper.Add(Tenant, 'Company', Company);
        exit(Tenant);
    end;
    #endregion

    #region Subscription
    internal procedure LicensePayment(LicenseKeyEntryNo: Integer; AppId: Guid; RequestJsonObject: JsonObject; var ErrorMessage: Text; var ErrorCode: Integer; ThrowError: Boolean): Boolean
    var
        AppLicenseKey: Record "IDYM App License Key";
        TempRESTParameters: Record "IDYM REST Parameters" temporary;
        ModifyRecord: Boolean;
        LicensePaymentUrlLbl: Label 'Subscription', Locked = true;
        LicensePaymentMatchingUnavailableMsg: Label 'The service that matches payments is currently unavailable (returned error code %1). Please inform idyn that the license key could be enabled.', Comment = '%1 = HTTP Status code';
    begin
        AppLicenseKey.Get(LicenseKeyEntryNo);
        if not IsNullGuid(AppLicenseKey."Licensed App Id") and (AppId <> AppLicenseKey."Licensed App Id") then
            exit(false);

        TempRESTParameters.Init();
        TempRESTParameters.RestMethod := TempRESTParameters.RestMethod::POST;
        TempRESTParameters.Path := LicensePaymentUrlLbl;
        TempRESTParameters.SetRequestContent(RequestJsonObject);
        ErrorCode := ExecuteHubCall(TempRESTParameters);
        case ErrorCode of
            200 .. 202:
                begin
                    ErrorCode := 0;
                    if not PostponeWriteTransactions then begin
                        ModifyRecord := (AppLicenseKey."License Grace Period Start" <> 0DT) or (SkipLicenseCheckDuration <> 0);
                        if AppLicenseKey."License Grace Period Start" <> 0DT then
                            Clear(AppLicenseKey."License Grace Period Start");
                        ModifyRecord := IsNullGuid(AppLicenseKey."Licensed App Id");
                        if ModifyRecord then begin
                            AppLicenseKey."Licensed App Id" := AppId;
                            AppLicenseKey.Modify();
                        end;
                    end;
                    exit(true);
                end;
            403, 500 .. 511: //service unavailable
                begin
                    if not PostponeWriteTransactions and (AppLicenseKey."License Grace Period Start" = 0DT) then begin
                        AppLicenseKey.Validate("License Grace Period Start", CurrentDateTime);
                        AppLicenseKey.Modify();
                    end;
                    ParseError(TempRESTParameters, AppLicenseKey, ErrorCode, ErrorMessage, AppId, ThrowError);

                    NotificationMgt.SendNotification(GetLicenseCheckUnavailableId(), StrSubStNo(LicensePaymentMatchingUnavailableMsg, ErrorCode));
                    exit(false);
                end;
            else begin
                ParseError(TempRESTParameters, AppLicenseKey, ErrorCode, ErrorMessage, AppId, ThrowError);
                if not PostponeWriteTransactions and (AppLicenseKey."License Grace Period Start" <> 0DT) then begin
                    Clear(AppLicenseKey."License Grace Period Start");
                    AppLicenseKey.Modify();
                end;
                exit(false);
            end;
        end;
    end;

    [NonDebuggable]
    internal procedure RequestDocusignAgreement(ApphubSubscription: Record "IDYM Apphub Subscription")
    var
        TempRESTParameters: Record "IDYM REST Parameters" temporary;
        AppInfo: ModuleInfo;
        ErrorMessage: Text;
        ErrorCode: Integer;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        TempRESTParameters.RestMethod := TempRESTParameters.RestMethod::POST;
        TempRESTParameters.Path := 'Subscription/Request';
        TempRESTParameters.SetRequestContent(CreateSubscriptionJsonObject(ApphubSubscription));
        ErrorCode := ExecuteHubCall(TempRESTParameters);
        if not (ErrorCode in [200, 201]) then
            ParseError(TempRESTParameters, ErrorCode, ErrorMessage, AppInfo.Id, true);
    end;

    [NonDebuggable]
    local procedure CreateSubscriptionJsonObject(ApphubSubscription: Record "IDYM Apphub Subscription") SubscriptionJsonObject: JsonObject
    begin
        JSONHelper.AddValue(SubscriptionJsonObject, 'appId', Format(LowerCase(DelChr(ApphubSubscription."App Id", '=', '{}'))));
        JSONHelper.AddValue(SubscriptionJsonObject, 'subscriptionId', Format(LowerCase(DelChr(ApphubSubscription."Id", '=', '{}'))));
        JSONHelper.AddValue(SubscriptionJsonObject, 'requestedAt', Format(CurrentDateTime, 0, 9));
        JSONHelper.AddValue(SubscriptionJsonObject, 'requestedBy', UserId());
        JSONHelper.AddValue(SubscriptionJsonObject, 'recipientName', ApphubSubscription."Recipient Name");
        JSONHelper.AddValue(SubscriptionJsonObject, 'recipientEmail', ApphubSubscription."Recipient Email");
    end;

    local procedure ResetSubmittedOnApphubSubscription(LicenseKey: Text[50])
    var
        ApphubSubscription: Record "IDYM Apphub Subscription";
    begin
        ApphubSubscription.SetRange("License Key", LicenseKey);
        ApphubSubscription.SetRange(Submitted, true);
        if ApphubSubscription.FindFirst() then begin
            ApphubSubscription.Submitted := false;
            ApphubSubscription."Recipient Name" := '';
            ApphubSubscription."Recipient Email" := '';
            ApphubSubscription.SetUnrestricedAccess();
            ApphubSubscription.Modify();
        end;
    end;

    local procedure RefreshSubscriptions(AppId: Guid; LicenseKey: Text[50]; var ValidUntil: DateTime) NoOrActiveSubscription: Boolean;
    var
        Subscription: Record "IDYM Subscription";
        PaymentMgt: Codeunit "IDYM Payment Mgt.";
    begin
        if LicenseKey = '' then
            Error('License Key should not be empty');
        PaymentMgt.SetParameters(AppId, LicenseKey);
        Subscription.SetRange("Product Guid", AppId);
        Subscription.SetRange("License Key", LicenseKey);
        if Subscription.FindSet(true) then
            repeat
                PaymentMgt.SetProvider(Subscription."Payment Provider");
                PaymentMgt.GetSubscription(Subscription.Id, Subscription, true);
                if (Subscription.Status in [Subscription.Status::Active, Subscription.Status::Expired, Subscription.Status::Cancelled]) and //Expired and cancelled are still valid when payment occured and today is within the payment interval
                   (Subscription."Valid Until" >= CreateDateTime(CalcDate('<3D>', Today), 0T))
                then begin
                    NoOrActiveSubscription := true;
                    if Subscription."Valid Until" > ValidUntil then
                        ValidUntil := Subscription."Valid Until";
                end;
            until NoOrActiveSubscription or (Subscription.Next() = 0)
        else
            NoOrActiveSubscription := true;
    end;
    #endregion

    #region Hubcall
    local procedure ExecuteHubCall(var RESTParameters: Record "IDYM REST Parameters" temporary): Integer
    var
        HttpHelper: Codeunit "IDYM HTTP Helper";
        HttpClient: HttpClient;
        HttpHeaders: HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpContent: HttpContent;
        ContentHttpHeaders: HttpHeaders;
    begin
        HttpHelper.SetRequestMethod(RESTParameters, HttpRequestMessage);
        HttpRequestMessage.SetRequestUri(CreateUri(RESTParameters.Path));
        HttpRequestMessage.GetHeaders(HttpHeaders);

        if RESTParameters.Accept <> '' then
            HttpHeaders.Add('Accept', RESTParameters.Accept);
        SetAppHubCredentials(HttpHeaders);

        if RESTParameters.HasRequestContent() then begin
            RESTParameters.GetRequestContent(HttpContent);
            HttpContent.GetHeaders(ContentHttpHeaders);
            if ContentHttpHeaders.Contains('Content-Type') then
                ContentHttpHeaders.Remove('Content-Type');
            if RESTParameters."Content-Type" <> '' then
                ContentHttpHeaders.Add('Content-Type', RESTParameters."Content-Type")
            else
                ContentHttpHeaders.Add('Content-Type', 'application/json');
            HttpRequestMessage.Content := HttpContent;
        end;

        HttpClient.Send(HttpRequestMessage, HttpResponseMessage);
        HttpHeaders := HttpResponseMessage.Headers();
        RESTParameters.SetResponseHeaders(HttpHeaders);
        HttpContent := HttpResponseMessage.Content();
        RESTParameters.SetResponseContent(HttpContent);
        exit(HttpResponseMessage.HttpStatusCode());
    end;

    local procedure CreateUri(Path: Text): Text
    begin
        if not Path.StartsWith('/') then
            Path := '/' + Path;
        //exit('https://apphub-v2-test.azurewebsites.net/api/v2' + Path);
        exit('https://apphub-v2.azurewebsites.net/api/v2' + Path);
    end;

    [NonDebuggable]
    local procedure SetAppHubCredentials(HttpHeaders: HttpHeaders)
    begin
        HttpHeaders.Add('appId', 'idym-appmgt-key');
        HttpHeaders.Add('appSecret', 'hUnX6RHlNRv8NYx6XybsF3yVnfMiM3b43itqQO');
        //HttpHeaders.Add('appId', 'idyn');
        //HttpHeaders.Add('appSecret', 'secret');
    end;

    local procedure LogVersionInfo(AppId: Guid; LicenseKey: Text[50]; Units: Integer; EventId: Text; EventName: Text)
    var
        ApplicationSystemConstants: Codeunit "Application System Constants";
        EnvironmentInformation: Codeunit "Environment Information";
        CustomDimensions: Dictionary of [Text, Text];
        AppInfo: ModuleInfo;
        Handled: Boolean;
    begin
        OnBeforeLogVersionInfo(AppId, Handled);
        if Handled then
            exit;
        if not NavApp.GetModuleInfo(AppId, AppInfo) then
            exit;
        CustomDimensions.Add('IdynExtentionLicenseKey', LicenseKey);
        CustomDimensions.Add('IdynExtentionUnits', Format(Units));
        CustomDimensions.Add('IdynExtentionId', Format(AppId));
        CustomDimensions.Add('IdynExtensionName', AppInfo.Name);
        CustomDimensions.Add('IdynExtensionVersion', Format(AppInfo.AppVersion));
        CustomDimensions.Add('IdynAppApplicationVersion', ApplicationSystemConstants.ApplicationVersion());
        CustomDimensions.Add('IdynAppBuildBranch', ApplicationSystemConstants.BuildBranch());
        CustomDimensions.Add('IdynAppBuildFileVersion', ApplicationSystemConstants.BuildFileVersion());
        CustomDimensions.Add('IdynAppPlatformFileVersion', ApplicationSystemConstants.PlatformFileVersion());
        CustomDimensions.Add('IdynEnvApplicationFamily', EnvironmentInformation.GetApplicationFamily());
        CustomDimensions.Add('IdynEnvIsSaaS', Format(EnvironmentInformation.IsSaaS(), 0, 9));
        CustomDimensions.Add('IdynEnvIsProduction', Format(EnvironmentInformation.IsProduction(), 0, 9));
        CustomDimensions.Add('IdynEnvIsSandbox', Format(EnvironmentInformation.IsSandbox(), 0, 9));
        LogMessage(EventId, EventName, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLogVersionInfo(AppId: Guid; var Handled: Boolean)
    begin
    end;
    #endregion

    #region [LogUsage]
    [Obsolete('Discontinued', '22.0')]
    procedure LogUsage(Qty: Integer; var ErrorMessage: Text; var ErrorCode: Integer; ActionId: Integer): Boolean
    begin
        exit(true);
    end;

    [Obsolete('Discontinued', '22.0')]
    procedure LogUsage(AppId: Guid; LicenseKey: Text[50]; Qty: Integer; var ErrorMessage: Text; var ErrorCode: Integer; ActionId: Integer): Boolean
    begin
        exit(true);
    end;

    procedure SetLogUsageRequestContent(Qty: Integer; ActionId: Integer; LicenseKey: Text[50]; AppId: Guid): JsonObject
    var
        EnvironmentInformation: Codeunit "Environment Information";
        AzureADTenant: Codeunit "Azure AD Tenant";
        Usage: JsonObject;
    begin
        // Only for AppSource App - Begin ///////////////////////////////////////////////////////
        if EnvironmentInformation.IsSaaS() and (AzureADTenant.GetAadTenantId().StartsWith('ms')) then
            JSONHelper.AddValue(Usage, 'tenantId', AzureADTenant.GetAadTenantId());
        // Only for AppSource App - End /////////////////////////////////////////////////////////
        JSONHelper.AddValue(Usage, 'licenseKey', LicenseKey);
        JSONHelper.AddValue(Usage, 'appId', DelChr(Format(AppId), '=', '{}'));
        JSONHelper.AddValue(Usage, 'appActionId', ActionId);
        JSONHelper.AddValue(Usage, 'qty', Qty);
        exit(Usage);
    end;
    #endregion

    #region [Error Handling]
    local procedure ParseError(RESTParameters: Record "IDYM REST Parameters"; var ErrorCode: Integer; var ErrorMessage: Text; AppId: Guid; ThrowError: Boolean) ErrorObject: JsonToken;
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
    begin
        if not TryGetResponseObject(RESTParameters, ErrorObject) or not ErrorObject.IsObject() then
            ErrorMessage := RESTParameters.GetResponseBodyAsString();
        if (ErrorMessage = '') and ErrorObject.IsObject then
            if not ErrorObject.AsObject().Contains('errorCode') then
                ErrorMessage := RESTParameters.GetResponseBodyAsString();

        if (ErrorMessage = '') and ErrorObject.IsObject then begin
            ErrorCode := JSONHelper.GetIntegerValue(ErrorObject.AsObject(), 'errorCode');

            case ErrorCode of
                1:
                    ErrorMessage := StrSubstNo(Msg001Err, AzureADTenant.GetAadTenantId());
                8:
                    ErrorMessage := StrSubstNo(Msg008Err, AppId);
                10:
                    ErrorMessage := Msg010Err;
                11:
                    ErrorMessage := Msg011Err;
                12:
                    ErrorMessage := Msg012Err;
                4 .. 7, 9, 13 .. 17:
                    exit;
                else
                    ErrorMessage := GenericErr;
            end;
        end;

        if ErrorMessage = '' then
            ErrorMessage := GenericErr;

        if ThrowError then
            Error(ErrorMessage);
    end;

    local procedure ParseError(RESTParameters: Record "IDYM REST Parameters"; AppLicenseKey: Record "IDYM App License Key"; var ErrorCode: Integer; var ErrorMessage: Text; AppId: Guid; ThrowError: Boolean): Boolean
    begin
        if not GuiAllowed then //on mobile devices and background tasks we need errors instead of notifications
            ThrowError := true;
        exit(ParseHubError(RESTParameters, AppLicenseKey, ErrorCode, ErrorMessage, AppId, ThrowError));
    end;

    local procedure GetErrorInfoFromResponse(ErrorToken: JsonToken; var ErrorCode: Integer; var ErrorMessage: Text)
    begin
        if ErrorToken.AsObject().Contains('errorCode') then
            ErrorCode := JSONHelper.GetIntegerValue(ErrorToken.AsObject(), 'errorCode');
        if ErrorToken.AsObject().Contains('message') then
            ErrorMessage := JSONHelper.GetTextValue(ErrorToken.AsObject(), 'message');
    end;

    local procedure ParseHubError(RESTParameters: Record "IDYM REST Parameters"; AppLicenseKey: Record "IDYM App License Key"; var ErrorCode: Integer; var ErrorMessage: Text; AppId: Guid; ThrowError: Boolean) ProcessAsSuccessful: Boolean
    var
        ApphubSubscription: Record "IDYM Apphub Subscription";
        PaymentMgt: Codeunit "IDYM Payment Mgt.";
        ErrorObject: JsonToken;
        AppInfo: ModuleInfo;
        RedirectErr: Label '%1 %2', Locked = true;
        PaymentDueMsg: Label 'This license key will be blocked soon because of overdue payments';
    begin
        ErrorObject := ParseError(RESTParameters, ErrorCode, ErrorMessage, AppId, ThrowError);
        if (ErrorMessage = '') and ErrorObject.IsObject then
            case ErrorCode of
                4:
                    ErrorMessage := StrSubstNo(Msg004Err, AppLicenseKey."License Key");
                5:
                    ErrorMessage := StrSubstNo(Msg005Err, AppLicenseKey."License Key");
                6:
                    ErrorMessage := StrSubstNo(Msg006Err, AppLicenseKey."License Key");
                7:
                    ErrorMessage := StrSubstNo(Msg007Err, AppLicenseKey."License Key");
                9:
                    ErrorMessage := Msg009Err;
                13:
                    if ErrorUnitName <> '' then
                        ErrorMessage := StrSubstNo(Msg013Err, ErrorUnitName)
                    else
                        ErrorMessage := StrSubstNo(Msg013Err, UnitNameLbl);
                14, 16:
                    begin
                        ErrorMessage := JSONHelper.GetTextValue(ErrorObject.AsObject(), 'message');
                        if ErrorMessage = '' then
                            ErrorMessage := Msg014Err;
                        if ErrorCode = 14 then begin
                            PaymentMgt.SetParameters(AppID, AppLicenseKey."License Key");
                            PaymentMgt.ExtractSubscriptionDetails(RESTParameters.GetResponseBodyAsJsonObject());
                            ErrorMessage := SendBlockedLicenseKeyNotification(AppLicenseKey, ThrowError);
                        end;
                        if ErrorCode = 16 then begin
                            PaymentMgt.SetParameters(AppId, AppLicenseKey."License Key");
                            PaymentMgt.ExtractApphubSubscriptionDetails(RESTParameters.GetResponseBodyAsJsonObject(), ApphubSubscription);
                            if not ThrowError then begin
                                NotificationMgt.AddAction(GetSubscriptionPaymentBlockedNotificationId(), 'Unblock License', Codeunit::"IDYM Payment Mgt.", 'UnblockLicense');
                                NotificationMgt.SendNotification(GetSubscriptionPaymentBlockedNotificationId(), ErrorMessage, 'SubscriptionId', ApphubSubscription.Id);
                            end
                            else begin
                                NavApp.GetModuleInfo(AppId, AppInfo);
                                ErrorMessage := StrSubstNo(RedirectErr, ErrorMessage, StrSubstNo(RedirectMsg, Appinfo.Name()));
                            end;
                        end;
                    end;
                //15: reserved for inactive subscriptions
                17:
                    begin
                        ErrorMessage := JSONHelper.GetTextValue(ErrorObject.AsObject(), 'message');
                        if ErrorMessage = '' then
                            ErrorMessage := PaymentDueMsg;
                        if GuiAllowed() then //17 is not really an error; just a warning
                            NotificationMgt.SendNotification(GetSubscriptionPaymentDueNotificationId(), ErrorMessage);
                        ProcessAsSuccessful := true;
                        exit;
                    end;
                else
                    ErrorMessage := GenericErr;
            end;

        if ErrorMessage = '' then
            ErrorMessage := GenericErr;

        if ThrowError then
            Error(ErrorMessage);
    end;

    local procedure SendBlockedLicenseKeyNotification(AppLicenseKey: Record "IDYM App License Key"; ThrowError: Boolean) ErrorMessage: Text
    var
        Subscription: Record "IDYM Subscription";
        AppInfo: ModuleInfo;
        DummyDateTime: DateTime;
        InitiateNewSubscription: Boolean;
        BlockedLicenseKeyMsg: Label 'License key for %1 is blocked due to missed payments.', Comment = '%1 = appname';
        RefreshNotificationTxt: Label 'A Paypal payment was registered for subscription %1, but the %2 license could not be updated. Please try again. If the issue persists please contact idyn.', Comment = '%1 = Subscription ID, %2 = appname';
        RedirectErr: Label '%1 %2', Locked = true;
        TryAgainTxt: Label 'Try Again.';
        InitiateNotificationTxt: Label 'Initiate payment';
    begin
        NavApp.GetModuleInfo(AppLicenseKey."App Id", AppInfo);
        Subscription.SetRange("Product Guid", AppLicenseKey."App Id");
        Subscription.SetRange("License Key", AppLicenseKey."License Key");
        InitiateNewSubscription := Subscription.IsEmpty();
        if not InitiateNewSubscription then
            InitiateNewSubscription := not RefreshSubscriptions(AppLicenseKey."App Id", AppLicenseKey."License Key", DummyDateTime);
        if not InitiateNewSubscription then begin
            Subscription.FindLast();
            if ThrowError then
                ErrorMessage := StrSubstNo(RedirectErr, StrSubstNo(RefreshNotificationTxt, Subscription.Id, AppInfo.Name), StrSubstNo(RedirectMsg, AppInfo.Name))
            else begin
                ErrorMessage := StrSubstNo(RefreshNotificationTxt, Subscription.Id, AppInfo.Name);
                NotificationMgt.AddAction(GetApphubUpdateFailedNotificationId(), TryAgainTxt, Codeunit::"IDYM Payment Mgt.", 'CheckLicensePayment');
                NotificationMgt.SendNotification(GetApphubUpdateFailedNotificationId(), ErrorMessage, 'LicenseEntryNo', Format(AppLicenseKey."Entry No."));
            end;
        end else
            if ThrowError then
                ErrorMessage := StrSubstNo(RedirectErr, StrSubstNo(BlockedLicenseKeyMsg, AppInfo.Name), StrSubstNo(RedirectMsg, AppInfo.Name))
            else begin
                ErrorMessage := StrSubstNo(BlockedLicenseKeyMsg, AppInfo.Name);
                NotificationMgt.AddAction(GetBlockedLicenseKeyNotificationId(), InitiateNotificationTxt, Codeunit::"IDYM Payment Mgt.", 'InitiateLicensePayment');
                NotificationMgt.SendNotification(GetBlockedLicenseKeyNotificationId(), ErrorMessage, 'LicenseEntryNo', Format(AppLicenseKey."Entry No."));
            end;
    end;

    [TryFunction]
    local procedure TryGetResponseObject(RestParameters: Record "IDYM REST Parameters"; var ReponseJsonToken: JsonToken)
    begin
        ReponseJsonToken := RestParameters.GetResponseBodyAsJSON();
    end;
    #endregion

    #region NotificationIds
    local procedure GetApphubUpdateFailedNotificationId(): Guid
    begin
        exit('e1ab2666-05e7-4918-a08e-7c6e2c5764e1');
    end;

    local procedure GetBlockedLicenseKeyNotificationId(): Guid
    begin
        exit('e1ab2666-05e7-4918-a08e-7c6e2c5764e0');
    end;

    local procedure GetLicenseCheckUnavailableId(): Guid
    begin
        exit('fb2c1be6-79ec-4d6e-9afb-a49a3b5cdb19');
    end;

    local procedure GetSubscriptionPaymentBlockedNotificationId(): Guid
    begin
        exit('821e6bb7-5ec6-46bd-9c76-8f9b72aa6b7a');
    end;

    local procedure GetSubscriptionPaymentDueNotificationId(): Guid
    begin
        exit('a155ad09-248c-4d5b-9744-35b3ca94fb27');
    end;

    local procedure GetTrialKeyNotificationId(): Guid
    begin
        exit('97873c4e-f39b-4593-8d57-70cc98d086da');
    end;

    local procedure RecallLicenseNotifications()
    begin
        NotificationMgt.RecallNotification(GetSubscriptionPaymentDueNotificationId());
        NotificationMgt.RecallNotification(GetSubscriptionPaymentBlockedNotificationId());
        NotificationMgt.RecallNotification(GetBlockedLicenseKeyNotificationId());
        NotificationMgt.RecallNotification(GetApphubUpdateFailedNotificationId());
    end;
    #endregion

    var
        JSONHelper: Codeunit "IDYM JSON Helper";
        NotificationMgt: Codeunit "IDYM Notification Management";
        NewLicenseRegistration: Boolean;
        PostponeWriteTransactions: Boolean;
        SkipLicenseCheckDuration: Integer;
        ReturnErrorCode: Integer;
        ErrorUnitName: Text;
        UnregisteredAppName: Text[50];
        AppUserName: Text[100];
        GenericErr: Label 'Something went wrong';
        Msg001Err: Label 'Tenant with ID %1 could not be found.', Comment = '%1=The tenant.'; //{usage.TenantId}
        Msg004Err: Label 'License Key %1 could not be found.', Comment = '%1=The license key.'; //{usage.LicenseKey}
        Msg005Err: Label 'License Key %1 is invalid', Comment = '%1=The license key.'; //{usage.LicenseKey}
        Msg006Err: Label 'License Key %1 is disabled.', Comment = '%1=The license key.'; //{usage.LicenseKey}
        Msg007Err: Label 'License Key %1 has expired.', Comment = '%1=The license key.'; //{usage.LicenseKey}
        Msg008Err: Label 'App with ID %1 could not be found.', Comment = '%1=The app id.'; //{usage.AppId}
        Msg009Err: Label 'License Key cannot be empty, please provide one.';
        Msg010Err: Label 'AppAction could not be found.'; //{usage.AppActionId}
        Msg011Err: Label 'Extension Setting could not be found.'; //{name} 
        Msg012Err: Label 'This license key has already been claimed.';
        Msg013Err: Label 'You have exceeded the number of allowed %1 for your license.', Comment = '%1 = unit name (dynamic)';
        Msg014Err: Label 'This license key is blocked due to missed payments.';
        RedirectMsg: Label 'See the %1 setup page to further inspect the issue.', Comment = '%1 = appname';
        UnitNameLbl: Label 'active units';
        AppUrlLbl: Label 'App', Locked = true;
        TrialLicenseKeyUrlLbl: Label 'LicenseKey/Trial', Locked = true;
}