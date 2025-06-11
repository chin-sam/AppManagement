page 11155290 "IDYM Apphub Subscription"
{
    PageType = NavigatePage;
    Caption = 'New customer agreement Wizard';
    DataCaptionFields = "License Key";
    UsageCategory = None;
    SourceTable = "IDYM Apphub Subscription";

    layout
    {
        area(Content)
        {
            group(BannerStandard)
            {
                Editable = false;
                Visible = TopBannerVisible and (CurrentStep = 0);
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
                Visible = TopBannerVisible and (CurrentStep = 1);
                field(DoneMediaResourcesField; DoneMediaResources."Media Reference")
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    ToolTip = 'Indicator to visualize that you reached the last step in the wizard.';
                }
            }
            group(Step1)
            {
                Caption = 'Provide Recipient Info';
                Visible = CurrentStep = 0;
                group(RecipientInfo)
                {
                    ShowCaption = false;
                    field(UnblockLicenseFld; UnblockLicense)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ShowCaption = false;
                        MultiLine = true;
                    }
                    field("Recipient Name"; Rec."Recipient Name")
                    {
                        Caption = 'Recipient Name';
                        ToolTip = 'Specifies the name of the recipient who will receive a request to sign the new agreement.';
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            CheckDataAndEnableSubmit();
                        end;
                    }
                    field("Recipient Email"; Rec."Recipient Email")
                    {
                        Caption = 'Recipient Email';
                        ToolTip = 'Specifies the e-mail address of the recipient who will receive a request to sign the new agreement.';
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            CheckDataAndEnableSubmit();
                        end;
                    }
                }
            }
            group(Step2)
            {
                Caption = 'Request new agreement';
                Visible = CurrentStep = 1;
                group(SignAgreement)
                {
                    ShowCaption = false;
                    field(SubmitLicenseFld; SubmitLicense)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ShowCaption = false;
                        MultiLine = true;
                    }
                    field("Recipient Name 2"; Rec."Recipient Name")
                    {
                        Caption = 'Recipient Name';
                        ToolTip = 'Specifies the name of the recipient who will receive a request to sign the new agreement.';
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            CheckDataAndEnableSubmit();
                        end;
                    }
                    field("Recipient Email 2"; Rec."Recipient Email")
                    {
                        Caption = 'Recipient Email';
                        ToolTip = 'Specifies the e-mail address of the recipient who will receive a request to sign the new agreement.';
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            CheckDataAndEnableSubmit();
                        end;
                    }
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
                Enabled = CurrentStep = 1;
                Image = PreviousRecord;
                InFooterBar = true;
                ToolTip = 'Go back one step in the wizard.';

                trigger OnAction()
                begin
                    Rec."Recipient Name" := '';
                    Rec."Recipient Email" := '';
                    CurrentStep := 0;
                end;
            }
            action(ActionSubmit)
            {
                ApplicationArea = All;
                Caption = 'Submit';
#if BC17
                Enabled = (CurrentStep = 1) and not Submitted;
#else
                Enabled = (CurrentStep = 1) and not Rec.Submitted;
#endif
                Image = Approve;
                InFooterBar = true;
                ToolTip = 'Submit the request to send a new agreement.';

                trigger OnAction()
                begin
                    SubmitAgreemenent();
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        LoadTopBanners();
    end;

    trigger OnAfterGetCurrRecord()
    var
        UnblockLicenseTxt: Label 'Dear customer,\\The license for %1 has been blocked on %2, because of overdue payments. Payments are due since %3.\The fastest way to unblock your license is to engage with idyn directly by signing a new customer agreement.\This agreement will be sent directly to the person responsible in your company.\\Please provide recipient details below:', Comment = '%1 = App Name, %2 = License Blocked Date, %3 = Payment Due Date';
        SubmitLicenseTxt: Label 'After pressing Submit, the entered recipient will receive an e-mail with an order for a subscription, using DocuSign.\After this order has been signed the option to setup your new subscription becomes visible in this notification.\Once the new subscription is paid using PayPal, it can take up to 30 minutes before the signed agreement is processed and your license is activated again.\\Thank you for chosing idyn!';
        SubmittedLicenseTxt: Label 'Someone in the organization already submitted a request for a new order to the recipient listed below.\The recipient has received an e-mail with an order for a subscription, using DocuSign.\After this order has been signed the option to setup your new subscription becomes visible in this notification.\Once the new subscription is paid using PayPal, it can take up to 30 minutes before the signed agreement is processed and your license is activated again.\\Thank you for chosing idyn!\You can close this page.';
        AppInfo: ModuleInfo;
    begin
        NavApp.GetModuleInfo(Rec."App Id", AppInfo);
        UnblockLicense := StrSubstNo(UnblockLicenseTxt, AppInfo.Name, DT2Date(Rec."Payment Blocked"), DT2Date(Rec."Payment Due"));
        if Rec.Submitted then
            SubmitLicense := SubmittedLicenseTxt
        else
            SubmitLicense := SubmitLicenseTxt;
        CheckDataAndEnableSubmit();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Rec.SetUnrestricedAccess();
    end;

    local procedure CheckDataAndEnableSubmit();
    begin
        if (Rec."Recipient Name" <> '') and (Rec."Recipient Email" <> '') then
            CurrentStep := 1;
    end;

    local procedure SubmitAgreemenent()
    var
        Apphub: Codeunit "IDYM Apphub";
    begin
        Apphub.RequestDocusignAgreement(Rec);
        Rec.Submitted := true;
        Rec.Modify();
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

    var
        StandardMediaRepository: Record "Media Repository";
        DoneMediaRepository: Record "Media Repository";
        StandardMediaResources: Record "Media Resources";
        DoneMediaResources: Record "Media Resources";
        UnblockLicense: Text;
        SubmitLicense: Text;
        CurrentStep: Integer;
        TopBannerVisible: Boolean;
}