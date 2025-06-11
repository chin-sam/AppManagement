codeunit 11155296 "IDYM Paypal Web Service"
{
    var
        HTTPHelper: Codeunit "IDYM HTTP Helper";
        JSONHelper: Codeunit "IDYM JSON Helper";
        StatusCode: Integer;
        CurrencyCode: Code[10];
        Interval: Integer;
        ProductId: Text[50];
        TotalAmount: Decimal;
        OneTimePayment: Boolean;

    #region [Products]
    internal procedure GetProducts(PageSize: Integer; PageNo: Integer)
    var
        ProdPathLbl: Label 'v1/catalogs/products?page_size=%1&page=%2', Locked = true;
    begin
        GetProducts(StrSubstNo(ProdPathLbl, PageSize, PageNo))
    end;

    local procedure GetProducts(Path: Text)
    var
        PaymentSetup: Record "IDYM Payment Setup";
        TempRestParameters: Record "IDYM REST Parameters" temporary;
        GetProductsFailedErr: Label 'Could not get available products: %1', Comment = '%1 - Error Message';
    begin
        TempRestParameters.Init();
        if PaymentSetup.Get() then
            TempRestParameters."Acceptance Environment" := PaymentSetup.Sandbox;
        TempRestParameters.Path := CopyStr(Path, 1, MaxStrLen(TempRestParameters.Path));
        TempRestParameters.RestMethod := TempRestParameters.RestMethod::GET;

        StatusCode := HTTPHelper.Execute(TempRestParameters, "IDYM Endpoint Service"::Paypal, "IDYM Endpoint Usage"::Default);
        if not (StatusCode in [200, 201]) then
            ParseError(GetProductsFailedErr, TempRestParameters.GetResponseBodyAsJSON(), true);
        ProcessProducts(TempRestParameters.GetResponseBodyAsJSON());
    end;

    [NonDebuggable]
    local procedure ProcessProducts(Response: JsonToken)
    var
        Product: Record "IDYM Product";
        JToken: JsonToken;
        DataArray: JsonArray;
        Data: JsonObject;
        LinkArray: JsonArray;
        NextLink: Text;
    begin
        Response.AsObject().Get('products', JToken);
        DataArray := JToken.AsArray();
        foreach JToken in DataArray do begin
            Data := JToken.AsObject();
            Product.Init();
            Product.Id := CopyStr(JSONHelper.GetTextValue(Data, 'id'), 1, MaxStrLen(Product.Id));
            Product."Payment Provider" := Product."Payment Provider"::Paypal;
            Product.Name := CopyStr(JSONHelper.GetTextValue(Data, 'name'), 1, MaxStrLen(Product.Name));
            Product."Product Guid" := CopyStr(JSONHelper.GetGuidValue(Data, 'id'), 1, MaxStrLen(Product.Id));
            if not IsNullGuid(Product."Product Guid") then begin
                Product.SetUnrestricedAccess();
                Product.Insert();
            end;
        end;

        LinkArray := JSONHelper.GetArray(Response, 'links');
        NextLink := GetNextLink(LinkArray);
        if NextLink <> '' then
            GetProducts(NextLink);
    end;
    #endregion

    #region [Plans]
    internal procedure GetPlans(PageSize: Integer; PageNo: Integer)
    var
        PlanPathLbl: Label 'v1/billing/plans?page_size=%1&page=%2', Locked = true;
    begin
        GetPlans(StrSubstNo(PlanPathLbl, PageSize, PageNo))
    end;

    [NonDebuggable]
    local procedure GetPlans(Path: Text)
    var
        TempRestParameters: Record "IDYM REST Parameters" temporary;
        PaymentSetup: Record "IDYM Payment Setup";
        HttpHeaderValues: Dictionary of [Text, Text];
        GetPlansFailedErr: Label 'Could not get available plans: %1', Comment = '%1 - Error Message';
    begin
        TempRestParameters.Init();
        if PaymentSetup.Get() then
            TempRestParameters."Acceptance Environment" := PaymentSetup.Sandbox;
        TempRestParameters.Path := CopyStr(Path, 1, MaxStrLen(TempRestParameters.Path));
        TempRestParameters.RestMethod := TempRestParameters.RestMethod::GET;

        HttpHeaderValues.Add('Prefer', 'return=representation');
        TempRestParameters.SetAdditionalRequestHttpHeaders(HttpHeaderValues);

        StatusCode := HTTPHelper.Execute(TempRestParameters, "IDYM Endpoint Service"::Paypal, "IDYM Endpoint Usage"::Default);
        if not (StatusCode in [200, 201]) then
            ParseError(GetPlansFailedErr, TempRestParameters.GetResponseBodyAsJSON(), true);
        ProcessPlans(TempRestParameters.GetResponseBodyAsJSON());
    end;

    [NonDebuggable]
    local procedure ProcessPlans(Response: JsonToken)
    var
        Plan: Record "IDYM Plan";
        JToken: JsonToken;
        DataArray: JsonArray;
        Data: JsonObject;
        BillingCycleJsonToken: JsonToken;
        BillingCycleDataJsonArray: JsonArray;
        BillingCycle: JsonObject;
        PricingSchemeJsonToken: JsonToken;
        FrequencyJsonToken: JsonToken;
        PricingScheme: JsonObject;
        Frequency: JsonObject;
        Status: Text;
        TenureType: Text;
        LinkArray: JsonArray;
        NextLink: Text;
    begin
        Response.AsObject().Get('plans', JToken);
        DataArray := JToken.AsArray();
        foreach JToken in DataArray do begin
            Data := JToken.AsObject();
            Status := JSONHelper.GetTextValue(Data, 'status');
            if (Status = 'ACTIVE') and Data.Get('billing_cycles', BillingCycleJsonToken) then begin
                Plan.Init();
                Plan.Id := CopyStr(JSONHelper.GetTextValue(Data, 'id'), 1, MaxStrLen(Plan.Id));
                Plan."Payment Provider" := Plan."Payment Provider"::Paypal;
                Plan."Product Id" := CopyStr(JSONHelper.GetTextValue(Data, 'product_id'), 1, MaxStrLen(Plan."Product Id"));


                Plan.Active := true;

                BillingCycleDataJsonArray := BillingCycleJsonToken.AsArray();
                foreach BillingCycleJsonToken in BillingCycleDataJsonArray do begin
                    BillingCycle := BillingCycleJsonToken.AsObject();
                    TenureType := JSONHelper.GetTextValue(BillingCycle, 'tenure_type');
                    case UpperCase(TenureType) of
                        'REGULAR':
                            begin
                                BillingCycle.Get('pricing_scheme', PricingSchemeJsonToken);
                                if PricingSchemeJsonToken.AsObject().Get('fixed_price', PricingSchemeJsonToken) then begin
                                    PricingScheme := PricingSchemeJsonToken.AsObject();
                                    Plan.Amount := JSONHelper.GetDecimalValue(PricingScheme, 'value');
                                    Plan.Currency := CopyStr(JSONHelper.GetTextValue(PricingScheme, 'currency_code'), 1, MaxStrLen(Plan.Currency));
                                end;
                                BillingCycle.Get('frequency', FrequencyJsonToken);
                                Frequency := FrequencyJsonToken.AsObject();
                                Evaluate(Plan.Interval, JSONHelper.GetTextValue(Frequency, 'interval_unit'));
                                Plan."Interval Count" := JSONHelper.GetIntegerValue(Frequency, 'interval_count');
                            end;
                        'TRIAL':
                            begin
                                BillingCycle.Get('frequency', FrequencyJsonToken);
                                Frequency := FrequencyJsonToken.AsObject();
                                Evaluate(Plan."Trial Period Interval", JSONHelper.GetTextValue(Frequency, 'interval_unit'));
                                Plan."Trial Period" := JSONHelper.GetIntegerValue(Frequency, 'interval_count');
                            end;
                    end;
                end;
                Plan.SetUnrestricedAccess();
                Plan.Insert();
            end;
        end;

        LinkArray := JSONHelper.GetArray(Response, 'links');
        NextLink := GetNextLink(LinkArray);
        if NextLink <> '' then
            GetPlans(NextLink);
    end;
    #endregion

    #region [Order]
    internal procedure CreateOrderRequest(IDYMAppLicenseKey: Record "IDYM App License Key") ReqJsonObject: JsonObject
    var
        ValueToAdd: JsonValue;
        Amount: JsonObject;
        PurchaseUnit: JsonObject;
        PurchaseUnitsArr: JsonArray;
    begin
        IDYMAppLicenseKey.TestField("Unit Price");
        ValueToAdd.SetValue(IDYMAppLicenseKey."Unit Price");
        Amount.Add('value', ValueToAdd);

        PurchaseUnit.Add('amount', Amount);

        PurchaseUnitsArr.Add(PurchaseUnit);
        ReqJsonObject.Add('purchase_units', PurchaseUnitsArr);
    end;

    internal procedure CaptureOrderResponse(ResponseObject: JsonObject; var AppLicenseKey: Record "IDYM App License Key")
    begin
        case Uppercase(JsonHelper.GetJsonValueByPath(ResponseObject.AsToken(), '$.purchase_units[0].payments.captures[0].status').AsText()) of
            'CREATED':
                AppLicenseKey."Payment Status" := AppLicenseKey."Payment Status"::Created;
            'SAVED':
                AppLicenseKey."Payment Status" := AppLicenseKey."Payment Status"::Saved;
            'APPROVED':
                AppLicenseKey."Payment Status" := AppLicenseKey."Payment Status"::Approved;
            'VOIDED':
                AppLicenseKey."Payment Status" := AppLicenseKey."Payment Status"::Voided;
            'COMPLETED', 'ACTIVE':
                AppLicenseKey."Payment Status" := AppLicenseKey."Payment Status"::Completed;
            'ACTION REQUIRED', 'CANCELLED':
                AppLicenseKey."Payment Status" := AppLicenseKey."Payment Status"::"Action Required";
            'ERROR':
                AppLicenseKey."Payment Status" := AppLicenseKey."Payment Status"::Error;
        end;
        AppLicenseKey."Payment Provider" := AppLicenseKey."Payment Provider"::Paypal;
        AppLicenseKey."Payment Id" := CopyStr(JsonHelper.GetJsonValueByPath(ResponseObject.AsToken(), '$.purchase_units[0].payments.captures[0].id').AsText(), 1, MaxStrLen(AppLicenseKey."Payment Id"));
        AppLicenseKey."Order Id" := CopyStr(JsonHelper.GetJsonValueByPath(ResponseObject.AsToken(), '$.id').AsText(), 1, MaxStrLen(AppLicenseKey."Payment Id"));
        AppLicenseKey.Modify();
    end;
    #endregion

    #region [Subscription]
    [Obsolete('Replaced with same function with additional parameters', '21.0')]
    internal procedure GetSubscription(SubscriptionId: Text; var Subscription: Record "IDYM Subscription"; UpdateMode: Boolean)
    begin
    end;

    [Obsolete('Added new parameters to FindOrCreateSubscription', '21.0')]
    internal procedure FindOrCreateSubscription(SubscriptionId: Text; var Subscription: Record "IDYM Subscription")
    begin
    end;

    internal procedure GetSubscription(SubscriptionId: Text; AppId: Guid; LicenseKey: Text[50]; var Subscription: Record "IDYM Subscription"; UpdateMode: Boolean)
    var
        TempRestParameters: Record "IDYM REST Parameters" temporary;
        PaymentSetup: Record "IDYM Payment Setup";
        AppInfo: ModuleInfo;
        AppMgtAppInfo: ModuleInfo;
        GetSubscriptionFailedErr: Label 'Could not get Paypal subscription (%1) details for %2', Comment = '%1 = Subscription id, %2 = appname';
        CreatedSubscriptionFailedErr: Label 'The paypal subscription (%1) for %2 doesn''t exist. If you already completed a payment, please notice that it''s just a reservation. Please contact idyn for further assistance. Paypal returned the following message: ', Comment = '%1 = Subscription id, %2 = appname';
        SubscriptionPathLbl: Label 'v1/billing/subscriptions/%1', Locked = true;
    begin
        TempRestParameters.Init();
        if PaymentSetup.Get() then
            TempRestParameters."Acceptance Environment" := PaymentSetup.Sandbox;
        TempRestParameters.Path := StrSubstNo(SubscriptionPathLbl, SubscriptionId);
        TempRestParameters.RestMethod := TempRestParameters.RestMethod::GET;

        StatusCode := HTTPHelper.Execute(TempRestParameters, "IDYM Endpoint Service"::Paypal, "IDYM Endpoint Usage"::Default);
        if not (StatusCode in [200, 201]) then begin
            NavApp.GetModuleInfo(AppId, AppInfo);
            if StatusCode = 404 then begin
                NavApp.GetCurrentModuleInfo(AppMgtAppInfo);
                Subscription.SetUnrestricedAccess();
                Subscription.Delete();
                ParseError(StrSubstNo(CreatedSubscriptionFailedErr, Subscription.Id, AppInfo.Name) + ': %1', TempRestParameters.GetResponseBodyAsJSON(), true);
            end else
                ParseError(StrSubstNo(GetSubscriptionFailedErr, Subscription.Id, AppInfo.Name) + ': %1', TempRestParameters.GetResponseBodyAsJSON(), true);
            exit;
        end;
        if not UpdateMode then
            FindOrCreateSubscription(SubscriptionId, AppId, LicenseKey, Subscription);

        ProcessSubscription(TempRestParameters.GetResponseBodyAsJsonObject(), Subscription);
        Subscription.TestField("License Key");
        Subscription.SetUnrestricedAccess();
        Subscription.Modify();
    end;

    internal procedure FindOrCreateSubscription(SubscriptionId: Text; AppId: Guid; LicenseKey: Text[50]; var Subscription: Record "IDYM Subscription")
    begin
        if not Subscription.Get(SubscriptionId) then begin
            Subscription.Init();
            Subscription.Id := CopyStr(SubscriptionId, 1, MaxStrLen(Subscription.Id));
            Subscription."License Key" := LicenseKey;
            Subscription."Product Guid" := AppId;
            Subscription."Payment Provider" := Subscription."Payment Provider"::Paypal;
            Subscription.Status := Subscription.Status::Unknown;
            Subscription.SetUnrestricedAccess();
            Subscription.Insert();
        end;
    end;

    [NonDebuggable]
    local procedure ProcessSubscription(Data: JsonObject; var Subscription: Record "IDYM Subscription")
    var
        Plan: Record "IDYM Plan";
        Product: Record "IDYM Product";
        ErrorMessage: Text;
        AppInfo: ModuleInfo;
        LastPaymentJsonValue: JsonValue;
        LastPaymentDateTime: DateTime;
        SubscriptionStatusErr: Label 'There is an issue with the status (%1) of the subscription %2 for %3. The payment is not captured correctly on paypal.', Comment = '%1 = subscription status, %2 = paypal subscription id, %3 = appname';
        RedirectMsg: Label 'See the %1 setup page to further inspect the issue.', Comment = '%1 = appname';
        RedirectErr: Label '%1 %2', Locked = true;
        ErrorNotificationMsgTok: Label 'a1c44c7d-5cd6-422b-a618-c865bc9428a2', Locked = true;
    begin
        //  https://developer.paypal.com/docs/subscriptions/integrate/
        JSONHelper.TryGetJsonValuePath(Data.AsToken(), '$.billing_info.last_payment.time', LastPaymentJsonValue);
        if LastPaymentJsonValue.IsNull() then begin
            //last payment not present in this stage means status error on paypal
            NavApp.GetCurrentModuleInfo(AppInfo);
            ErrorMessage := StrSubstNo(SubscriptionStatusErr, Subscription.Status, Subscription.Id, AppInfo.Name);
            if GuiAllowed() then begin
                NotificationMgt.SendNotification(ErrorNotificationMsgTok, ErrorMessage);
                exit;
            end else
                Error(RedirectErr, ErrorMessage, StrSubstNo(RedirectMsg, AppInfo.Name));
        end;

        Subscription.Created := JSONHelper.GetDateTimeValue(Data, 'create_time');
        LastPaymentDateTime := JSONHelper.GetDateTimeValue(LastPaymentJsonValue.AsText());

        Plan.Get(CopyStr(JSONHelper.GetTextValue(Data, 'plan_id'), 1, MaxStrLen(Plan.Id)), Plan."Payment Provider"::Paypal);
        Subscription."Valid Until" := CalculateValidUntilBasedOnInterval(Plan, LastPaymentDateTime);
        Subscription.Validate("Status (External)", CopyStr(JSONHelper.GetTextValue(Data, 'status'), 1, MaxStrLen(Subscription."Status (External)")));
        Subscription.Quantity := JSONHelper.GetIntegerValue(Data, 'quantity');
        Subscription."Plan Id" := Plan.Id;

        Product.Get(Plan."Product Id", Product."Payment Provider"::Paypal);
        Subscription."Product Id" := Product.Id;
        Subscription."Product Guid" := Product."Product Guid";
    end;

    local procedure CalculateValidUntilBasedOnInterval(var Plan: Record "IDYM Plan"; LastPaymentDateTime: DateTime): DateTime
    var
        DayCountExprLbl: Label '<1D>', Locked = true;
        WeekCountExprLbl: Label '<1W>', Locked = true;
        MonthCountExprLbl: Label '<1M>', Locked = true;
        YearCountExprLbl: Label '<1Y>', Locked = true;
    begin
        case Plan.Interval of
            Plan.Interval::day:
                exit(CreateDateTime(CalcDate(DayCountExprLbl, DT2Date(LastPaymentDateTime)), DT2Time(LastPaymentDateTime)));
            Plan.Interval::week:
                exit(CreateDateTime(CalcDate(WeekCountExprLbl, DT2Date(LastPaymentDateTime)), DT2Time(LastPaymentDateTime)));
            Plan.Interval::month:
                exit(CreateDateTime(CalcDate(MonthCountExprLbl, DT2Date(LastPaymentDateTime)), DT2Time(LastPaymentDateTime)));
            Plan.Interval::year:
                exit(CreateDateTime(CalcDate(YearCountExprLbl, DT2Date(LastPaymentDateTime)), DT2Time(LastPaymentDateTime)));
        end;
    end;

    [NonDebuggable]
    internal procedure GetSubscriptionReqObject(var PricePlan: Record "IDYM Price Plan"; var IDYMCustomer: Record "IDYM Customer") ReqJsonObject: JsonObject
    var
        Integer: Record Integer;
        Plan: Record "IDYM Plan";
        PaymentContext: JsonObject;
        VATPercentage: Decimal;
        NoVATFoundErr: Label 'No VAT % specified in price plan %1', Comment = '%1 = Price Plan Id';
        MultiplePlansFoundErr: Label 'Unable to associate the correct PayPal plan due to the presence of multiple plans.';
    begin
        IDYMCustomer.CalcFields("Country/Region ISO Code");

        // Get associated plan
        Plan.Reset();
        Plan.SetRange("Payment Provider", Plan."Payment Provider"::Paypal);
        Plan.SetRange(Active, true);
        Plan.SetRange("Product Id", ProductId);
        Plan.SetRange(Currency, CurrencyCode);
        Plan.SetRange(Interval, Interval);
        if Plan.Count() > 1 then
            Error(MultiplePlansFoundErr);
        Plan.FindLast();

        if IDYMCustomer.IncludeVATAmount() then begin
            PricePlan.GetPricePlanPrice(CurrencyCode, VATPercentage);
            if VATPercentage = 0 then
                Error(NoVATFoundErr, PricePlan.Id);
        end;

        JSONHelper.AddValue(ReqJsonObject, 'plan_id', Plan.Id);
        JSONHelper.Add(ReqJsonObject, 'subscriber', GetSubscriberObject(IDYMCustomer));
        JSONHelper.Add(ReqJsonObject, 'plan', GetPlanObject(IDYMCustomer, VATPercentage));

        // PaymentContext
        Integer.Get(PricePlan.Id_Int);
        Integer.SetRecFilter();
        PaymentContext.Add('return_url', GetUrl(CLIENTTYPE::Default, CompanyName, OBJECTTYPE::Page, Page::"IDYM Paypal Payment Redirect", Integer, true));
        PaymentContext.Add('user_action', 'SUBSCRIBE_NOW');
        ReqJsonObject.Add('application_context', PaymentContext);
        //to do add "supplementary_data" reference to app and username
    end;

    [NonDebuggable]
    local procedure GetSubscriberObject(var IDYMCustomer: Record "IDYM Customer") Subscriber: JsonObject
    var
        SubscriberName: JsonObject;
        ShippingAddress: JsonObject;
        NameObject: JsonObject;
        Address: JsonObject;
    begin
        JSONHelper.AddValue(Subscriber, 'email_address', IDYMCustomer.Email);

        // name
        JSONHelper.AddValue(SubscriberName, 'given_name', IDYMCustomer.Name);
        //JSONHelper.AddValue(SubscriberName, 'surname', '');
        JSONHelper.Add(Subscriber, 'name', SubscriberName);

        // shipping_address
        //  name
        JSONHelper.AddValue(NameObject, 'full_name', IDYMCustomer.Name);
        JSONHelper.Add(ShippingAddress, 'name', NameObject);

        //  address
        JSONHelper.AddValue(Address, 'address_line_1', IDYMCustomer.Address);
        JSONHelper.AddValue(Address, 'address_line_2', IDYMCustomer."Address 2");
        JSONHelper.AddValue(Address, 'admin_area_2', IDYMCustomer.City);
        JSONHelper.AddValue(Address, 'admin_area_1', IDYMCustomer.State);
        JSONHelper.AddValue(Address, 'postal_code', IDYMCustomer."Postal Code");
        JSONHelper.AddValue(Address, 'country_code', IDYMCustomer."Country/Region ISO Code");
        JSONHelper.Add(ShippingAddress, 'address', Address);
        JSONHelper.Add(Subscriber, 'shipping_address', ShippingAddress);
    end;

    [NonDebuggable]
    local procedure GetPlanObject(var IDYMCustomer: Record "IDYM Customer"; VATPercentage: Decimal) Plan: JsonObject
    var
        FixedPrice: JsonObject;
        PrichingScheme: JsonObject;
        BillingCycle: JsonObject;
        BillingCycleArr: JsonArray;
        Taxes: JsonObject;
    begin
        // pricing_scheme
        JSONHelper.AddValue(FixedPrice, 'currency_code', CurrencyCode);
        JSONHelper.AddValue(FixedPrice, 'value', TotalAmount);
        JSONHelper.Add(PrichingScheme, 'fixed_price', FixedPrice);
        JSONHelper.Add(BillingCycle, 'pricing_scheme', PrichingScheme);

        // vat
        if IDYMCustomer.IncludeVATAmount() then begin
            JSONHelper.AddValue(Taxes, 'inclusive', true);
            JSONHelper.AddValue(Taxes, 'percentage', VATPercentage);
            JSONHelper.Add(Plan, 'taxes', Taxes);
        end;

        // billing_cycles   
        //   https://developer.paypal.com/docs/api/subscriptions/v1/#definition-billing_cycle
        JSONHelper.AddValue(BillingCycle, 'tenure_type', 'REGULAR');
        JSONHelper.AddValue(BillingCycle, 'sequence', 1);
        if OneTimePayment then
            JSONHelper.AddValue(BillingCycle, 'total_cycles', 1)
        else
            JSONHelper.AddValue(BillingCycle, 'total_cycles', 0);

        JSONHelper.Add(BillingCycleArr, BillingCycle);
        JSONHelper.Add(Plan, 'billing_cycles', BillingCycleArr);
    end;
    #endregion

    internal procedure SetParameters(NewCurrencyCode: Code[10]; NewProductId: Text[50]; NewInterval: Integer; NewTotalAmount: Decimal; NewOneTimePayment: Boolean)
    begin
        ProductId := NewProductId;
        CurrencyCode := NewCurrencyCode;
        Interval := NewInterval;
        TotalAmount := NewTotalAmount;
        OneTimePayment := NewOneTimePayment;
    end;

    local procedure ParseError(GeneralErrorText: Text; ErrorToken: JsonToken; ShowAsNotification: Boolean)
    var
        ErrMessage: Text;
        UnknownErr: Label 'Unknown error. Please try again.';
        ParseErr: Label 'Invalid error object.';
        ErrorNotificationMsgTok: Label '13057b66-11f9-4285-b77b-dfd2d0d3099c', Locked = true;
    begin
        if not GuiAllowed() then
            ShowAsNotification := false;

        if not ErrorToken.IsObject() then
            Error(ParseErr);

        ErrMessage := JSONHelper.GetTextValue(ErrorToken, 'message');
        if ErrMessage = '' then
            ErrMessage += ': ' + UnknownErr;

        if ShowAsNotification and GuiAllowed() then
            NotificationMgt.SendNotification(ErrorNotificationMsgTok, StrSubstNo(GeneralErrorText, ErrMessage))
        else
            Error(GeneralErrorText, ErrMessage)
    end;

    local procedure GetNextLink(LinkArray: JsonArray): Text;
    var
        LinkToken: JsonToken;
        LinkObject: JsonObject;
    begin
        foreach LinkToken in LinkArray do begin
            LinkObject := LinkToken.AsObject();
            if Uppercase(JSONHelper.GetTextValue(LinkObject, 'rel')) = 'NEXT' then
                exit(JSONHelper.GetTextValue(LinkObject, 'href'));
        end;
    end;

    #region Paypal Bearer Token
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"IDYM HTTP Helper", 'OnGetBearerToken', '', true, false)]
    local procedure OnGetBearerToken(Endpoint: Record "IDYM Endpoint"; var BearerToken: Text; var ExpiryInMS: Integer)
    begin
        if Endpoint.Service <> Endpoint.Service::Paypal then
            exit;
        if Endpoint."Authorization Type" <> Endpoint."Authorization Type"::Bearer then
            exit;
        GetBearerToken(BearerToken, ExpiryInMS);
    end;

    [NonDebuggable]
    local procedure GetBearerToken(var BearerToken: Text; var ExpiryInMS: Integer) StatusCode: Integer
    var
        PaymentSetup: Record "IDYM Payment Setup";
        TempRestParameters: Record "IDYM REST Parameters" temporary;
    begin
        if PaymentSetup.Get() then
            TempRestParameters."Acceptance Environment" := PaymentSetup.Sandbox;
        TempRestParameters.RestMethod := TempRestParameters.RestMethod::POST;
        StatusCode := HTTPHelper.Execute(TempRestParameters, "IDYM Endpoint Service"::Paypal, "IDYM Endpoint Usage"::GetToken);
        ProcessBearerTokenResponse(TempRestParameters, BearerToken, ExpiryInMS);
    end;

    [NonDebuggable]
    local procedure ProcessBearerTokenResponse(var TempRestParameters: Record "IDYM REST Parameters" temporary; var BearerToken: Text; var ExpiryInMS: Integer): Boolean
    var
        ResponseString: Text;
        ResponseObject: JsonObject;
        BearerTokenErr: Label 'Retrieving the Bearer token failed with HTTP Status %1', Comment = '%1 = HTTP Status Code';
    begin
        ResponseString := TempRestParameters.GetResponseBodyAsString();
        if not ResponseObject.ReadFrom(ResponseString) then
            Error(ResponseString);

        if TempRestParameters."Status Code" <> 200 then
            Error(BearerTokenErr, TempRestParameters."Status Code");
        BearerToken := JSONHelper.GetTextValue(ResponseObject, 'access_token');
        ExpiryInMS := JSONHelper.GetIntegerValue(ResponseObject, 'expires_in');
        exit(true);
    end;
    #endregion
    var
        NotificationMgt: Codeunit "IDYM Notification Management";
}