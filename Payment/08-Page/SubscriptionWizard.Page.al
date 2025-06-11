page 11155293 "IDYM Subscription Wizard"
{
    PageType = NavigatePage;
    SourceTable = "IDYM Customer";
    Caption = 'Create Subscription';
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(BannerStandard)
            {
                Editable = false;
                Visible = TopBannerVisible and (CurrentStep < 4);
                field(StandardMediaResourcesField; StandardMediaResources."Media Reference")
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    ToolTip = 'In-progress picture indicator.';
                }
            }
            group(BannerDone)
            {
                Editable = false;
                Visible = TopBannerVisible and (CurrentStep = 4);
                field(DoneMediaResourcesField; DoneMediaResources."Media Reference")
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    ToolTip = 'Indicator to visualize that you reached the last step in the wizard.';
                }
            }
            group(Step1)
            {
                Visible = (CurrentStep = 1);
                group(SelectProvider)
                {
                    Caption = 'Choose payment provider';
                    InstructionalText = 'Based on your chosen provider, the system will fetch plans that have been configured for that specific provider.';
                    field(Provider; PaymentProvider)
                    {
                        Caption = 'Provider';
                        ToolTip = 'Specifies the payment provider';
                        ApplicationArea = All;
                        ValuesAllowed = 0;
                    }
                }
            }
            group(Step2)
            {
                Visible = (CurrentStep = 2);
                group(Customer)
                {
                    Caption = 'Customer details';
                    InstructionalText = 'Provide your company details';
                    field(Name; Rec.Name)
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                        ToolTip = 'Enter the Name of your company.';
                    }
                    field(Address; Rec.Address)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Enter the company address.';
                    }
                    field(PostalCode; Rec."Postal Code")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Enter the company postal code.';
                    }
                    field(City; Rec.City)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Enter the city where the company is registered.';
                    }
                    field(State; Rec.State)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Enter the state where the company is registered.';
                    }
                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Enter the country where the company is registered.';
                    }
                    field(Phone; Rec.Phone)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Enter the company''s phone number.';
                    }
                    field(Email; Rec.Email)
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                        ToolTip = 'Enter the company''s email adress.';
                    }

                }
            }
            group(Step3)
            {
                Visible = (CurrentStep = 3);
                group(Plan)
                {
                    Caption = 'Choose a plan';
                    InstructionalText = 'Choose a subscription plan from the list below';
                    part(Plans; "IDYM Price Plan Subpart")
                    {
                        Caption = 'Plans';
                        ApplicationArea = All;
                        UpdatePropagation = Both;
                    }
                    part(Modules; "IDYM Modules")
                    {
                        ApplicationArea = All;
                        Provider = Plans;
                        SubPageLink = "App Id" = field("App Id");
                        Editable = false;
                        Caption = 'Included Modules';
                    }
                    group(Totals)
                    {
                        Caption = 'Totals';
                        // field(OneTimePayment; OneTimePayment)
                        // {
                        //     Caption = 'One Time Payment';
                        //     ApplicationArea = All;
                        //     ToolTip = 'Specifies if it''s one time payment.';
                        // }

                        field(TotalAmount; TotalAmount)
                        {
                            CaptionClass = TotalAmountCaption;
                            Caption = 'Amount Incl. VAT';
                            ApplicationArea = All;
                            Editable = false;
                            AutoFormatExpression = CurrencyCode;
                            AutoFormatType = 1;
                            ToolTip = 'Shows the total amount to purchase';
                        }
                    }
                }

            }
            // group(Step41)
            // {
            //     Visible = (CurrentStep = 4) and (Provider = Provider::Stripe);
            //     group(CreditCardInstruction)
            //     {
            //         Caption = 'Credit card details';
            //         InstructionalText = 'Please fill in your credit card details below. They will be safely stored with our payment provider Stripe. No credit card information will be stored in Dynamics 365.';
            //     }
            //     group(CreditCardDetails)
            //     {
            //         ShowCaption = false;
            //         usercontrol(CreditCardControl; StripeCreditCardControl)
            //         {
            //             ApplicationArea = All;

            //             trigger ControlAddInReady()
            //             begin
            //                 //CurrPage.CreditCardControl.InitializeCheckOutForm(PaymentMgt.GetPublishableKey());
            //             end;

            //             trigger InputChanged(complete: Boolean)
            //             begin
            //                 CreditCardInputComplete := complete;
            //                 SetControls();
            //             end;

            //             trigger StripeTokenCreated(newTokenId: Text)
            //             var
            //                 Product: Record "IDYM Product";
            //             begin
            //                 Rec."Stripe Token Id" := CopyStr(newTokenId, 1, MaxStrLen(Rec."Stripe Token Id"));

            //                 Product.Get(ProdId, Provider);
            //                 Product."Stripe Token Id" := CopyStr(newTokenId, 1, MaxStrLen(Product."Stripe Token Id"));
            //                 Product.Modify();
            //                 CurrentStep := 5;
            //                 SetControls();
            //             end;
            //         }
            //     }
            // }
            group(Step42)
            {
                Visible = (CurrentStep = 4) and (PaymentProvider = PaymentProvider::Paypal);
                // group(Paypal) //TODO reenable when OldPaypal Addin is replaced with SDK Paypal Button
                // {
                //     Caption = 'Paypal';
                //     InstructionalText = 'Please continue using the PayPal button below. If the button is not loaded, please refresh the page.';
                // }
                // group(PaypalAddin)
                // {
                //     ShowCaption = false;
                //     usercontrol(PayPalSubscriptionAddin; "IDYM PayPal Subs. Control")
                //     {
                //         ApplicationArea = All;

                //         trigger OnControlAddinStart()
                //         begin
                //             CurrPage.PayPalSubscriptionAddin.LoadScript(PaymentSetup.GetPaypalUserName());
                //         end;

                //         trigger OnLoadScript()
                //         var
                //             IDYNPAYPaypalWebService: Codeunit "IDYM Paypal Web Service";
                //         begin
                //             IDYNPAYPaypalWebService.SetParameters(CurrencyCode, ProdId, IDYNPAYPricePlan.Interval, TotalAmount, OneTimePayment);
                //             CurrPage.PayPalSubscriptionAddin.InitSubscriptionButton(IDYNPAYPaypalWebService.GetSubscriptionReqObject(IDYNPAYPricePlan, Rec));
                //         end;

                //         trigger OnApprove(NewSubscriptionId: Text)
                //         begin
                //             SubscriptionId := NewSubscriptionId;
                //             CreditCardInputComplete := true;
                //             CurrentStep := 5;
                //             SetControls();
                //         end;
                //     }
                // }
                group(PaypalAddin)
                {
                    ShowCaption = false;
                    Visible = PaypalAddinVisible;
                    usercontrol("IDYM PayPal Payment Addin"; "IDYM PayPal Payment Addin")
                    {
                        ApplicationArea = All;

                        trigger AddinLoaded()
                        var
                            PayPalLbl: Label 'PayPal', Locked = true;
                            ExplainTxt: Label 'To purchase a subscription for %1 please use the Paypal button.', Comment = '%1 = App Name';
                        begin
                            CurrPage."IDYM PayPal Payment Addin".Initialize(GlobalLanguage(), 'Payment/Addins/NonSDKPayPalButton/PayPal_Logo.png', StrSubstNo(ExplainTxt, PricePlan."App Name"));
                            CurrPage."IDYM PayPal Payment Addin".addButton(PayPalLbl, 'Payment/Addins/NonSDKPayPalButton/PayPal_Btn.png');
                        end;

                        trigger ButtonPressed()
                        var
                            PaypalAddinMgt: Codeunit "IDYM Paypal Addin Mgt.";
                            TaskParameters: Dictionary of [Text, Text];
                            TaskID: Integer;
                        begin
                            Hyperlink(PaypalAddinMgt.CreateSubscription(PricePlan, Rec, SubscriptionId, CurrencyCode, ProdId, TotalAmount, OneTimePayment));
                            TaskParameters.Add('RunMode', 'CheckPaymentStatus');
                            TaskParameters.Add('subscription_id', SubscriptionId);
                            PricePlan.Validate("Subscription Id", CopyStr(SubscriptionId, 1, MaxStrLen(PricePlan."Subscription Id")));
                            PricePlan.SetUnrestricedAccess();
                            PricePlan.Modify();
                            TaskID := 1;
                            CurrPage.EnqueueBackgroundTask(TaskId, Codeunit::"IDYM Check Paypal Payment", TaskParameters);
                        end;
                    }
                }
            }
            group(Step5)
            {
                Visible = (CurrentStep = 5);
                group(Overview)
                {
                    Caption = 'All done';
                    InstructionalText = 'Click on Finish to create your subscription.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionBack)
            {
                ApplicationArea = All;
                Caption = 'Back';
                Enabled = ActionBackAllowed;
                Image = PreviousRecord;
                InFooterBar = true;
                ToolTip = 'Go back one step in the wizard.';

                trigger OnAction()
                begin
                    TakeStep(-1);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Enabled = ActionNextAllowed;
                Image = NextRecord;
                InFooterBar = true;
                ToolTip = 'Go to the next step of the wizard.';

                trigger OnAction()
                begin
                    TakeStep(1);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = All;
                Caption = 'Finish';
                Enabled = ActionFinishAllowed;
                Image = Approve;
                InFooterBar = true;
                ToolTip = 'Complete the wizard.';

                trigger OnAction()
                begin
                    Finish();
                end;
            }

        }
    }

    trigger OnInit()
    begin
        LoadTopBanners();
    end;

    trigger OnOpenPage()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        PaymentMgt.SetParameters(AppId, LicenseKey);
        PaymentSetup.GetSetup();

        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."LCY Code" in ['EUR', 'USD'] then
            CurrencyCode := GeneralLedgerSetup."LCY Code"
        else
            CurrencyCode := 'EUR';

        //Temp code
        CurrentStep := 2; //TODO reset to 1 when second payment provider is live
        PaymentProvider := PaymentProvider::Paypal;
        PaymentMgt.SetProvider(PaymentProvider);
        PaymentMgt.RefreshData();
        CurrPage.Plans.Page.SetParameters(AppId, CurrencyCode);
        GetProductId();
        // end Temp Code

        SetControls();

        if Rec.FindFirst() then
            Rec.SetRecFilter()
        else
            PaymentMgt.CreateCustomer(Rec);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Plans.Page.GetSelectedPlan(PricePlan);
        PaypalAddinVisible := PricePlan."Payment Id" = '';
        CurrPage.Modules.Page.SetParameters(PricePlan."Interval Count", PricePlan.Interval, CurrencyCode, PricePlan.Id);
        TotalAmount := PaymentMgt.CalculateSubscriptionAmount(Rec, PricePlan, CurrencyCode);
        UsedTierId := PricePlan.GetTierId();
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text]) //TODO remove when OldPaypal Addin is replaced with SDK Paypal Button
    var
        PaypalWebService: Codeunit "IDYM Paypal Web Service";
        ErrorMessage: Text;
        IssueProcessingPaymentErr: Label 'There was an issue with registering your payment. The status of the subscription is %1 and the returned error is %2', Comment = '%1 = Status, %2 = Error Message';
    begin
        Status := Results.Get('Status');
        ErrorMessage := Results.Get('ErrorMessage');
        case UpperCase(Status) of
            'CREATED':
                PricePlan."Payment Status" := PricePlan."Payment Status"::Created;
            'SAVED':
                PricePlan."Payment Status" := PricePlan."Payment Status"::Saved;
            'APPROVED':
                PricePlan."Payment Status" := PricePlan."Payment Status"::Approved;
            'VOIDED':
                PricePlan."Payment Status" := PricePlan."Payment Status"::Voided;
            'COMPLETED', 'ACTIVE':
                PricePlan."Payment Status" := PricePlan."Payment Status"::Completed;
            'ACTION REQUIRED', 'CANCELLED':
                PricePlan."Payment Status" := PricePlan."Payment Status"::"Action Required";
            'ERROR':
                PricePlan."Payment Status" := PricePlan."Payment Status"::Error;
        end;
        PricePlan."Payment Id" := CopyStr(Results.Get('Id'), 1, MaxStrLen(PricePlan."Payment Id"));
        PricePlan.SetUnrestricedAccess();
        PricePlan.Modify();
        PaypalWebService.FindOrCreateSubscription(PricePlan."Subscription Id", AppId, LicenseKey, Subscription);
        Commit();
        CreditCardInputComplete := PricePlan."Payment Status" = PricePlan."Payment Status"::Completed;
        if CreditCardInputComplete then begin
            PaypalAddinVisible := true;
            CurrentStep := 5;
            SetControls();
            CurrPage.Update();
        end else
            if ErrorMessage <> '' then
                NotificationMgt.SendNotification(GetSubscriptionPaymentFailedNotificationId(), StrSubstNo(IssueProcessingPaymentErr, Status, ErrorMessage));
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean) //TODO remove when OldPaypal Addin is replaced with SDK Paypal Button
    var
        PaymentTimedOutErr: Label 'The purchase of the subscription timed out. Please try again. Be aware that the actual payment needs to be completed in a separate tab on the browser.';
    begin
        if not CreditCardInputComplete then begin
            case ErrorCode of
                'ChildSessionTaskTimeout':
                    ErrorText := PaymentTimedOutErr;
            end;
            if ErrorText <> '' then
                NotificationMgt.SendNotification(GetSubscriptionPaymentFailedNotificationId(), ErrorText);
        end else
            IsHandled := true;
    end;

    local procedure SetControls()
    begin
        ActionBackAllowed := CurrentStep > 2; //TODO Restore to 1 when another payment provider is live
        ActionNextAllowed := (CurrentStep < 4) or ((CurrentStep = 4) and CreditCardInputComplete);
        ActionFinishAllowed := CurrentStep = 5;
    end;

    local procedure TakeStep(Step: Integer)
    begin
        if (CurrentStep = 4) and (Step = 2) and (Rec."Stripe Token Id" = '') then
            Step := 0;
        CheckCustomerData();
        CurrentStep += Step;
        SetControls();
    end;

    local procedure Finish()
    var
        Module: Record "IDYM Module";
    begin
        PaymentMgt.GetSubscription(SubscriptionId, Subscription, false);

        // AppHub data
        CurrPage.Modules.Page.GetSelectedModules(Module);
        Subscription.SetSubscriptionData(PaymentMgt.GetSelectedSubscription(Module, Subscription, PricePlan.Id, UsedTierId, CurrencyCode, TotalAmount));
        Subscription.SetUnrestricedAccess();
        Subscription.Modify();

        Completed := true;
        CurrPage.Close();
    end;

    local procedure LoadTopBanners()
    begin
        if StandardMediaRepository.Get('AssistedSetup-NoText-400px.png', Format(CurrentClientType())) and
           DoneMediaRepository.Get('AssistedSetupDone-NoText-400px.png', Format(CurrentClientType()))
        then
            if StandardMediaResources.Get(StandardMediaRepository."Media Resources Ref") and
               DoneMediaResources.Get(DoneMediaRepository."Media Resources Ref")
            then
                TopBannerVisible := DoneMediaResources."Media Reference".HasValue();
    end;

    local procedure CheckCustomerData()
    var
        CountryRegion: Record "Country/Region";
    begin
        case CurrentStep of
            1:
                begin
                    PaymentMgt.SetProvider(PaymentProvider);
                    PaymentMgt.RefreshData();
                    CurrPage.Plans.Page.SetParameters(AppId, CurrencyCode);
                    GetProductId();
                end;
            2:
                begin
                    Rec.TestField(Name);
                    Rec.TestField(Email);

                    Rec.TestField("Country/Region Code");
                    CountryRegion.Get(Rec."Country/Region Code");
                    CountryRegion.TestField("ISO Code");

                    InclVATAmount := Rec.IncludeVATAmount();
                    if InclVATAmount then
                        TotalAmountCaption := AmountInclVATLbl
                    else
                        TotalAmountCaption := AmountLbl;

                end;
            3:
                if not CurrPage.Plans.Page.HasSelectedPlan() then
                    Error(NoPlanSelectedErr);
        // 4:
        //     case Provider of
        //         Provider::Stripe:
        //             CurrPage.CreditCardControl.CreateStripeToken();
        //     end;
        end;
    end;

    local procedure GetProductId()
    var
        Product: Record "IDYM Product";
    begin
        Product.SetRange("Product Guid", AppId);
        Product.SetRange("Payment Provider", PaymentProvider);
        if Product.FindLast() then
            ProdId := Product.Id;
    end;

    local procedure GetSubscriptionPaymentFailedNotificationId(): Guid
    begin
        exit('b2cf4c8e-4697-4e88-980d-f973711f7fdc');
    end;

    internal procedure IsCompleted(): Boolean
    begin
        exit(Completed);
    end;

#if not BC17
    internal procedure GetSubscriptionRecId(): RecordId
    begin
        exit(Subscription.RecordId);
    end;

    [Obsolete('Using RecordID return variable', '17.9')]
#endif    
    internal procedure GetSubscriptionRecId(var ReturnRecordId: RecordId)
    begin
        ReturnRecordId := Subscription.RecordId;
    end;

    [Obsolete('Added additional Parameters', '21.0')]
    internal procedure SetParameters(NewAppId: Guid)
    begin
        AppId := NewAppId;
    end;

    internal procedure SetParameters(NewAppId: Guid; NewLicenseKey: Text[50])
    begin
        AppId := NewAppId;
        LicenseKey := NewLicenseKey;
    end;

    var
        PaymentSetup: Record "IDYM Payment Setup";
        StandardMediaRepository: Record "Media Repository";
        DoneMediaRepository: Record "Media Repository";
        StandardMediaResources: Record "Media Resources";
        DoneMediaResources: Record "Media Resources";
        Subscription: Record "IDYM Subscription";
        PricePlan: Record "IDYM Price Plan";
        PaymentMgt: Codeunit "IDYM Payment Mgt.";
        NotificationMgt: Codeunit "IDYM Notification Management";
        PaymentProvider: Enum "IDYM Payment Provider";
        AppId: Guid;
        ProdId: Text[50];
        Status: Text;
        PaypalAddinVisible: Boolean;
        ActionBackAllowed: Boolean;
        ActionNextAllowed: Boolean;
        ActionFinishAllowed: Boolean;
        TopBannerVisible: Boolean;
        CreditCardInputComplete: Boolean;
        Completed: Boolean;
        InclVATAmount: Boolean;
        CurrentStep: Integer;
        LicenseKey: Text[50];
        TotalAmount: Decimal;
        CurrencyCode: Code[10];
        SubscriptionId: Text;
        UsedTierId: Guid;
        TotalAmountCaption: Text;
        OneTimePayment: Boolean;
        NoPlanSelectedErr: Label 'Please select a plan';
        AmountInclVATLbl: Label 'Amount Incl. VAT';
        AmountLbl: Label 'Amount';
}