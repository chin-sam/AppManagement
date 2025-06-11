table 11155304 "IDYM Apphub Subscription"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Id';
            Editable = false;
        }
        field(2; "License Key"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'License Key';
            Editable = false;
        }
        field(3; "App Id"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'App Id';
            Editable = false;
        }
        field(4; "Payment Due"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Payment Due';
            Editable = false;
        }
        field(5; "Payment Blocked"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Payment Blocked';
            Editable = false;
        }
        field(10; "Recipient Name"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Recipient Name';
        }
        field(11; "Recipient Email"; Text[80])
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Caption = 'Recipient E-Mail';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            begin
                ValidateEmail();
            end;
        }
        field(50; Submitted; Boolean)
        {
            Caption = 'Submitted';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    local procedure ValidateEmail();
    var
        MailManagement: Codeunit "Mail Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateEmail(Rec, IsHandled, xRec);
        if IsHandled then
            exit;

        if "Recipient Email" = '' then
            exit;
        MailManagement.CheckValidEmailAddresses("Recipient Email");
    end;

    internal procedure SetUnrestricedAccess()
    begin
        UnrestricedAccess := true;
    end;

    internal procedure HasUnrestricedAccess(): Boolean
    begin
        exit(UnrestricedAccess);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateEmail(var ApphubSubscription: Record "IDYM Apphub Subscription"; var IsHandled: Boolean; xApphubSubscription: Record "IDYM Apphub Subscription")
    begin
    end;

    protected var
        UnrestricedAccess: Boolean;
}