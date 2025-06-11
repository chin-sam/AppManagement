// codeunit 11155298 "IDYM Stripe Web Service"
// {
//     var
//         IDYMHTTPHelper: Codeunit "IDYM HTTP Helper";
//         IDYMJSONHelper: Codeunit "IDYM JSON Helper";
//         CustomersListLbl: Label 'customers/%1', Locked = true;
//         SubcriptionsListLbl: Label 'subscriptions/%1', Locked = true;
//         FormUrlEncodedContentTypeLbl: Label 'application/x-www-form-urlencoded', Locked = true;
//         StatusCode: Integer;

//     #region [Customer]
//     procedure CreateCustomer(var IDYMCustomer: Record "IDYM Customer")
//     var
//         TempRestParameterss: Record "IDYM REST Parameters" temporary;
//         RequestHttpContent: HttpContent;
//         CreateCustomerFailedErr: Label 'Creation of customer failed: %1', Comment = '%1 - Error Message';
//     begin
//         TempRestParameterss.Init();
//         TempRestParameterss.Path := 'customers';
//         TempRestParameterss.RestMethod := TempRestParameterss.RestMethod::POST;
//         TempRestParameterss."Content-Type" := FormUrlEncodedContentTypeLbl;

//         RequestHttpContent.WriteFrom(IDYMCustomer.GetAsFormData());
//         TempRestParameterss.SetRequestContent(RequestHttpContent);

//         StatusCode := IDYMHTTPHelper.Execute(TempRestParameterss, "IDYM Endpoint Service"::Stripe, "IDYM Endpoint Usage"::Default);
//         if not (StatusCode in [200, 201]) then
//             ParseError(CreateCustomerFailedErr, TempRestParameterss.GetResponseBodyAsJSON(), true);

//         ProcessStripeCustomer(TempRestParameterss.GetResponseBodyAsJsonObject(), IDYMCustomer);
//     end;

//     procedure UpdateCustomer(var IDYMCustomer: Record "IDYM Customer")
//     var
//         TempRestParameterss: Record "IDYM REST Parameters" temporary;
//         RequestHttpContent: HttpContent;
//         UpdateCustomerFailedErr: Label 'Update of customer failed: %1', Comment = '%1 - Error Message';
//     begin
//         TempRestParameterss.Init();
//         TempRestParameterss.Path := StrSubstNo(CustomersListLbl, IDYMCustomer.Id);
//         TempRestParameterss.RestMethod := TempRestParameterss.RestMethod::POST;
//         TempRestParameterss."Content-Type" := FormUrlEncodedContentTypeLbl;

//         RequestHttpContent.WriteFrom(IDYMCustomer.GetAsFormData());
//         TempRestParameterss.SetRequestContent(RequestHttpContent);

//         StatusCode := IDYMHTTPHelper.Execute(TempRestParameterss, "IDYM Endpoint Service"::Stripe, "IDYM Endpoint Usage"::Default);
//         if not (StatusCode in [200, 201]) then
//             ParseError(UpdateCustomerFailedErr, TempRestParameterss.GetResponseBodyAsJSON(), true);

//         ProcessStripeCustomer(TempRestParameterss.GetResponseBodyAsJsonObject(), IDYMCustomer);
//         IDYMCustomer.Modify();
//     end;

//     local procedure ProcessStripeCustomer(Data: JsonObject; var StripeCustomer: Record "IDYM Customer")
//     begin
//         StripeCustomer.Id := CopyStr(IDYMJSONHelper.GetTextValue(Data, 'id'), 1, MaxStrLen(StripeCustomer.id));
//         StripeCustomer.Delinquent := IDYMJSONhelper.GetBooleanValue(Data, 'delinquent');
//     end;

//     procedure GetAccount(var IDYMCustomer: Record "IDYM Customer")
//     var
//         TempRestParameterss: Record "IDYM REST Parameters" temporary;
//         Subscription: Record "IDYM Subscription";
//         JToken: JsonToken;
//         DataArray: JsonArray;
//         Data: JsonObject;
//         GetAccountErr: Label 'Could not retrieve account: %1', Comment = '%1 - Error Message';
//     begin
//         TempRestParameterss.Init();
//         TempRestParameterss.Path := StrSubstNo(CustomersListLbl, IDYMCustomer.Id);
//         TempRestParameterss.RestMethod := TempRestParameterss.RestMethod::GET;

//         StatusCode := IDYMHTTPHelper.Execute(TempRestParameterss, "IDYM Endpoint Service"::Stripe, "IDYM Endpoint Usage"::Default);
//         if not (StatusCode in [200, 201]) then
//             ParseError(GetAccountErr, TempRestParameterss.GetResponseBodyAsJSON(), true);
//         IDYMCustomer.DeleteAll();
//         ProcessStripeCustomer(TempRestParameterss.GetResponseBodyAsJsonObject(), IDYMCustomer);
//         IDYMCustomer.Insert();
//         Subscription.SetRange("Payment Provider", Subscription."Payment Provider"::Stripe);
//         Subscription.DeleteAll();
//         TempRestParameterss.GetResponseBodyAsJsonObject().Get('subscriptions', JToken);
//         JToken.SelectToken('data', JToken);
//         DataArray := JToken.AsArray();
//         foreach JToken in DataArray do begin
//             Data := JToken.AsObject();
//             Subscription.Init();
//             ProcessSubscription(Data, Subscription);
//             Subscription.Insert();
//         end;
//     end;

//     procedure GetProducts(var Product: Record "IDYM Product")
//     var
//         TempRestParameterss: Record "IDYM REST Parameters" temporary;
//         Subscription: Record "IDYM Subscription";
//         JToken: JsonToken;
//         DataArray: JsonArray;
//         Data: JsonObject;
//         GetProductsFailedErr: Label 'Could not get available products: %1', Comment = '%1 - Error Message';
//     begin
//         TempRestParameterss.Init();
//         TempRestParameterss.Path := 'products?limit=100';
//         TempRestParameterss.RestMethod := TempRestParameterss.RestMethod::GET;

//         StatusCode := IDYMHTTPHelper.Execute(TempRestParameterss, "IDYM Endpoint Service"::Stripe, "IDYM Endpoint Usage"::Default);
//         if not (StatusCode in [200, 201]) then
//             ParseError(GetProductsFailedErr, TempRestParameterss.GetResponseBodyAsJSON(), true);

//         Product.Reset();
//         Product.SetRange("Payment Provider", Subscription."Payment Provider"::Stripe);
//         Product.DeleteAll();

//         TempRestParameterss.GetResponseBodyAsJsonObject().Get('data', JToken);
//         DataArray := JToken.AsArray();
//         foreach JToken in DataArray do begin
//             Data := JToken.AsObject();
//             Product.Init();
//             Product.Id := CopyStr(IDYMJSONHelper.GetTextValue(Data, 'id'), 1, MaxStrLen(Product.Id));
//             Product."Payment Provider" := Product."Payment Provider"::Stripe;
//             Product.Name := CopyStr(IDYMJSONHelper.GetTextValue(Data, 'name'), 1, MaxStrLen(Product.Name));
//             Product."Product Guid" := CopyStr(IDYMJSONHelper.GetTextValue(IDYMJSONHelper.GetObject(Data, 'metadata'), 'guid'), 1, MaxStrLen(Product."Product Guid"));
//             Product.Insert();
//         end;
//     end;
//     #endregion

//     procedure GetPlans(var StripePlan: Record "IDYM Plan")
//     var
//         TempRestParameterss: Record "IDYM REST Parameters" temporary;
//         JToken: JsonToken;
//         DataArray: JsonArray;
//         Data: JsonObject;
//         GetPlansFailedErr: Label 'Could not get available plans: %1', Comment = '%1 - Error Message';
//     begin
//         TempRestParameterss.Init();
//         TempRestParameterss.Path := 'plans?limit=100';
//         TempRestParameterss.RestMethod := TempRestParameterss.RestMethod::GET;

//         StatusCode := IDYMHTTPHelper.Execute(TempRestParameterss, "IDYM Endpoint Service"::Stripe, "IDYM Endpoint Usage"::Default);
//         if not (StatusCode in [200, 201]) then
//             ParseError(GetPlansFailedErr, TempRestParameterss.GetResponseBodyAsJSON(), true);

//         StripePlan.Reset();
//         StripePlan.SetRange("Payment Provider", StripePlan."Payment Provider"::Stripe);
//         StripePlan.DeleteAll();

//         TempRestParameterss.GetResponseBodyAsJsonObject().Get('data', JToken);
//         DataArray := JToken.AsArray();
//         foreach JToken in DataArray do begin
//             Data := JToken.AsObject();
//             StripePlan.Init();
//             StripePlan.Id := CopyStr(IDYMJSONHelper.GetTextValue(Data, 'id'), 1, MaxStrLen(StripePlan.Id));
//             StripePlan."Payment Provider" := StripePlan."Payment Provider"::Stripe;
//             StripePlan."Product Id" := CopyStr(IDYMJSONHelper.GetTextValue(Data, 'product'), 1, MaxStrLen(StripePlan."Product Id"));
//             StripePlan.Amount := IDYMJSONHelper.GetDecimalValue(Data, 'amount');
//             StripePlan.Currency := CopyStr(IDYMJSONHelper.GetTextValue(Data, 'currency'), 1, MaxStrLen(StripePlan.Currency));
//             Evaluate(StripePlan.Interval, IDYMJSONHelper.GetTextValue(Data, 'interval'));
//             StripePlan."Interval Count" := IDYMJSONHelper.GetIntegerValue(Data, 'interval_count');
//             StripePlan."Trial Period Interval" := StripePlan."Trial Period Interval"::day;
//             StripePlan."Trial Period" := IDYMJSONHelper.GetIntegerValue(Data, 'trial_period_days', 0);
//             StripePlan.Active := IDYMJSONHelper.GetBooleanValue(Data, 'active');
//             StripePlan.Insert();
//         end;
//     end;

//     #region [Subscriptions]
//     procedure CreateSubscription(IDYMCustomer: Record "IDYM Customer"; StripePlan: Record "IDYM Plan"; var Subscription: Record "IDYM Subscription"; ProductGuid: Text[50])
//     var
//         TempRestParameterss: Record "IDYM REST Parameters" temporary;
//         RequestHttpContent: HttpContent;
//         CreateSubscriptionFailedErr: Label 'Could not create subscription: %1', Comment = '%1 - Error Message';
//     begin
//         TempRestParameterss.Init();
//         TempRestParameterss.Path := 'subscriptions';
//         TempRestParameterss.RestMethod := TempRestParameterss.RestMethod::POST;
//         TempRestParameterss."Content-Type" := FormUrlEncodedContentTypeLbl;

//         RequestHttpContent.WriteFrom(Subscription.GetFormDataForCreateSubscription(StripePlan, IDYMCustomer));
//         TempRestParameterss.SetRequestContent(RequestHttpContent);

//         StatusCode := IDYMHTTPHelper.Execute(TempRestParameterss, "IDYM Endpoint Service"::Stripe, "IDYM Endpoint Usage"::Default);
//         if not (StatusCode in [200, 201]) then
//             ParseError(CreateSubscriptionFailedErr, TempRestParameterss.GetResponseBodyAsJSON(), true);

//         Subscription.Init();
//         ProcessSubscription(TempRestParameterss.GetResponseBodyAsJsonObject(), Subscription);
//         Subscription."Product Guid" := ProductGuid;
//         Subscription.Insert();
//     end;

//     procedure UpdateSubscription(StripePlan: Record "IDYM Plan"; var Subscription: Record "IDYM Subscription")
//     var
//         TempRestParameterss: Record "IDYM REST Parameters" temporary;
//         RequestHttpContent: HttpContent;
//         CreateSubscriptionFailedErr: Label 'Could not update subscription: %1', Comment = '%1 - Error Message';
//     begin
//         TempRestParameterss.Init();
//         TempRestParameterss.Path := StrSubstNo(SubcriptionsListLbl, Subscription.Id);
//         TempRestParameterss.RestMethod := TempRestParameterss.RestMethod::POST;
//         TempRestParameterss."Content-Type" := FormUrlEncodedContentTypeLbl;

//         RequestHttpContent.WriteFrom(Subscription.GetFormDataForUpdateSubscription(StripePlan));
//         TempRestParameterss.SetRequestContent(RequestHttpContent);

//         StatusCode := IDYMHTTPHelper.Execute(TempRestParameterss, "IDYM Endpoint Service"::Stripe, "IDYM Endpoint Usage"::Default);
//         if not (StatusCode in [200, 201]) then
//             ParseError(CreateSubscriptionFailedErr, TempRestParameterss.GetResponseBodyAsJSON(), true);

//         ProcessSubscription(TempRestParameterss.GetResponseBodyAsJsonObject(), Subscription);
//         Subscription.Modify();
//     end;

//     procedure RefreshSubscription(var Subscription: Record "IDYM Subscription")
//     var
//         TempRestParameterss: Record "IDYM REST Parameters" temporary;
//         GetSubscriptionFailedErr: Label 'Could not get subscription: %1', Comment = '%1 - Error Message';
//     begin
//         TempRestParameterss.Init();
//         TempRestParameterss.Path := StrSubstNo(SubcriptionsListLbl, Subscription.Id);
//         TempRestParameterss.RestMethod := TempRestParameterss.RestMethod::GET;

//         StatusCode := IDYMHTTPHelper.Execute(TempRestParameterss, "IDYM Endpoint Service"::Stripe, "IDYM Endpoint Usage"::Default);
//         if not (StatusCode in [200, 201]) then
//             ParseError(GetSubscriptionFailedErr, TempRestParameterss.GetResponseBodyAsJSON(), true);

//         ProcessSubscription(TempRestParameterss.GetResponseBodyAsJsonObject(), Subscription);
//         Subscription.Modify();
//     end;

//     procedure ProcessSubscription(Data: JsonObject; var Subscription: Record "IDYM Subscription")
//     var
//         Plan: Record "IDYM Plan";
//         Product: Record "IDYM Product";
//     begin
//         Subscription.Id := CopyStr(IDYMJSONHelper.GetTextValue(Data, 'id'), 1, MaxStrLen(Subscription.Id));
//         Subscription."Payment Provider" := Subscription."Payment Provider"::Stripe;
//         // Subscription.Created := IDYMJSONHelper.GetBigIntegerValue(Data, 'created');
//         // Subscription."Current Period Start" := IDYMJSONHelper.GetBigIntegerValue(Data, 'current_period_start');
//         // Subscription."Current Period End" := IDYMJSONHelper.GetBigIntegerValue(Data, 'current_period_end');
//         // Subscription."Ended At" := IDYMJSONHelper.GetIntegerValue(Data, 'ended_at');

//         Subscription.Validate("Status (External)", CopyStr(IDYMJSONHelper.GetTextValue(Data, 'status'), 1, MaxStrLen(Subscription."Status (External)")));
//         Subscription."Trial Start" := IDYMJSONHelper.GetIntegerValue(Data, 'trial_start');
//         Subscription."Trial End" := IDYMJSONHelper.GetIntegerValue(Data, 'trial_end');

//         Subscription.Quantity := IDYMJSONHelper.GetIntegerValue(Data, 'quantity');

//         Subscription."Subscription Item Id" := CopyStr(IDYMJSONHelper.GetJsonValueByPath(Data.AsToken(), '$.items.data[0].id').AsText(), 1, MaxStrLen(Subscription."Subscription Item Id"));
//         Subscription."Plan Id" := CopyStr(IDYMJSONHelper.GetTextValue(IDYMJSONHelper.GetObject(Data, 'plan'), 'id'), 1, MaxStrLen(Subscription."Plan Id"));

//         Plan.Get(Subscription."Plan Id", Plan."Payment Provider"::Stripe);
//         Product.Get(Plan."Product Id", Product."Payment Provider"::Stripe);
//         Subscription."Product Id" := Product.Id;
//         Subscription."Product Guid" := Product."Product Guid";
//     end;
//     #endregion

//     local procedure ParseError(GeneralErrorText: Text; ErrorToken: JsonToken; ShowAsNotification: Boolean)
//     var
//         ErrorNotification: Notification;
//         ErrorObject: JsonObject;
//         ErrMessage: Text;
//         UnknownErr: Label 'Unknown error. Please try again.';
//         ParseErr: Label 'Invalid error object.';
//     begin
//         if not GuiAllowed() then
//             ShowAsNotification := false;

//         if not ErrorToken.IsObject() then
//             Error(ParseErr);
//         ErrorObject := IDYMJsonHelper.GetObject(ErrorToken, 'error');

//         ErrMessage := IDYMJsonHelper.GetTextValue(ErrorObject, 'message');
//         if ErrMessage = '' then
//             ErrMessage += ': ' + UnknownErr;

//         if ShowAsNotification then begin
//             Clear(ErrorNotification);
//             ErrorNotification.SetData('ErrorDescription', StrSubstNo(GeneralErrorText, ErrMessage));
//             ErrorNotification.Message(StrSubstNo(GeneralErrorText, ErrMessage));
//             ErrorNotification.Send();
//             Error('');
//         end else
//             Error(GeneralErrorText, ErrMessage)
//     end;
// }