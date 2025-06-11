table 11155301 "IDYM Payment Setup"
{
    DataClassification = SystemMetadata;
    Access = Internal;
    Caption = 'Payment Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = SystemMetadata;
            Caption = 'Primary Key';
        }
        field(2; "Last Synchronized"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Last Synchronized';
        }
        field(4; Sandbox; Boolean)
        {
            Caption = 'Sandbox Mode';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetSetup()
    begin
        if not FindFirst() then begin
            Init();
            Insert();
        end;
    end;

    procedure ResetSync()
    begin
        "Last Synchronized" := 0DT;
    end;

    #region [Paypal]
    [NonDebuggable]
    internal procedure GetPaypalUserName() UserName: Text[150];
    var
        AuthorizationGuid: Guid;
    begin
        OnAuthorizePaypalAccountUpdate(AuthorizationGuid);
        if not IsNullGuid(AuthorizationGuid) then begin
            CheckAuthorization(AuthorizationGuid);
            OnGetPaypalUserName(UserName);
            if UserName <> '' then
                exit(UserName);
        end;

        if Rec.Sandbox then
            exit('Ae5TpTaVJNpJlmiNuANZkEk9ji_BfNmRbmrAgPNREQ4cF6wu1TWqAoGuBdaWlbKDVQ-976Hmpys9QbNb'); //test
        exit('ASOW3IxpaPFJsSLUp3LsgLzppO7a31EJR4xwXX0W2J2VX4Tz2Vx2uFc_xI_tHChS8Bqdkb9aHEq8Gm74'); //live
    end;

    [NonDebuggable]
    internal procedure GetPaypalSecret() Secret: Text[150];
    var
        AuthorizationGuid: Guid;
    begin
        OnAuthorizePaypalAccountUpdate(AuthorizationGuid);
        if not IsNullGuid(AuthorizationGuid) then begin
            CheckAuthorization(AuthorizationGuid);
            OnGetPaypalSecret(Secret);
            if Secret <> '' then
                exit(Secret);
        end;

        if Rec.Sandbox then
            exit('EMHEipkwA9qA3Ucus7GcsxJPKdcBQ8EwT_B3wxCuoopUh3CRBK4rJgzInqGxTTPCiq4pRmZI43FeYdJ_'); //test
        exit('EEFkhftKsCk-ZVlsCOxpx8HEYciRuit7PmXXxGYZmpepJetHjMa_uGlZgFoXowjfQx8cXG069cyRiho5'); //live
    end;

    [NonDebuggable]
    local procedure CheckAuthorization(AuthorizationGuid: Guid)
    var
        AuthorizationInvalidErr: Label 'Authorization %1 is not valid', Comment = '%1 entered authorization code';
    begin
        if AuthorizationGuid <> 'ad32ced7-d54c-4188-ab37-4c2c747e094e' then
            Error(AuthorizationInvalidErr, AuthorizationGuid);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAuthorizePaypalAccountUpdate(var AuthorizationGuid: Guid);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPaypalUserName(PublishableKey: Text[150])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPaypalSecret(SecretKey: Text[150])
    begin
    end;
    #endregion
}