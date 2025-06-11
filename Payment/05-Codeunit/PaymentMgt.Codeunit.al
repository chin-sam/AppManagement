codeunit 11155295 "IDYM Payment Mgt."
{
    internal procedure CreateCustomer(var IDYMCustomer: Record "IDYM Customer")
    var
        CompanyInformation: Record "Company Information";
    begin
        GetCompanyInformation(CompanyInformation);

        IDYMCustomer.Init();
        IDYMCustomer.Name := CompanyInformation.Name;
        IDYMCustomer.Email := CompanyInformation."E-Mail";
        IDYMCustomer.Address := CompanyInformation.Address;
        IDYMCustomer."Postal Code" := CompanyInformation."Post Code";
        IDYMCustomer.City := CompanyInformation.City;
        IDYMCustomer.State := CompanyInformation.County;
        IDYMCustomer."Country/Region Code" := CompanyInformation."Country/Region Code";
        IDYMCustomer.Insert();
    end;

    internal procedure GetSubscription(SubscriptionId: Text; var Subscription: Record "IDYM Subscription"; UpdateMode: Boolean)
    begin
        case PaymentProvider of
            // Provider::Stripe:
            //     RefreshData();
            PaymentProvider::Paypal:
                PaypalWebService.GetSubscription(SubscriptionId, AppId, LicenseKey, Subscription, UpdateMode);
        end;
    end;

    local procedure GetCompanyInformation(var CompanyInformation: Record "Company Information")
    begin
        if not CompanyInformation.Get() then
            CompanyInformation.Init();
    end;

    [NonDebuggable]
    internal procedure GetSelectedSubscription(var Module: Record "IDYM Module"; Subscription: Record "IDYM Subscription"; PricePlanId: Guid; TierId: Guid; CurrencyCode: Code[10]; TotalAmount: Decimal) SubscriptionDataAsText: Text
    var
        SubscriptionData: JsonObject;
        PricingPlanJsonArray: JsonArray;
        PricingPlanJsonObject: JsonObject;
        TierJsonObject: JsonObject;
        TierJsonArray: JsonArray;
        PriceJsonObject: JsonObject;
        PriceJsonArray: JsonArray;
        ModuleJsonObject: JsonObject;
        ModuleJsonArray: JsonArray;
        PaymentJsonObject: JsonObject;
    begin
        JSONHelper.AddValue(SubscriptionData, 'appId', DelChr(AppId, '<>', '{}'));
        JSONHelper.AddValue(SubscriptionData, 'startingDate', Subscription.Created);
        JSONHelper.AddValue(SubscriptionData, 'endingDate', Subscription."Valid Until");
        JSONHelper.AddValue(SubscriptionData, 'externalReference', Subscription.Id);
        JSONHelper.AddValue(PricingPlanJsonObject, 'id', PricePlanId);
        JSONHelper.Add(PricingPlanJsonArray, PricingPlanJsonObject);
        JSONHelper.Add(SubscriptionData, 'pricingPlans', PricingPlanJsonArray);

        JSONHelper.AddValue(TierJsonObject, 'id', TierId);
        JSONHelper.AddValue(PriceJsonObject, 'pricingPlanId', PricePlanId);
        JSONHelper.AddValue(PriceJsonObject, 'currency', CurrencyCode);
        JSONHelper.Add(PriceJsonArray, PriceJsonObject);
        JSONHelper.Add(TierJsonObject, 'prices', PriceJsonArray);
        JSONHelper.Add(TierJsonArray, TierJsonObject);
        JSONHelper.Add(SubscriptionData, 'tiers', TierJsonArray);

        if Module.FindSet() then begin
            repeat
                Clear(ModuleJsonObject);
                JSONHelper.AddValue(ModuleJsonObject, 'id', Module.Id);
                JSONHelper.Add(ModuleJsonObject, 'prices', PriceJsonArray);
                JSONHelper.Add(ModuleJsonArray, ModuleJsonObject);
            until Module.Next() = 0;
            JSONHelper.Add(SubscriptionData, 'modules', ModuleJsonArray);
        end;

        JSONHelper.AddValue(PaymentJsonObject, 'paymentMethod', Subscription."Payment Provider".Names().Get(Subscription."Payment Provider".Ordinals().IndexOf(Subscription."Payment Provider".AsInteger())));
        JSONHelper.AddValue(PaymentJsonObject, 'paymentId', Subscription.Id);
        JSONHelper.AddValue(PaymentJsonObject, 'pricePlanId', PricePlanId);
        JSONHelper.AddValue(PaymentJsonObject, 'paymentAmount', TotalAmount);
        JSONHelper.Add(SubscriptionData, 'payment', PaymentJsonObject);

        SubscriptionData.WriteTo(SubscriptionDataAsText);
    end;

    [NonDebuggable]
    internal procedure ExtractSubscriptionDetails(ResponseObject: JsonObject)
    var
        PricePlan: Record "IDYM Price Plan";
        Tier: Record "IDYM Tier";
        Module: Record "IDYM Module";
        AppPrice: Record "IDYM App Price";
        SubscriptionJsonObject: JsonObject;
        PricePlanJsonToken: JsonToken;
        TierJsonToken: JsonToken;
        PriceJsonToken: JsonToken;
        ModuleJsonToken: JsonToken;
        IntervalUnit: Text;
        ModuleType: Text;
    begin
        SubscriptionJsonObject := JSONHelper.GetObject(ResponseObject, 'subscription');

        AppPrice.Reset();
        if AppPrice.FindSet(true) then
            repeat
                AppPrice.SetUnrestricedAccess();
                AppPrice.Delete();
            until AppPrice.Next() = 0;

        PricePlan.Reset();
        if PricePlan.FindSet(true) then
            repeat
                PricePlan.SetUnrestricedAccess();
                PricePlan.Delete();
            until PricePlan.Next() = 0;
        foreach PricePlanJsonToken in JSONHelper.GetArray(SubscriptionJsonObject, 'pricingPlans') do begin
            PricePlan.Init();
            PricePlan.Id := JSONHelper.GetGuidValue(PricePlanJsonToken.AsObject(), 'id');
            PricePlan.Description := CopyStr(JSONHelper.GetTextValue(PricePlanJsonToken, 'description'), 1, MaxStrlen(PricePlan.Description));

            IntervalUnit := JSONHelper.GetTextValue(PricePlanJsonToken, 'intervalUnit');
            case UpperCase(IntervalUnit) of
                'YEARLY':
                    PricePlan.Interval := PricePlan.Interval::Year;
                'MONTHLY':
                    PricePlan.Interval := PricePlan.Interval::Month;
                'WEEKLY':
                    PricePlan.Interval := PricePlan.Interval::Week;
                'DAILY':
                    PricePlan.Interval := PricePlan.Interval::Day;
            end;
            PricePlan.Select := JSONHelper.GetBooleanValue(PricePlanJsonToken.AsObject(), 'isDefault');
            PricePlan."Interval Count" := JSONHelper.GetIntegerValue(PricePlanJsonToken, 'intervalCount');
            PricePlan.Validate("App Id", JSONHelper.GetGuidValue(SubscriptionJsonObject, 'appId'));
            PricePlan.SetUnrestricedAccess();
            PricePlan.Insert();
        end;

        Tier.Reset();
        if Tier.FindSet(true) then
            repeat
                Tier.SetUnrestricedAccess();
                Tier.Delete();
            until Tier.Next() = 0;
        foreach TierJsonToken in JSONHelper.GetArray(SubscriptionJsonObject, 'tiers') do begin
            Tier.Init();
            Tier.Id := JSONHelper.GetGuidValue(TierJsonToken.AsObject(), 'id');
            Tier.Description := CopyStr(JSONHelper.GetTextValue(TierJsonToken, 'description'), 1, MaxStrlen(Tier.Description));
            // Tier.Type // Units only
            Tier."Minimum Quantity" := JSONHelper.GetIntegerValue(TierJsonToken, 'minQty');
            Tier."Maximum Quantity" := JSONHelper.GetIntegerValue(TierJsonToken, 'maxQty');
            Tier."No Upper Limit" := JSONHelper.GetBooleanValue(TierJsonToken, 'noUpperLimit');
            Tier."App Id" := JSONHelper.GetGuidValue(SubscriptionJsonObject, 'appId');
            Tier.SetUnrestricedAccess();
            Tier.Insert();

            foreach PriceJsonToken in JSONHelper.GetArray(TierJsonToken, 'prices') do begin
                Clear(AppPrice);
                AppPrice.Init();
                AppPrice."App Id" := JSONHelper.GetGuidValue(SubscriptionJsonObject, 'appId');
                AppPrice."Tier ID" := Tier.Id;
                AppPrice."Price Plan ID" := JSONHelper.GetGuidValue(PriceJsonToken, 'pricingPlanId');
                AppPrice."Currency Code" := CopyStr(JSONHelper.GetCodeValue(PriceJsonToken, 'currency'), 1, MaxStrLen(AppPrice."Currency Code"));
                AppPrice."Unit Price" := JSONHelper.GetDecimalValue(PriceJsonToken, 'unitPrice');
                AppPrice."Total Price" := JSONHelper.GetDecimalValue(PriceJsonToken, 'totalPrice');
                AppPrice."VAT %" := JSONHelper.GetDecimalValue(PriceJsonToken, 'vat');
                AppPrice.SetUnrestricedAccess();
                AppPrice.Insert();
            end;
        end;

        Module.Reset();
        if Module.FindSet(true) then
            repeat
                Module.SetUnrestricedAccess();
                Module.Delete();
            until Module.Next() = 0;
        foreach ModuleJsonToken in JSONHelper.GetArray(SubscriptionJsonObject, 'modules') do begin
            Module.Init();
            Module.Id := JSONHelper.GetGuidValue(ModuleJsonToken.AsObject(), 'id');
            Module.Description := CopyStr(JSONHelper.GetTextValue(ModuleJsonToken.AsObject(), 'description'), 1, MaxStrlen(Module.Description));

            ModuleType := JSONHelper.GetTextValue(ModuleJsonToken.AsObject(), 'type');
            case LowerCase(ModuleType) of
                'applicationarea':
                    Module.Type := Module.Type::applicationarea;
                'company':
                    Module.Type := Module.Type::company;
            end;
            Module.Value := CopyStr(JSONHelper.GetTextValue(ModuleJsonToken.AsObject(), 'value'), 1, MaxStrlen(Module.Value));
            Module.Optional := JSONHelper.GetBooleanValue(ModuleJsonToken.AsObject(), 'isOptional');
            Module."App Id" := JSONHelper.GetGuidValue(SubscriptionJsonObject, 'appId');
            Module.Select := true;
            Module.SetUnrestricedAccess();
            Module.Insert();

            foreach PriceJsonToken in JSONHelper.GetArray(ModuleJsonToken, 'prices') do begin
                // key(PK; "App ID", "Tier ID", "Price Plan ID", "Module Id", "Starting Date", "Currency Code")
                Clear(AppPrice);

                AppPrice.Init();
                AppPrice."App Id" := JSONHelper.GetGuidValue(SubscriptionJsonObject, 'appId');
                AppPrice."Price Plan ID" := JSONHelper.GetGuidValue(PriceJsonToken, 'pricingPlanId');
                AppPrice."Module ID" := Module.Id;
                AppPrice."Currency Code" := CopyStr(JSONHelper.GetCodeValue(PriceJsonToken, 'currency'), 1, MaxStrLen(AppPrice."Currency Code"));
                AppPrice."Unit Price" := JSONHelper.GetDecimalValue(PriceJsonToken, 'unitPrice');
                AppPrice."Total Price" := JSONHelper.GetDecimalValue(PriceJsonToken, 'totalPrice');
                AppPrice.SetUnrestricedAccess();
                AppPrice.Insert();
            end;
        end;
    end;

    [NonDebuggable]
    internal procedure ExtractApphubSubscriptionDetails(ResponseObject: JsonObject; var ApphubSubscription: Record "IDYM Apphub Subscription")
    var
        SubscriptionJsonObject: JsonObject;
        SubscriptionId: Guid;
    begin
        SubscriptionJsonObject := JSONHelper.GetObject(ResponseObject, 'subscription');
        SubscriptionId := JSONHelper.GetGuidValue(SubscriptionJsonObject, 'id');

        if not ApphubSubscription.Get(SubscriptionId) then begin
            ApphubSubscription.Init();
            ApphubSubscription.Id := SubscriptionId;
            ApphubSubscription."License Key" := CopyStr(JSONHelper.GetTextValue(SubscriptionJsonObject, 'licenseKey'), 1, MaxStrLen(ApphubSubscription."License Key"));
            ApphubSubscription."App Id" := AppId;
            ApphubSubscription.SetUnrestricedAccess();
            ApphubSubscription.Insert();
        end;
        ApphubSubscription."Payment Due" := JSONHelper.GetDateTimeValue(SubscriptionJsonObject, 'paymentDue');
        ApphubSubscription."Payment Blocked" := JSONHelper.GetDateTimeValue(SubscriptionJsonObject, 'paymentBlocked');
        ApphubSubscription.SetUnrestricedAccess();
        ApphubSubscription.Modify();
    end;

    internal procedure SetProvider(NewPaymentProvider: Enum "IDYM Payment Provider")
    begin
        PaymentProvider := NewPaymentProvider;
    end;

    [Obsolete('Replaced with SetParameters()', '21.0')]
    internal procedure SetAppId(NewAppId: Guid)
    begin
        AppId := NewAppId;
    end;

    internal procedure SetParameters(NewAppId: Guid; NewLicenseKey: Text[50])
    begin
        AppId := NewAppId;
        LicenseKey := NewLicenseKey;
    end;

    #region RefreshData
    internal procedure RefreshData()
    var
        Product: Record "IDYM Product";
        Plan: Record "IDYM Plan";
        IsHandled: Boolean;
    begin
        OnBeforeRefreshData(PaymentProvider, AppId, IsHandled);
        if IsHandled then
            exit;

        Product.Reset();
        Product.SetRange("Payment Provider", PaymentProvider);
        if Product.FindSet(true) then
            repeat
                Product.SetUnrestricedAccess();
                Product.Delete();
            until Product.Next() = 0;

        Plan.Reset();
        Plan.SetRange("Payment Provider", PaymentProvider);
        if Plan.FindSet(true) then
            repeat
                Plan.SetUnrestricedAccess();
                Plan.Delete();
            until Plan.Next() = 0;

        case PaymentProvider of
            // Provider::Stripe:
            //     RefreshData();
            PaymentProvider::Paypal:
                begin
                    PaypalWebService.GetProducts(10, 1);
                    PaypalWebService.GetPlans(10, 1);
                end;
        end;

        OnAfterRefreshData(PaymentProvider, AppId);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRefreshData(PaymentProvider: Enum "IDYM Payment Provider"; AppId: Guid; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRefreshData(PaymentProvider: Enum "IDYM Payment Provider"; AppId: Guid)
    begin
    end;
    #endregion

    #region Notifications
    procedure CheckLicensePayment(CurrentNotification: Notification) //used as action in notification in Apphub codeunit
    var
        Subscription: Record "IDYM Subscription";
        AppLicenseKey: Record "IDYM App License Key";
        LicenseEntryNo: Integer;
        AppInfo: ModuleInfo;
    begin
        Evaluate(LicenseEntryNo, CurrentNotification.GetData('LicenseEntryNo'));
        AppLicenseKey.Get(LicenseEntryNo);
        NavApp.GetModuleInfo(AppLicenseKey."App Id", AppInfo);
        AppId := AppInfo.Id();
        Subscription.SetCurrentKey(Created);
        Subscription.SetRange("Product Guid", AppInfo.Id());
        Subscription.SetRange("License Key", AppLicenseKey."License Key");
        if Subscription.FindLast() then
            LicensePayment(LicenseEntryNo, Subscription.RecordId, true);
    end;

    procedure InitiateLicensePayment(CurrentNotification: Notification) //used as action in notification in Apphub codeunit
    var
        AppLicenseKey: Record "IDYM App License Key";
        SubscriptionWizard: Page "IDYM Subscription Wizard";
#if BC17        
        SubscriptionRecordId: RecordId;
#endif  
        AppInfo: ModuleInfo;
        LicenseEntryNo: Integer;
    begin
        Evaluate(LicenseEntryNo, CurrentNotification.GetData('LicenseEntryNo'));
        AppLicenseKey.Get(LicenseEntryNo);
        NavApp.GetModuleInfo(AppLicenseKey."App Id", AppInfo);
        AppId := AppInfo.Id();
        //GET LICENSE ID FROM CURRENT NOTIFICATION
        SubscriptionWizard.SetParameters(AppInfo.Id(), AppLicenseKey."License Key");
        SubscriptionWizard.RunModal();
#if BC17
        if SubscriptionWizard.IsCompleted() then begin
            SubscriptionWizard.GetSubscriptionRecId(SubscriptionRecordId);
            LicensePayment(LicenseEntryNo, SubscriptionRecordId, true)
        end;
#else
        if SubscriptionWizard.IsCompleted() then
            LicensePayment(LicenseEntryNo, SubscriptionWizard.GetSubscriptionRecId(), true)
#endif
    end;

    procedure UnblockLicense(CurrentNotification: Notification) //used as action in notification in Apphub codeunit
    var
        ApphubSubscription: Record "IDYM Apphub Subscription";
        SubscriptionId: Guid;
    begin
        SubscriptionId := CurrentNotification.GetData('SubscriptionId');
        ApphubSubscription.Get(SubscriptionId);
        Page.RunModal(Page::"IDYM Apphub Subscription", ApphubSubscription);
    end;

    [NonDebuggable]
    local procedure LicensePayment(LicenseEntryNo: Integer; SubscriptionRecordId: RecordId; ThrowError: Boolean)
    var
        IDYMCustomer: Record "IDYM Customer";
        Subscription: Record "IDYM Subscription";
        Plan: Record "IDYM Plan";
        Module: Record "IDYM Module";
        PricePlan: Record "IDYM Price Plan";
        AppLicenseKey: Record "IDYM App License Key";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Apphub: Codeunit "IDYM Apphub";
        NotificationMgt: Codeunit "IDYM Notification Management";
        RequestJsonObject: JsonObject;
        ErrorMessage: Text;
        JsonObjectAsText: Text;
        TotalAmount: Decimal;
        ErrorCode: Integer;
        CurrencyCode: Code[10];
        UsedTierId: Guid;
        UpdatedLicenseKeyMsg: Label 'The license has been successfully updated. If the license status doesn''t reflect that, then please reopen the page.';
    begin
        AppLicenseKey.Get(LicenseEntryNo);
        if not Subscription.Get(SubscriptionRecordId) then
            exit;

        if not Plan.Get(Subscription."Plan Id", Subscription."Payment Provider") then
            exit;

        JsonObjectAsText := Subscription.GetSubscriptionData();
        if JsonObjectAsText = '' then begin //When FINISH button is not used in the wizard then SUBSCRIPTION DATA cannot be found
            GetSubscription(Subscription.Id, Subscription, false);
            // AppHub data
            Module.SetRange("App Id", AppId);
            Module.SetRange(Select, true);
            if Module.FindFirst() then;
            PricePlan.SetRange("App Id", AppId);
            PricePlan.SetRange(Select, true);
            PricePlan.FindFirst();
            GeneralLedgerSetup.Get();
            if GeneralLedgerSetup."LCY Code" in ['EUR', 'USD'] then
                CurrencyCode := GeneralLedgerSetup."LCY Code"
            else
                CurrencyCode := 'EUR';
            IDYMCustomer.FindFirst();
            TotalAmount := CalculateSubscriptionAmount(IDYMCustomer, PricePlan, CurrencyCode);
            UsedTierId := PricePlan.GetTierId();
            Subscription.SetSubscriptionData(GetSelectedSubscription(Module, Subscription, PricePlan.Id, UsedTierId, CurrencyCode, TotalAmount));
            Subscription.SetUnrestricedAccess();
            Subscription.Modify();
        end else
            RequestJsonObject.ReadFrom(JsonObjectAsText);
        JSONHelper.AddValue(RequestJsonObject, 'licenseKey', AppLicenseKey."License Key");
        if AppHub.LicensePayment(LicenseEntryNo, AppId, RequestJsonObject, ErrorMessage, ErrorCode, ThrowError) then
            NotificationMgt.SendNotification(GetUpdatedLicenseKeyNotificationId(), UpdatedLicenseKeyMsg);
    end;

    internal procedure CalculateSubscriptionAmount(IDYMCustomer: Record "IDYM Customer"; var PricePlan: Record "IDYM Price Plan"; CurrencyCode: Code[10]) TotalAmount: Decimal
    var
        Module: Record "IDYM Module";
        VATPercentage: Decimal;
    begin
        TotalAmount := PricePlan.GetPricePlanPrice(CurrencyCode, VATPercentage);
        Module.SetRange("App Id", PricePlan."App Id");
        if Module.FindSet() then
            repeat
                TotalAmount += Module.GetModulePrice(CurrencyCode, 0, PricePlan.Id);
            until Module.Next() = 0;
        if IDYMCustomer.IncludeVATAmount() then
            TotalAmount := Round(TotalAmount * (1 + VATPercentage / 100), 0.01, '=');
    end;

    local procedure GetUpdatedLicenseKeyNotificationId(): Guid
    begin
        exit('95353738-0343-44b1-8bed-536c50aac7f5');
    end;
    #endregion

    [EventSubscriber(ObjectType::Table, Database::"Company Information", 'OnAfterModifyEvent', '', true, false)]
    local procedure CompanyInformation_OnAfterModify(var Rec: Record "Company Information"; var xRec: Record "Company Information"; RunTrigger: Boolean)
    var
        IDYMCustomer: Record "IDYM Customer";
        Company: Record Company;
        UpdateCustomer: Boolean;
        SyncQst: Label 'Do you want to update Customer details used in the payment application, with the new Company Information?';
    begin
        if not RunTrigger then
            exit;
        if Rec.IsTemporary() then
            exit;
        Company.Get(CompanyName());

        if Not Company."Evaluation Company" then begin
            if IDYMCustomer.FindFirst() then;

            if (IDYMCustomer.Name = '') or (IDYMCustomer.Email = '') then
                UpdateCustomer := true;
            if not UpdateCustomer and GuiAllowed() then
                if (xRec.Name <> Rec.Name) or
                    (xRec."E-Mail" <> Rec."E-Mail") or
                    (xRec.Address <> Rec.Address) or
                    (xRec."Post Code" <> Rec."Post Code") or
                    (xRec.City <> Rec.City) or
                    (xRec.County <> Rec.County) or
                    (xRec."Country/Region Code" <> Rec."Country/Region Code")
                then
                    if Confirm(SyncQst) then
                        UpdateCustomer := true;

            if UpdateCustomer then
                if IDYMCustomer.FindFirst() then begin
                    IDYMCustomer.Name := Rec.Name;
                    IDYMCustomer.Email := Rec."E-Mail";
                    IDYMCustomer.Address := Rec.Address;
                    IDYMCustomer."Postal Code" := Rec."Post Code";
                    IDYMCustomer.City := Rec.City;
                    IDYMCustomer.State := Rec.County;
                    IDYMCustomer."Country/Region Code" := Rec."Country/Region Code";
                    IDYMCustomer.Modify();

                    //UpdateCustomer(IDYMCustomer);
                end else
                    CreateCustomer(IDYMCustomer);
        end;
    end;

    var
        PaypalWebService: Codeunit "IDYM Paypal Web Service";
        JSONHelper: Codeunit "IDYM JSON Helper";
        PaymentProvider: Enum "IDYM Payment Provider";
        AppId: Guid;
        LicenseKey: Text[50];
}