var html = '<div id="btn-paypal-checkout"></div>';
var control = document.getElementById('controlAddIn');
control.innerHTML = html;
Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnControlAddinStart', null);
