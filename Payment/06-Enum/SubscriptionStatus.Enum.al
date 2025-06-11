enum 11155297 "IDYM Subscription Status"
{
    Extensible = true;

    value(0; Error)
    {
        Caption = 'Error';
    }
    value(1; Active)
    {
        Caption = 'Active';
    }
    value(3; Cancelled)
    {
        Caption = 'Cancelled';
    }
    value(4; "Waiting for action")
    {
        Caption = 'Waiting for action';
    }
    value(5; Trialing)
    {
        Caption = 'Trialing';
    }
    value(6; Expired)
    {
        Caption = 'Expired';
    }
    value(100; Unknown)
    {
        Caption = 'Unknown';
    }
}