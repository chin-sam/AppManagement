controladdin "IDYM PayPal Payment Addin"
{
    RequestedHeight = 150;
    RequestedWidth = 280;
    VerticalStretch = true;
    HorizontalStretch = true;
    Scripts = 'https://code.jquery.com/jquery-1.9.1.min.js',
              'Payment/Addins/NonSDKPayPalButton/js/IDYNPAYPayPalAddin.js';
    StyleSheets = 'Payment/Addins/NonSDKPayPalButton/css/IDYNPAYPayPal.css';
    Images = 'Payment/Addins/NonSDKPayPalButton/PayPal_Logo.png', 'Payment/Addins/NonSDKPayPalButton/PayPal_Btn.png', 'Payment/Addins/NonSDKPayPalButton/Card_Btn.png';

    event AddinLoaded();

    procedure Initialize(LanguageID: Integer; ImageName: Text; InputText: Text);

    event ButtonPressed();

    procedure addButton(ButtonName: Text; ImageName: Text);
}