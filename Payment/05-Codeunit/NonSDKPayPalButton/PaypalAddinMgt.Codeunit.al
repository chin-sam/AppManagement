codeunit 11155299 "IDYM Paypal Addin Mgt."
{
    trigger OnRun()
    begin

    end;

    internal procedure CreateSubscription(PricePlan: Record "IDYM Price Plan"; IDYMCustomer: Record "IDYM Customer"; var SubscriptionID: Text; CurrencyCode: Code[10]; ProductId: Text[50]; TotalAmount: Decimal; OneTimePayment: Boolean) Href: Text
    var
        PaymentSetup: Record "IDYM Payment Setup";
        TempRESTParameters: Record "IDYM REST Parameters" temporary;
        HttpHelper: Codeunit "IDYM HTTP Helper";
        PaypalWebService: Codeunit "IDYM Paypal Web Service";
        ResponseJsonToken: JsonToken;
        RequestUriLbl: Label '/v1/billing/subscriptions', Locked = true;
        ResponseFailedErr: Label 'Reading the response failed, the link to process the payment was not returned';
    begin
        if not PaymentSetup.Get() then;
        PaypalWebService.SetParameters(CurrencyCode, ProductId, PricePlan.Interval, TotalAmount, OneTimePayment);
        TempRESTParameters."Acceptance Environment" := PaymentSetup.Sandbox;
        TempRESTParameters.Path := RequestUriLbl;
        TempRESTParameters.RestMethod := TempRESTParameters.RestMethod::POST;
        TempRESTParameters.SetRequestContent(PaypalWebService.GetSubscriptionReqObject(PricePlan, IDYMCustomer));
        HttpHelper.Execute(TempRESTParameters, "IDYM Endpoint Service"::Paypal, "IDYM Endpoint Usage"::Default);
        ResponseJsonToken := TempRESTParameters.GetResponseBodyAsJSON();
        if ((TempRESTParameters."Status Code" < 200) or (TempRESTParameters."Status Code" >= 300)) or not ResponseJsonToken.IsObject then
            Error(ResponseFailedErr);
        Href := ProcessCreateSubscriptionResponse(ResponseJsonToken.AsObject(), SubscriptionID);
        if Href = '' then
            Error(ResponseFailedErr);
    end;

    local procedure ProcessCreateSubscriptionResponse(Response: JsonObject; var SubscriptionID: Text) Href: Text
    var
        IDYMJSONHelper: Codeunit "IDYM JSON Helper";
        Links: JsonArray;
        Link: JsonToken;
    begin
        if not Response.Contains('links') then
            exit;
        SubscriptionID := IDYMJSONHelper.GetTextValue(Response, 'id');
        Links := IDYMJSONHelper.GetArray(Response, 'links');

        foreach Link in Links do
            if IDYMJSONHelper.GetTextValue(Link.AsObject(), 'rel') = 'approve' then begin
                Href := IDYMJSONHelper.GetTextValue(Link.AsObject(), 'href');
                break;
            end;
    end;
}