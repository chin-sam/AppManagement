// codeunit 11155295 "IDYM Logging Helper"
// {
//     var
//         AppSetting: Record "IDYM App Setting";
//         LogEntry: Record "IDYM Log Entry";
//         CallerModuleInfo: ModuleInfo;
//         StartDateTime: DateTime;
//         ParentEntryNo: Integer;

//     procedure InitLogEntry(LoggingLevel: Enum "IDYM Logging Type"; LogAction: Enum "IDYM Log Action"; ObjectType: Option "TableData","Table",,"Report",,"Codeunit","XMLport","MenuSuite","Page","Query","System","FieldNumber",,,"PageExtension","TableExtension","Enum","EnumExtension","Profile","ProfileExtension"; ObjectId: Integer; Message: Text)
//     begin
//         if IsNullGuid(CallerModuleInfo.Id) then
//             NavApp.GetCallerModuleInfo(CallerModuleInfo);
//         GetOrCreateAppSetting(CallerModuleInfo.Id, CopyStr(CallerModuleInfo.Name(), 1, MaxStrLen(LogEntry."App Name")));
//         LogEntry.Init();
//         LogEntry.Validate("App ID", CallerModuleInfo.Id);
//         LogEntry.Validate("App Name", AppSetting."App Name");
//         LogEntry.Validate("App Version", CopyStr(Format(CallerModuleInfo.AppVersion), 1, MaxStrLen(LogEntry."App Version")));
//         LogEntry."User Security ID" := UserSecurityId();
//         LogEntry.Validate("Log Action", LogAction);
//         if ParentEntryNo <> 0 then
//             LogEntry.Validate("Parent Entry No.", ParentEntryNo);
//         LogEntry.Validate("Logging Type", LoggingLevel);
//         LogEntry.Validate("Object Type", ObjectType);
//         LogEntry.Validate("Object ID", ObjectId);
//         LogEntry.Message := CopyStr(Message, 1, MaxStrLen(LogEntry.Message));
//         LogEntry."Execution Date/Time" := CurrentDateTime();
//         if StartDateTime <> 0DT then
//             LogEntry.Duration := CurrentDateTime - StartDateTime;
//     end;

//     procedure WriteLogEntry(LoggingLevel: Enum "IDYM Logging Type"; LogAction: Enum "IDYM Log Action"; ObjectType: Option "TableData","Table",,"Report",,"Codeunit","XMLport","MenuSuite","Page","Query","System","FieldNumber",,,"PageExtension","TableExtension","Enum","EnumExtension","Profile","ProfileExtension"; ObjectId: Integer; Message: Text) LastEntryNo: Integer
//     begin
//         if IsNullGuid(CallerModuleInfo.Id) then
//             NavApp.GetCallerModuleInfo(CallerModuleInfo);
//         InitLogEntry(LoggingLevel, LogAction, ObjectType, ObjectId, Message);
//         LogEntry.Insert(true);
//         exit(LogEntry."Entry No.");
//     end;

//     procedure WriteLogEntry(LoggingLevel: Enum "IDYM Logging Type"; LogAction: Enum "IDYM Log Action"; ObjectType: Option "TableData","Table",,"Report",,"Codeunit","XMLport","MenuSuite","Page","Query","System","FieldNumber",,,"PageExtension","TableExtension","Enum","EnumExtension","Profile","ProfileExtension"; ObjectId: Integer; Message: Text; JSONRequest: JsonObject) LastEntryNo: Integer
//     var
//         JSONResponse: JsonObject;
//     begin
//         NavApp.GetCallerModuleInfo(CallerModuleInfo);
//         exit(WriteLogEntry(LoggingLevel, LogAction, ObjectType, ObjectId, Message, JSONRequest, JSONResponse));
//     end;

//     procedure WriteLogEntry(LoggingLevel: Enum "IDYM Logging Type"; LogAction: Enum "IDYM Log Action"; ObjectType: Option "TableData","Table",,"Report",,"Codeunit","XMLport","MenuSuite","Page","Query","System","FieldNumber",,,"PageExtension","TableExtension","Enum","EnumExtension","Profile","ProfileExtension"; ObjectId: Integer; Message: Text; JSONRequest: JsonObject; JSONResponse: JsonObject) LastEntryNo: Integer
//     var
//         RequestOutStream: OutStream;
//         ResponseOutStream: OutStream;
//         JsonString: Text;
//     begin
//         if IsNullGuid(CallerModuleInfo.Id) then
//             NavApp.GetCallerModuleInfo(CallerModuleInfo);
//         InitLogEntry(LoggingLevel, LogAction, ObjectType, ObjectId, Message);
//         if JSONRequest.WriteTo(JsonString) then begin
//             LogEntry.Request.CreateOutStream(RequestOutStream);
//             RequestOutStream.Write(JsonString);
//         end;

//         if JSONResponse.WriteTo(JsonString) then begin
//             LogEntry.Response.CreateOutStream(ResponseOutStream);
//             RequestOutStream.Write(JsonString);
//         end;
//         LogEntry.Insert(true);
//         LastEntryNo := LogEntry."Entry No.";
//     end;

//     procedure WriteLogEntry(LoggingLevel: Enum "IDYM Logging Type"; LogAction: Enum "IDYM Log Action"; ObjectType: Option "TableData","Table",,"Report",,"Codeunit","XMLport","MenuSuite","Page","Query","System","FieldNumber",,,"PageExtension","TableExtension","Enum","EnumExtension","Profile","ProfileExtension"; ObjectId: Integer; Message: Text; RequestInStream: InStream) LastEntryNo: Integer
//     var
//         RequestOutStream: OutStream;
//     begin
//         NavApp.GetCallerModuleInfo(CallerModuleInfo);
//         InitLogEntry(LoggingLevel, LogAction, ObjectType, ObjectId, Message);
//         LogEntry.Request.CreateOutStream(RequestOutStream);
//         CopyStream(RequestOutStream, RequestInStream);
//         LogEntry.Insert(true);
//         LastEntryNo := LogEntry."Entry No.";
//     end;

//     procedure WriteLogEntry(LoggingLevel: Enum "IDYM Logging Type"; LogAction: Enum "IDYM Log Action"; ObjectType: Option "TableData","Table",,"Report",,"Codeunit","XMLport","MenuSuite","Page","Query","System","FieldNumber",,,"PageExtension","TableExtension","Enum","EnumExtension","Profile","ProfileExtension"; ObjectId: Integer; Message: Text; RequestInStream: InStream; ResponseInStream: InStream) LastEntryNo: Integer
//     var
//         RequestOutStream: OutStream;
//         ResponseOutStream: OutStream;
//     begin
//         NavApp.GetCallerModuleInfo(CallerModuleInfo);
//         InitLogEntry(LoggingLevel, LogAction, ObjectType, ObjectId, Message);

//         LogEntry.Request.CreateOutStream(RequestOutStream);
//         CopyStream(RequestOutStream, RequestInStream);

//         LogEntry.Response.CreateOutStream(ResponseOutStream);
//         CopyStream(ResponseOutStream, ResponseInStream);
//         LogEntry.Insert(true);
//         LastEntryNo := LogEntry."Entry No.";
//     end;

//     procedure CleanUpLogEntries()
//     var
//         LastDate: Date;
//         LastDateTime: DateTime;
//     begin
//         //to do should have job queue to clean up
//         NavApp.GetCallerModuleInfo(CallerModuleInfo);
//         GetOrCreateAppSetting(CallerModuleInfo.Id, CopyStr(CallerModuleInfo.Name(), 1, MaxStrLen(LogEntry."App Name")));

//         LastDate := CalcDate(AppSetting."Retention Period", Today);
//         LastDateTime := CreateDateTime(LastDate, 0T);

//         LogEntry.Reset();
//         LogEntry.SetRange("App ID", CallerModuleInfo.Id);
//         LogEntry.SetFilter("Execution Date/Time", '..%1', LastDateTime);
//         if not LogEntry.IsEmpty then
//             LogEntry.DeleteAll(true);
//     end;

//     procedure SetStartDateTime(NewDateTime: DateTime)
//     begin
//         StartDateTime := NewDateTime;
//     end;

//     procedure SetParentEntry(MainEntryNo: Integer)
//     begin
//         ParentEntryNo := MainEntryNo;
//     end;

//     local procedure GetOrCreateAppSetting(AppId: Guid; AppName: Text[100])
//     begin
//         if AppSetting."App Id" <> AppId then
//             if not AppSetting.Get(AppId) then begin
//                 AppSetting.Init();
//                 AppSetting.Validate("App Id", AppId);
//                 AppSetting.Validate("App Name", AppName);
//                 AppSetting.Insert(true);
//             end;
//     end;
// }