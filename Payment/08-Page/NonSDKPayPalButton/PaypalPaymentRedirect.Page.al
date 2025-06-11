page 11155294 "IDYM Paypal Payment Redirect"
{
    Caption = 'Subscription Payment Status Check';
    SourceTable = Integer;
    UsageCategory = None;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    Editable = false;
    ShowFilter = false;
    PageType = Card;
    DataCaptionExpression = PricePlan."App Name";

    layout
    {
        area(Content)
        {
            group(InProcess)
            {
                ShowCaption = false;
                InstructionalText = 'Your payment is in process. Please wait ...';
                Visible = not PaymentCaptured;
            }
            group(Processed)
            {
                ShowCaption = false;
                Visible = PaymentCaptured;
                field(PaymentCompletedFld; PaymentCompleted)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    MultiLine = true;
                }
            }
            group(License)
            {
                field("App Name"; PricePlan."App Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the app for which a payment is required.';
                }
            }
            group(PaymentStatus)
            {
                Caption = 'Payment Status';
                Visible = PaymentCaptured;
                field("Payment Id"; PricePlan."Payment Id")
                {
                    Caption = 'Paypal Payment Id';
                    ApplicationArea = All;
                    ToolTip = 'Indicates the payment id of the registered payment.';
                }
                field("Payment Status"; PricePlan."Payment Status")
                {
                    Caption = 'Payment Status';
                    ApplicationArea = all;
                    ToolTip = 'Indicates the status of the Payment in progress.';
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        TaskParameters: Dictionary of [Text, Text];
        TaskId: Integer;
        PaymentCompletedMsg: Label 'Thank you for your payment.\A receipt for your purchase has been emailed to you. You can also log into your PayPal account to view the details of this transaction.\You can now close the browser to return to the subscription wizard and click on the Finish button.';
    begin
        PaymentCompleted := PaymentCompletedMsg;
        PricePlan.SetRange(Id_Int, Rec.Number);
        PricePlan.FindFirst();
        PaymentCaptured := (PricePlan."Payment Id" <> '');
        TaskParameters.Add('RunMode', 'RefreshReturnPage');
        TaskParameters.Add('IDYMPricePlanID', Format(PricePlan.Id));
        if PricePlan."Payment Status" <> PricePlan."Payment Status"::Completed then
            CurrPage.EnqueueBackgroundTask(TaskId, Codeunit::"IDYM Check Paypal Payment", TaskParameters);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        TaskParameters: Dictionary of [Text, Text];
        SecondTaskId: Integer;
    begin
        PricePlan.SetRange(Id_Int, Rec.Number);
        PricePlan.FindFirst();
        PaymentCaptured := (PricePlan."Payment Id" <> '');

        TaskParameters.Add('RunMode', 'RefreshReturnPage');
        TaskParameters.Add('IDYMPricePlanID', Format(PricePlan."Id"));
        if PricePlan."Payment Status" <> PricePlan."Payment Status"::Completed then
            CurrPage.EnqueueBackgroundTask(SecondTaskId, Codeunit::"IDYM Check Paypal Payment", TaskParameters);
        CurrPage.Update();
    end;

    var
        PricePlan: Record "IDYM Price Plan";
        PaymentCaptured: Boolean;
        PaymentCompleted: Text;
}