table 11155302 "IDYM Subscription"
{
    DataClassification = SystemMetadata;
    Access = Internal;
    Extensible = false;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Text[50])
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(2; "Payment Provider"; Enum "IDYM Payment Provider")
        {
            Caption = 'Provider';
            DataClassification = SystemMetadata;
        }
        field(3; "License Key"; Text[50])
        {
            Caption = 'License Key';
            DataClassification = SystemMetadata;
            TableRelation = "IDYM App License Key"."License Key";
            ValidateTableRelation = false;
            NotBlank = true;
        }
        field(10; "Created"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Created';
        }
        field(11; "Current Period Start"; BigInteger)
        {
            DataClassification = SystemMetadata;
            Access = Internal;
            Caption = 'Current Period Start';
        }
        field(12; "Current Period End"; BigInteger)
        {
            DataClassification = SystemMetadata;
            Access = Internal;
            Caption = 'Current Period End';
        }
        field(13; "Subscription Item Id"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Subscription Item Id';
        }
        field(14; "Valid Until"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Valid Until';
        }
        field(15; "Plan Id"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'PLan Id';
        }
        field(16; Quantity; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Quantity';
        }
        field(17; Status; Enum "IDYM Subscription Status")
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
            Access = Internal;
        }
        field(18; "Trial Start"; Integer)
        {
            DataClassification = SystemMetadata;
            Access = Internal;
            Caption = 'Trial Start';
        }
        field(19; "Trial End"; Integer)
        {
            DataClassification = SystemMetadata;
            Access = Internal;
            Caption = 'Trial End';
        }
        field(21; "Status (External)"; Text[30])
        {
            DataClassification = SystemMetadata;
            Caption = 'Status (External)';

            trigger OnValidate()
            begin
                // ACTIVE:
                //     Stripe: active
                //     PayPal: ACTIVE
                // ERROR:
                //     Stripe: past_due, unpaid
                //     PayPal: SUSPENDED, EXPIRED
                // CANCELLED:
                //     Stripe: cancelled
                //     PayPal: CANCELLED
                // WAITING_FOR_ACTION:
                //     Stripe: incomplete, incomplete_expired
                //     PayPal: APPROVAL_PENDING, APPROVED
                // TRIALING
                //     Stripe: trialing
                //     PayPal: -    

                case Uppercase("Status (External)") of
                    'ACTIVE':
                        Status := Status::Active;
                    'TRIALING':
                        Status := Status::Trialing;
                    'EXPIRED':
                        Status := Status::Expired;
                    'PAST_DUE', 'UNPAID', 'SUSPENDED':
                        Status := Status::Error;
                    'INCOMPLETE', 'INCOMPLETE_EXPIRED', 'APPROVAL_PENDING', 'APPROVED':
                        Status := Status::"Waiting for action";
                    'CANCELLED':
                        Status := Status::Cancelled;
                    else
                        Status := Status::Unknown;
                end;
            end;
        }
        field(22; "Product Id"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Product Id';
        }
        field(23; "Product Guid"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Product Guid';
        }
        field(24; "Subscription Data"; Blob)
        {
            DataClassification = SystemMetadata;
            Access = Internal;
            Caption = 'Subscription Data';
        }
    }

    keys
    {
        key(PK; Id, "Payment Provider")
        {
            Clustered = true;
        }
        key(Key1; Created)
        {
        }
    }

    internal procedure SetUnrestricedAccess()
    begin
        UnrestricedAccess := true;
    end;

    internal procedure HasUnrestricedAccess(): Boolean
    begin
        exit(UnrestricedAccess);
    end;

    internal procedure SetSubscriptionData(SubscriptionDataAsText: Text)
    var
        TextOutStream: OutStream;
    begin
        "Subscription Data".CreateOutStream(TextOutStream);
        TextOutStream.WriteText(SubscriptionDataAsText);
    end;

    internal procedure GetSubscriptionData(): Text
    var
        Output: Text;
        TextInStream: InStream;
    begin
        CalcFields("Subscription Data");
        "Subscription Data".CreateInStream(TextInStream);
        TextInStream.ReadText(Output);
        exit(Output);
    end;

    internal procedure IsSubscriptionValid(): Boolean;
    begin
        if Status in [Status::Trialing, Status::Active] then
            exit(true)
        else
            exit(false);
    end;

    internal procedure SubscriptionStatus(): Text[50]
    begin
        exit(format(Status));
    end;

    protected var
        UnrestricedAccess: Boolean;
}