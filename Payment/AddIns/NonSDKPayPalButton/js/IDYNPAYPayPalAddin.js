$(document).ready(function () {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('AddinLoaded', null);
});

function Initialize(LanguageID,ImageName,InputText)
{
    var ImageURL = Microsoft.Dynamics.NAV.GetImageResource(ImageName);

    $("#controlAddIn").append(InputText);
}

function addButton(buttonName,ImageName) {
    var ImageHTML = '';    
    var ImageURL = Microsoft.Dynamics.NAV.GetImageResource(ImageName);
    var placeholder = document.getElementById('controlAddIn');
    var button = document.createElement('button');

    button.textContent = buttonName;
    ImageHTML = "<div style='padding-bottom: 10.5pt'><img width=inherit src='" + ImageURL + " alt='Powered by Paypal'/></div>";
    button.innerHTML = ImageHTML;

    button.onclick = function() {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ButtonPressed', null);
    }    
    placeholder.appendChild(button); 
}   