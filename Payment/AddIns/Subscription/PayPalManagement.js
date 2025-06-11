function LoadScript(ClientId)
{
    const script = document.createElement('script');
    script.src = 'https://www.paypal.com/sdk/js?client-id=' + ClientId + '&components=buttons&vault=true&intent=subscription';
    document.head.prepend(script);
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnLoadScript', null);
}

function InitSubscriptionButton(SubscriptionRequestObject)
{
    // https://developer.paypal.com/sdk/js/reference/
    paypal.Buttons({
        style: {
          layout: 'horizontal'
        },

        createSubscription: function(data, actions) {
          return actions.subscription.create(SubscriptionRequestObject);
        },
        onApprove: function(data, actions) {
          var arguments = [data.subscriptionID];
          Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnApprove', arguments);
        },
        onError(err) {
          // TODO Might require separated handling
          alert(err);
        }
      }).render('#btn-paypal-checkout');    
}