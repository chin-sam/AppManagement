enum 11155293 "IDYM Authorization Type"
{
    Extensible = true;

    value(0; Anonymous)
    {
        Caption = 'Anonymous';
    }
    value(10; Basic)
    {
        Caption = 'Basic Authorization';
    }
    value(20; Bearer)
    {
        Caption = 'Bearer Token';
    }
    value(30; ApiKey)
    {
        Caption = 'Api Key';
    }
}
