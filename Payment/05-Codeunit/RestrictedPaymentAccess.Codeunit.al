codeunit 11155297 "IDYM Restricted Payment Access"
{
    [EventSubscriber(ObjectType::Table, Database::"IDYM Apphub Subscription", 'OnBeforeInsertEvent', '', true, false)]
    local procedure ApphubSubscription_OnBeforeInsertEvent(var Rec: Record "IDYM Apphub Subscription")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(InsertNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM Apphub Subscription", 'OnBeforeModifyEvent', '', true, false)]
    local procedure ApphubSubscription_OnBeforeModifyEvent(var Rec: Record "IDYM Apphub Subscription")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(ModifyNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM Apphub Subscription", 'OnBeforeDeleteEvent', '', true, false)]
    local procedure ApphubSubscription_OnBeforeDeleteEvent(var Rec: Record "IDYM Apphub Subscription")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(DeleteNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM App Price", 'OnBeforeInsertEvent', '', true, false)]
    local procedure AppPrice_OnBeforeInsertEvent(var Rec: Record "IDYM App Price")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(InsertNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM App Price", 'OnBeforeModifyEvent', '', true, false)]
    local procedure AppPrice_OnBeforeModifyEvent(var Rec: Record "IDYM App Price")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(ModifyNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM App Price", 'OnBeforeDeleteEvent', '', true, false)]
    local procedure AppPrice_OnBeforeDeleteEvent(var Rec: Record "IDYM App Price")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(DeleteNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM Module", 'OnBeforeInsertEvent', '', true, false)]
    local procedure Module_OnBeforeInsertEvent(var Rec: Record "IDYM Module")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(InsertNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM Module", 'OnBeforeModifyEvent', '', true, false)]
    local procedure Module_OnBeforeModifyEvent(var Rec: Record "IDYM Module")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(ModifyNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM Module", 'OnBeforeDeleteEvent', '', true, false)]
    local procedure Module_OnBeforeDeleteEvent(var Rec: Record "IDYM Module")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(DeleteNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM Plan", 'OnBeforeInsertEvent', '', true, false)]
    local procedure Plan_OnBeforeInsertEvent(var Rec: Record "IDYM Plan")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(InsertNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM Plan", 'OnBeforeModifyEvent', '', true, false)]
    local procedure Plan_OnBeforeModifyEvent(var Rec: Record "IDYM Plan")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(ModifyNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM Plan", 'OnBeforeDeleteEvent', '', true, false)]
    local procedure Plan_OnBeforeDeleteEvent(var Rec: Record "IDYM Plan")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(DeleteNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM Price Plan", 'OnBeforeInsertEvent', '', true, false)]
    local procedure PricePlan_OnBeforeInsertEvent(var Rec: Record "IDYM Price Plan")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(InsertNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM Price Plan", 'OnBeforeModifyEvent', '', true, false)]
    local procedure PricePlan_OnBeforeModifyEvent(var Rec: Record "IDYM Price Plan")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(ModifyNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM Price Plan", 'OnBeforeDeleteEvent', '', true, false)]
    local procedure PricePlan_OnBeforeDeleteEvent(var Rec: Record "IDYM Price Plan")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(DeleteNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM Product", 'OnBeforeInsertEvent', '', true, false)]
    local procedure Product_OnBeforeInsertEvent(var Rec: Record "IDYM Product")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(InsertNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM Product", 'OnBeforeModifyEvent', '', true, false)]
    local procedure Product_OnBeforeModifyEvent(var Rec: Record "IDYM Product")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(ModifyNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM Product", 'OnBeforeDeleteEvent', '', true, false)]
    local procedure Product_OnBeforeDeleteEvent(var Rec: Record "IDYM Product")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(DeleteNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM Subscription", 'OnBeforeInsertEvent', '', true, false)]
    local procedure Subscription_OnBeforeInsertEvent(var Rec: Record "IDYM Subscription")
    begin
        Rec.TestField("License Key");
        if not Rec.HasUnrestricedAccess() then
            Error(InsertNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM Subscription", 'OnBeforeModifyEvent', '', true, false)]
    local procedure Subscription_OnBeforeModifyEvent(var Rec: Record "IDYM Subscription")
    begin
        Rec.TestField("License Key");
        if not Rec.HasUnrestricedAccess() then
            Error(ModifyNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM Subscription", 'OnBeforeDeleteEvent', '', true, false)]
    local procedure Subscription_OnBeforeDeleteEvent(var Rec: Record "IDYM Subscription")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(DeleteNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM Tier", 'OnBeforeInsertEvent', '', true, false)]
    local procedure Tier_OnBeforeInsertEvent(var Rec: Record "IDYM Tier")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(InsertNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM Tier", 'OnBeforeModifyEvent', '', true, false)]
    local procedure Tier_OnBeforeModifyEvent(var Rec: Record "IDYM Tier")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(ModifyNotAllowedErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"IDYM Tier", 'OnBeforeDeleteEvent', '', true, false)]
    local procedure Tier_OnBeforeDeleteEvent(var Rec: Record "IDYM Tier")
    begin
        if not Rec.HasUnrestricedAccess() then
            Error(DeleteNotAllowedErr, Rec.TableCaption());
    end;

    var
        ModifyNotAllowedErr: Label 'Modifying a %1 record is not allowed.', Comment = '%1 = TableCaption Subscription';
        DeleteNotAllowedErr: Label 'Deleting a %1 record is not allowed.', Comment = '%1 = TableCaption Subscription';
        InsertNotAllowedErr: Label 'Inserting a %1 record is not allowed.', Comment = '%1 = TableCaption Subscription';
}