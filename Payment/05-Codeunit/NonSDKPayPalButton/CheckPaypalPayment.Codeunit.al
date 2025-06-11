codeunit 11155300 "IDYM Check Paypal Payment"
{
    Access = Internal;

    trigger OnRun()
    begin
        case Page.GetBackgroundParameters().Get('RunMode') of
            'CheckPaymentStatus':
                CheckPaymentStatus();
            'RefreshReturnPage':
                RefreshReturnPage();
        end;
    end;

    local procedure RefreshReturnPage()
    var
        PricePlan: Record "IDYM Price Plan";
        Result: Dictionary of [Text, Text];
    begin
        Sleep(2000);
        PricePlan.Get(Page.GetBackgroundParameters().Get('IDYMPricePlanID'));
        Result.Add('Id', Format(PricePlan.Id));
        Page.SetBackgroundTaskResult(Result);
    end;

    local procedure CheckPaymentStatus()
    var
        Result: Dictionary of [Text, Text];
        Attempts: Integer;
        FailCount: Integer;
        Status: Text;
        PaymentId: Text;
        ErrorMessage: Text;
    begin
        repeat
            Attempts += 1;
            Status := CheckIfPaymentIsComplete(Page.GetBackgroundParameters().Get('subscription_id'), true, PaymentId, ErrorMessage);
            if Status = '' then begin
                if ErrorMessage <> '' then
                    FailCount += 1
                else
                    FailCount := 0;
                Sleep(3000);
            end;
        until (Status <> '') or (Attempts = 300) or (FailCount = 10);
        if Status <> '' then
            Result.Add('Status', Status)
        else
            Result.Add('Status', 'Cancelled');
        Result.Add('Id', PaymentId);
        Result.Add('ErrorMessage', ErrorMessage);
        Page.SetBackgroundTaskResult(Result);
    end;

    local procedure CheckIfPaymentIsComplete(SubscriptionId: Text; FirstTimeCalled: Boolean; var PaymentId: Text; var ErrorMessage: Text) Status: Text
    var
        TempRESTParameters: Record "IDYM REST Parameters" temporary;
        Subscription: Record "IDYM Subscription";
        PaymentSetup: Record "IDYM Payment Setup";
        JSONHelper: Codeunit "IDYM JSON Helper";
        ResponseHttpContent: HttpContent;
        ResponseObject: JsonObject;
        ResponseString: Text;
        RequestUriLbl: Label '/v1/billing/subscriptions/%1', Locked = true;
        CantReadResponseErr: Label 'The response from the paypal subscription api call can''t be read';
        HttpErr: Label 'The response from the paypal subscription api call returned %1. The returned error message was: %2.', Comment = '%1 = http error code, %2 = error message';
    begin
        Clear(ErrorMessage);
        if PaymentSetup.Get() then
            TempRESTParameters."Acceptance Environment" := PaymentSetup.Sandbox;
        TempRESTParameters.Path := StrSubstNo(RequestUriLbl, SubscriptionId);
        TempRESTParameters.RestMethod := TempRESTParameters.RestMethod::GET;
        HTTPHelper.Execute(TempRESTParameters, "IDYM Endpoint Service"::Paypal, "IDYM Endpoint Usage"::Default);

        TempRESTParameters.GetResponseContent(ResponseHttpContent);
        if not ResponseHttpContent.ReadAs(ResponseString) then
            ErrorMessage := CantReadResponseErr
        else
            if not ResponseObject.ReadFrom(ResponseString) then
                ErrorMessage := CantReadResponseErr;

        if (TempRESTParameters."Status Code" <> 200) or (ErrorMessage <> '') then begin
            if Subscription.Get(SubscriptionId) then;
            ErrorMessage := StrSubstNo(HttpErr, TempRESTParameters."Status Code", ResponseString);
            exit('');
        end;

        Status := JSONHelper.GetTextValue(ResponseObject, 'status');
        PaymentId := JSONHelper.GetTextValue(ResponseObject, 'id');
        if UpperCase(Status) in ['APPROVED', 'COMPLETED', 'ACTIVE'] then begin
            if UpperCase(Status) in ['APPROVED'] then
                if CapturePayment(SubscriptionId, TempRESTParameters."Acceptance Environment") in [200, 201] then begin
                    if FirstTimeCalled then
                        Status := CheckIfPaymentIsComplete(SubscriptionId, false, PaymentId, ErrorMessage);
                end else
                    Clear(Status);
        end else
            Clear(Status);
    end;

    local procedure CapturePayment(SubscriptionId: Text; Sandbox: Boolean) HTTPStatusCode: Integer
    var
        TempRESTParameters: Record "IDYM REST Parameters" temporary;
        RequestUriLbl: Label '/v1/billing/subscriptions/%1/capture', Locked = true;
    begin
        TempRESTParameters."Acceptance Environment" := Sandbox;
        TempRESTParameters.Path := StrSubstNo(RequestUriLbl, SubscriptionId);
        TempRESTParameters.RestMethod := TempRESTParameters.RestMethod::POST;
        TempRESTParameters."Content-Type" := 'application/json';
        HTTPHelper.Execute(TempRESTParameters, "IDYM Endpoint Service"::Paypal, "IDYM Endpoint Usage"::Default);
        HTTPStatusCode := TempRESTParameters."Status Code";
    end;

    var
        HTTPHelper: Codeunit "IDYM HTTP Helper";
}