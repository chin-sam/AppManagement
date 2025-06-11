page 11155292 "IDYM Payment Setup Card"
{
    PageType = Card;
    UsageCategory = None;
    SourceTable = "IDYM Payment Setup";
    Caption = 'Payment Setup';

    layout
    {
        area(Content)
        {
            group(Credentials)
            {
                Caption = 'Credentials';
                field("User Name"; UserName)
                {
                    ApplicationArea = All;
                    ToolTip = 'Your user name. You can create your API credentials on your paypal account.';
                    Caption = 'User Name';

                    trigger OnValidate()
                    begin
                        ClearEndpointCredentials();
                    end;
                }
                field(Secret; Secret)
                {
                    Caption = 'Secret';
                    ApplicationArea = All;
                    ToolTip = 'Your secret. You can create your API credentials on your paypal account.';
                    ExtendedDatatype = Masked;
                    Editable = PageEditable;

                    trigger OnValidate()
                    var
                        IDYMEndpointManagement: Codeunit "IDYM Endpoint Management";
                        xSecret: Text;
                    begin
                        if (Secret <> '') and (not EncryptionEnabled()) then
                            if Confirm(EncryptionIsNotActivatedQst) then
                                Page.RunModal(Page::"Data Encryption Management");

                        xSecret := Secret;
                        ClearEndpointCredentials();
                        Secret := xSecret;
                        if (Secret <> '') then begin
                            IDYMEndpointManagement.RegisterCredentials("IDYM Endpoint Service"::Paypal, "IDYM Endpoint Usage"::GetToken, AppInfo.Id(), "IDYM Authorization Type"::Basic, UserName, Secret);
                            IDYMEndpointManagement.RegisterEndpoint("IDYM Endpoint Service"::Paypal, "IDYM Endpoint Usage"::Default, "IDYM Authorization Type"::Bearer, AppInfo.Id);
                        end;
                    end;
                }
                field(Sandbox; Rec.Sandbox)
                {
                    Caption = 'Sandbox';
                    ApplicationArea = All;
                    ToolTip = 'Indicates that the Sandbox API of Paypal should be used instead of the production environment.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert(true);
        end;
    end;

    trigger OnAfterGetRecord()
    begin
        PageEditable := CurrPage.Editable();
        if Endpoint.Get("IDYM Endpoint Service"::Paypal, "IDYM Endpoint Usage"::GetToken) and Endpoint.HasApiKeyValue() then begin
            UserName := Endpoint."API Key Name";
            Secret := '*****';
        end else begin
            Clear(Secret);
            Clear(UserName);
        end;
    end;

    local procedure ClearEndpointCredentials()
    var
        Continue: Boolean;
    begin
        Continue := Endpoint.Get("IDYM Endpoint Service"::Paypal, "IDYM Endpoint Usage"::GetToken);
        if Continue then
            Continue := Endpoint.HasApiKeyValue();
        if Continue then
            Endpoint.ResetCredentials();
        Clear(Secret);
    end;

    var
        Endpoint: Record "IDYM Endpoint";
        AppInfo: ModuleInfo;
        UserName: Text[150];
        Secret: Text;
        PageEditable: Boolean;
        EncryptionIsNotActivatedQst: Label 'Data encryption is currently not enabled. We recommend that you encrypt sensitive data. \Do you want to open the Data Encryption Management window?';
}