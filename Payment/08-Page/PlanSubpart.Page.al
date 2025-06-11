// page 11155290 "IDYM Plan Subpart"
// {
//     PageType = ListPart;
//     SourceTable = "IDYM Plan";
//     InsertAllowed = false;
//     DeleteAllowed = false;
//     Caption = 'Plans';

//     layout
//     {
//         area(Content)
//         {
//             repeater(StripePlans)
//             {
//                 field(Select; Rec.Select)
//                 {
//                     ShowCaption = false;
//                     ApplicationArea = All;
//                     ToolTip = 'Click on this box to select this price plan.';
//                     trigger OnValidate()
//                     begin
//                         CurrPage.Update(true);
//                         if Rec.Select then begin
//                             Rec.SetRange(Select, true);
//                             Rec.SetFilter(Id, '<>%1', Rec.Id);
//                             if Rec.FindFirst() then begin
//                                 Rec.Select := false;
//                                 Rec.Modify();
//                             end;
//                             Rec.SetRange(Id);
//                             Rec.FindFirst();
//                             Rec.SetRange(Select);
//                         end;
//                     end;
//                 }
//                 field("Product Name"; Rec."Product Name")
//                 {
//                     ApplicationArea = All;
//                     Width = 15;
//                     ToolTip = 'Specifies the name of the product for which a usage license is purchased.';
//                 }
//                 field(Amount; Rec.Amount)
//                 {
//                     ApplicationArea = All;
//                     Editable = false;
//                     Caption = 'Amount';
//                     ToolTip = 'Specifies the amount for the current price plan.';
//                 }
//                 field(Currency; Rec.Currency)
//                 {
//                     ApplicationArea = All;
//                     Editable = false;
//                     ToolTip = 'Specifies the currency in which the amount is specified for the current price plan.';
//                 }
//                 field("Interval Count"; Rec."Interval Count")
//                 {
//                     ApplicationArea = All;
//                     Editable = false;
//                     ToolTip = 'Specifies how many intervals are used for this price plan to check if the price plan is still valid.';
//                 }
//                 field(Interval; Rec.Interval)
//                 {
//                     ApplicationArea = All;
//                     Editable = false;
//                     ToolTip = 'Specifies how often it will be checked if this price plan is still valid.';
//                 }
//             }
//         }
//     }

//     trigger OnOpenPage()
//     begin
//         //StripeWebService.GetPlans(Rec);
//         Rec.SetRange("Product Id", ProductId);
//         Rec.SetRange("Payment Provider", PaymentProvider);
//         //Rec.SetRange("Internal Invoice", InternalId);
//         Rec.SetRange(Active, true);
//     end;

//     procedure HasSelectedPlan() ReturnValue: Boolean
//     begin
//         Rec.SetRange(Select, true);
//         ReturnValue := not Rec.IsEmpty();
//         Rec.SetRange(Select);
//     end;

//     procedure GetSelectedPlan(var Plan: Record "IDYM Plan")
//     begin
//         Rec.SetRange(Select, true);
//         Rec.FindFirst();
//         Plan := Rec;
//     end;

//     procedure SetParameters(NewProductId: Text[50]; NewPaymentProvider: Enum "IDYM Payment Provider")
//     begin
//         ProductId := NewProductId;
//         PaymentProvider := NewPaymentProvider;
//     end;

//     var
//         //StripeWebService: Codeunit "IDYM Stripe Web Service";
//         [InDataSet]
//         ProductId: Text[50];
//         PaymentProvider: Enum "IDYM Payment Provider";
// }