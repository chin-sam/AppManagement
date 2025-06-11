// codeunit 11155297 "IDYM Stripe Management"
// {
//     procedure RefreshData()
//     begin
//         if not ShouldRefreshStripeData() then
//             exit;

//         GetBaseData();
//         OnCreateSubscription();

//         PaymentSetup."Last Synchronized" := CurrentDateTime();
//         PaymentSetup.Modify();
//     end;

//     procedure GetBaseData()
//     var
//         Product: Record "IDYM Product";
//         StripePlan: Record "IDYM Plan";
//     begin
//         StripeWebService.GetProducts(Product);
//         StripeWebService.GetPlans(StripePlan);
//     end;

//     local procedure ShouldRefreshStripeData() ReturnValue: Boolean
//     begin
//         PaymentSetup.GetSetup();
//         ReturnValue := true;
//         if PaymentSetup."Last Synchronized" <> 0DT then
//             ReturnValue := (CurrentDateTime() - PaymentSetup."Last Synchronized") > (24 * 60 * 60 * 1000);
//         ReturnValue := true;  //TODO, temp to always refresh data
//     end;

//     procedure CreateSubcription(IDYMCustomer: Record "IDYM Customer"; StripePlan: Record "IDYM Plan"; var Subscription: Record "IDYM Subscription")
//     begin
//         DoCreateSubscription(IDYMCustomer, StripePlan, Subscription);
//     end;

//     local procedure DoCreateSubscription(IDYMCustomer: Record "IDYM Customer"; StripePlan: Record "IDYM Plan"; var Subscription: Record "IDYM Subscription")
//     var
//         Product: Record "IDYM Product";
//     begin
//         CheckCustomerDetails(IDYMCustomer);
//         StripeWebService.UpdateCustomer(IDYMCustomer);

//         Product.Get(StripePlan."Product Id", StripePlan."Payment Provider");

//         Subscription.SetRange("Product Guid", Product."Product Guid");
//         Subscription.SetRange("Payment Provider", StripePlan."Payment Provider");
//         if Subscription.FindFirst() then
//             StripeWebService.UpdateSubscription(StripePlan, Subscription)
//         else
//             StripeWebService.CreateSubscription(IDYMCustomer, StripePlan, Subscription, Product."Product Guid");
//     end;

//     local procedure CheckCustomerDetails(IDYMCustomer: Record "IDYM Customer");
//     begin
//         IDYMCustomer.TestField(IDYMCustomer.Name);
//         IDYMCustomer.TestField(IDYMCustomer.Email);
//     end;

//     procedure CreateTrialSubscription(var Product: Record "IDYM Product"; var Subscription: Record "IDYM Subscription")
//     begin
//         DoCreateTrialSubscription(Product, Subscription);
//     end;

//     local procedure DoCreateTrialSubscription(var Product: Record "IDYM Product"; var Subscription: Record "IDYM Subscription")
//     var
//         IDYMCustomer: Record "IDYM Customer";
//         StripePlan: Record "IDYM Plan";
//     begin
//         if not IDYMCustomer.findfirst() then
//             StripeManagement.CreateTrialCustomer(IDYMCustomer);

//         if not Product.FindFirst() then
//             exit;

//         StripePlan.SetRange("Product Id", Product.Id);
//         StripePlan.SetRange("Trial Period Interval", StripePlan."Trial Period Interval"::day);
//         StripePlan.SetFilter("Trial Period", '<>%1', 0);
//         StripePlan.SetRange("Internal Invoice", 0);
//         StripePlan.FindFirst();

//         StripeWebService.CreateSubscription(IDYMCustomer, StripePlan, Subscription, Product."Product Guid");
//     end;

//     procedure CreateTrialCustomer(var IDYMCustomer: Record "IDYM Customer")
//     begin
//         DoCreateTrialCustomer(IDYMCustomer);
//     end;

//     local procedure DoCreateTrialCustomer(var IDYMCustomer: Record "IDYM Customer")
//     var
//         CompanyInformation: Record "Company Information";
//     begin
//         GetCompanyInformation(CompanyInformation);
//         InitStripeCustomer(IDYMCustomer, CompanyInformation);
//         StripeWebService.CreateCustomer(IDYMCustomer);
//         IDYMCustomer.Insert();
//     end;

//     local procedure GetCompanyInformation(var CompanyInformation: Record "Company Information")
//     begin
//         if not CompanyInformation.Get() then
//             CompanyInformation.Init();
//     end;

//     local procedure InitStripeCustomer(var IDYMCustomer: Record "IDYM Customer"; CompanyInformation: Record "Company Information")
//     begin
//         IDYMCustomer.Init();
//         IDYMCustomer.Name := CompanyInformation.Name;
//         IDYMCustomer.Email := CompanyInformation."E-Mail";
//         IDYMCustomer.Address := CompanyInformation.Address;
//         IDYMCustomer."Postal Code" := CompanyInformation."Post Code";
//         IDYMCustomer.City := CompanyInformation.City;
//         IDYMCustomer.State := CompanyInformation.County;
//         IDYMCustomer."Country/Region Code" := CompanyInformation."Country/Region Code";
//     end;

//     [IntegrationEvent(false, false)]
//     procedure OnCreateSubscription()
//     begin
//     end;

//     [NonDebuggable]
//     procedure GetSecretKey() SecretKey: Text[150]
//     begin
//         OnGetSecretKey(SecretKey);
//         if SecretKey <> '' then
//             exit(SecretKey);

//         PaymentSetup.GetSetup();
//         if PaymentSetup.Sandbox then
//             exit('sk_test_51NJbjrFCpIKjWoFldnUgiveabAznkXp119UQI8Y82Qca1Dwx5YdD4hLJ9Q4tAtoHlXxF6tZluAWc8OvzQca8m5OX00RECr3Brc'); //test
//         exit('sk_test_51NJbjrFCpIKjWoFldnUgiveabAznkXp119UQI8Y82Qca1Dwx5YdD4hLJ9Q4tAtoHlXxF6tZluAWc8OvzQca8m5OX00RECr3Brc'); //live, TODO
//     end;

//     [NonDebuggable]
//     procedure GetPublishableKey() PublishableKey: Text[150]
//     begin
//         OnGetPublishableKey(PublishableKey);
//         if PublishableKey <> '' then
//             exit(PublishableKey);

//         PaymentSetup.GetSetup();
//         if PaymentSetup.Sandbox then
//             exit('pk_test_51NJbjrFCpIKjWoFlnn4oPSqFBM6oXp0ZPNmhFQA3zNbw0sKxT6T3RfJPrF9GYmP3fA7zfS9ObcUIzDU2goqANvB800EwuenGA6'); //test
//         exit('pk_test_51NJbjrFCpIKjWoFlnn4oPSqFBM6oXp0ZPNmhFQA3zNbw0sKxT6T3RfJPrF9GYmP3fA7zfS9ObcUIzDU2goqANvB800EwuenGA6'); //live, TODO
//     end;

//     [IntegrationEvent(false, false)]
//     local procedure OnGetPublishableKey(PublishableKey: Text[150])
//     begin
//     end;

//     [IntegrationEvent(false, false)]
//     local procedure OnGetSecretKey(SecretKey: Text[150])
//     begin
//     end;

//     var
//         PaymentSetup: Record "IDYM Payment Setup";
//         StripeWebService: Codeunit "IDYM Stripe Web Service";
//         StripeManagement: Codeunit "IDYM Stripe Management";
// }