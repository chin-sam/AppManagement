codeunit 11155294 "IDYM Installation"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        EndpointManagement: Codeunit "IDYM Endpoint Management";
        AppInfo: ModuleInfo;
    begin
        NewApphubDefaultEndpoint();
        //RegisterTenant();

        // Payment module
        NavApp.GetCurrentModuleInfo(AppInfo);
        if not PaymentSetup.Get() then begin
            PaymentSetup.Init();
            PaymentSetup.Insert();
        end;

        EndPointManagement.RegisterCredentials("IDYM Endpoint Service"::Paypal, "IDYM Endpoint Usage"::GetToken, AppInfo.Id(), "IDYM Authorization Type"::Basic, PaymentSetup.GetPaypalUserName(), PaymentSetup.GetPaypalSecret());
        EndPointManagement.RegisterEndpoint("IDYM Endpoint Service"::Paypal, "IDYM Endpoint Usage"::Default, "IDYM Authorization Type"::Bearer, AppInfo.Id());
    end;

    local procedure NewApphubDefaultEndpoint()
    var
        EndpointManagement: Codeunit "IDYM Endpoint Management";
        AppInfo: ModuleInfo;
    begin
        EndPointManagement.RegisterEndpoint("IDYM Endpoint Service"::Apphub, "IDYM Endpoint Usage"::Default, "IDYM Authorization Type"::Anonymous, AppInfo.Id());
    end;

    var
        PaymentSetup: Record "IDYM Payment Setup";
}
