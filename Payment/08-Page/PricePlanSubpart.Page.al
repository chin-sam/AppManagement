page 11155291 "IDYM Price Plan Subpart"
{
    PageType = ListPart;
    SourceTable = "IDYM Price Plan";
    InsertAllowed = false;
    DeleteAllowed = false;
    Caption = 'Plans';

    layout
    {
        area(Content)
        {
            repeater(PricePlans)
            {
                field(Select; Rec.Select)
                {
                    ApplicationArea = All;
                    ToolTip = 'Click on this box to select this price plan.';
                    trigger OnValidate()
                    begin
                        Rec.SetUnrestricedAccess();
                        CurrPage.Update(true);
                    end;
                }
                field("Description"; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the plan for which a usage license is purchased.';
                }
                field("Interval Count"; Rec."Interval Count")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies how many intervals are used for this price plan to check if the price plan is still valid.';
                }
                field(Interval; Rec.Interval)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies how often it will be checked if this price plan is still valid.';
                }
                field(Amount; Rec.GetPricePlanPrice(CurrencyCode, DummyVAT))
                {
                    ApplicationArea = All;
                    DecimalPlaces = 2 : 2;
                    Editable = false;
                    Caption = 'Amount';
                    ToolTip = 'Specifies the amount for the current price plan.';
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

    internal procedure HasSelectedPlan() ReturnValue: Boolean
    var
        PricePlan: Record "IDYM Price Plan";
    begin
        PricePlan.CopyFilters(Rec);
        PricePlan.SetRange(Select, true);
        ReturnValue := not PricePlan.IsEmpty();
    end;

    internal procedure GetSelectedPlan(var PricePlan: Record "IDYM Price Plan")
    begin
        PricePlan.CopyFilters(Rec);
        PricePlan.SetRange(Select, true);
        PricePlan.FindFirst();
    end;

    internal procedure SetParameters(NewAppId: Guid; NewCurrencyCode: Code[10])
    begin
        AppId := NewAppId;
        CurrencyCode := NewCurrencyCode;
        Rec.FilterGroup(10);
        Rec.SetRange("App Id", AppId);
        Rec.FilterGroup(0);
    end;

    var
        AppId: Guid;
        CurrencyCode: Code[10];
        DummyVAT: Decimal;
}