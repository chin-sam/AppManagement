controladdin "IDYM PayPal Subs. Control"
{
    RequestedHeight = 220;
    RequestedWidth = 220;
    VerticalStretch = true;
    HorizontalStretch = true;
    Scripts = 'https://code.jquery.com/jquery-1.9.1.min.js',
              'Payment/AddIns/Subscription/PayPalManagement.js';
    StartupScript = 'Payment/Addins/Subscription/PayPalStartup.js';

    event OnControlAddinStart();
    event OnLoadScript();
    procedure InitSubscriptionButton(ReqJsonObject: JsonObject);
    procedure LoadScript(ClientId: Text);
    event OnApprove(SubscriptionId: Text);
}