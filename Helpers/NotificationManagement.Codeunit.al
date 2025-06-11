codeunit 11155302 "IDYM Notification Management"
{
    procedure SendNotification(NotificationId: Guid; NotificationMessage: Text; DataPropertyName: Text; DataPropertyValue: Text)
    var
        Notification: Notification;
    begin
        Notification.Id(NotificationId);
        Notification.Recall();
        Notification.Message(NotificationMessage);
        Notification.SetData(DataPropertyName, DataPropertyValue);
        Notification.Scope(NotificationScope::LocalScope);
        AddActions(Notification);
        Notification.Send();
    end;

    procedure SendNotification(NotificationId: Guid; NotificationMessage: Text)
    var
        Notification: Notification;
    begin
        Notification.Id(NotificationId);
        Notification.Recall();
        Notification.Message(NotificationMessage);
        Notification.Scope(NotificationScope::LocalScope);
        AddActions(Notification);
        Notification.Send();
    end;

    procedure SendNotification(NotificationMessage: Text)
    var
        Notification: Notification;
    begin
        Notification.Scope(NotificationScope::LocalScope);
        Notification.Message(NotificationMessage);
        Notification.Send();
    end;

    local procedure AddActions(var Notification: Notification)
    var
        i: Integer;
        Token: JsonToken;
        ActionObject: JsonObject;
        ActionCaption: Text;
        ActionCodeunitId: Integer;
        ActionMethodName: Text;
    begin
        if ActionArray.Count > 0 then
            for i := 0 to ActionArray.Count() - 1 do begin
                ActionArray.Get(i, Token);
                ActionObject := Token.AsObject();
                if ActionObject.Get('NotificationId', Token) then
                    if Notification.Id = Token.AsValue().AsText() then begin
                        if ActionObject.Get('Caption', Token) then
                            ActionCaption := Token.AsValue().AsText();
                        if ActionObject.Get('CodeunitID', Token) then
                            ActionCodeunitId := Token.AsValue().AsInteger();
                        if ActionObject.Get('MethodName', Token) then
                            ActionMethodName := Token.AsValue().AsText();
                        Notification.AddAction(ActionCaption, ActionCodeunitId, ActionMethodName);
                    end;
            end;
    end;

    procedure AddAction(NotificationId: Guid; ActionCaption: Text; ActionCodeunitId: Integer; ActionMethodName: Text)
    var
        ActionJson: JsonObject;
    begin
        ActionJson.Add('NotificationId', NotificationId);
        ActionJson.Add('Caption', ActionCaption);
        ActionJson.Add('CodeunitID', ActionCodeunitId);
        ActionJson.Add('MethodName', ActionMethodName);
        ActionArray.Add(ActionJson);
    end;

    procedure RecallNotification(NotificationId: Guid)
    var
        Notification: Notification;
    begin
        Notification.Id(NotificationId);
        Notification.Recall();
    end;

    procedure HideNotification(NotificationId: Guid)
    var
        Notification: Notification;
    begin
        Notification.Id(NotificationId);
        HideNotification(Notification);
    end;

    local procedure HideNotification(EnabledNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.Disable(EnabledNotification.Id());
    end;

    procedure IsEnabled(NotificationId: Guid): Boolean
    var
        Notification: Notification;
    begin
        Notification.Id(NotificationId);
        exit(IsEnabled(Notification));
    end;

    local procedure IsEnabled(MyNotification: Notification) Enabled: Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        Enabled := MyNotifications.IsEnabled(MyNotification.Id());
    end;

    var
        ActionArray: JsonArray;
}