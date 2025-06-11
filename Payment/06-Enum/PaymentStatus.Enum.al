enum 11155295 "IDYM Payment Status"
{
    Extensible = true;

    value(0; Created)
    {
        Caption = 'Created';
    }
    value(1; Saved)
    {
        Caption = 'Saved';
    }
    value(2; Approved)
    {
        Caption = 'Approved';
    }
    value(3; Voided)
    {
        Caption = 'Voided';
    }
    value(4; Completed)
    {
        Caption = 'Completed';
    }
    value(5; "Action Required")
    {
        Caption = 'Action Required';
    }
    value(6; Cancelled)
    {
        Caption = 'Cancelled';
    }
    value(7; Error)
    {
        Caption = 'Error';
    }
}