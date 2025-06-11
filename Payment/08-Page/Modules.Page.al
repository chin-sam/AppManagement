page 11155289 "IDYM Modules"
{
    PageType = ListPart;
    UsageCategory = None;
    SourceTable = "IDYM Module";
    Caption = 'Modules';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Select; Rec.Select)
                {
                    ApplicationArea = All;
                    Editable = false; //In the future this can be based on the optional field.
                    ToolTip = 'Select this module to activate it in your license.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'The name of the module that is included in your license.';
                }
                // field(Optional; Rec.Optional)
                // {
                //     ApplicationArea = All;                    
                //     ToolTip = 'Indicates if the module can be added as an option to the license or that it is mandatory.';
                // }
                field("Interval Count"; IntervalCount)
                {
                    ApplicationArea = All;
                    Caption = 'Interval Count';
                    Editable = false;
                    ToolTip = 'Specifies how many intervals are used for this price plan to check if the price plan is still valid.';
                }
                field(Interval; Interval)
                {
                    ApplicationArea = All;
                    Caption = 'Interval';
                    OptionCaption = 'Day,Week,Month,Year';
                    Editable = false;
                    ToolTip = 'Specifies how often it will be checked if this price plan is still valid.';
                }
                field(Amount; Rec.GetModulePrice(CurrencyCode, 0, PricePlanID))
                {
                    Caption = 'Amount';
                    ApplicationArea = All;
                    ToolTip = 'Indicates the price for the additional module.';
                }
                field(Currency; CurrencyCode)
                {
                    Caption = 'Currency Code';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the currency in which the amount is specified for the current price plan.';
                }
            }
        }
    }
    internal procedure GetSelectedModules(var Module: Record "IDYM Module")
    begin
        Module.CopyFilters(Rec);
        Module.SetRange(Select, true);
    end;

    internal procedure SetParameters(NewIntervalCount: Integer; NewInterval: Option; NewCurrencyCode: Code[10]; NewPricePlanId: Guid)
    begin
        IntervalCount := NewIntervalCount;
        Interval := NewInterval;
        CurrencyCode := NewCurrencyCode;
        PricePlanId := NewPricePlanId;
    end;

    var
        IntervalCount: Integer;
        Interval: Option Day,Week,Month,Year;
        CurrencyCode: Code[10];
        PricePlanId: Guid;
}