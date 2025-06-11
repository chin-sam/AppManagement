codeunit 11155291 "IDYM JSON Helper"
{
    procedure AddVariantValue(var Object: JsonObject; KeyName: Text; ValueAsVariant: Variant)
    var
        DecimalValue: Decimal;
        IntegerValue: Integer;
        TextValue: Text;
        BooleanValue: Boolean;
        CodeValue: Code[250];
        DateValue: Date;
        DateTimeValue: DateTime;
        TimeValue: Time;
        BigIntegerValue: BigInteger;
        DurationValue: Duration;
    begin
        case true of
            ValueAsVariant.IsDecimal():
                begin
                    DecimalValue := ValueAsVariant;
                    AddValue(Object, KeyName, DecimalValue);
                end;
            ValueAsVariant.IsBoolean():
                begin
                    BooleanValue := ValueAsVariant;
                    AddValue(Object, KeyName, BooleanValue);
                end;
            ValueAsVariant.IsText(),
            ValueAsVariant.IsDateFormula(),
            ValueAsVariant.IsGuid():
                begin
                    TextValue := ValueAsVariant;
                    AddValue(Object, KeyName, TextValue);
                end;
            ValueAsVariant.IsCode():
                begin
                    CodeValue := ValueAsVariant;
                    AddValue(Object, KeyName, CodeValue);
                end;
            ValueAsVariant.IsInteger():
                begin
                    IntegerValue := ValueAsVariant;
                    AddValue(Object, KeyName, IntegerValue);
                end;
            ValueAsVariant.IsBigInteger():
                begin
                    BigIntegerValue := ValueAsVariant;
                    AddValue(Object, KeyName, BigIntegerValue);
                end;
            ValueAsVariant.IsDateTime():
                begin
                    DateTimeValue := ValueAsVariant;
                    AddValue(Object, KeyName, DateTimeValue);
                end;
            ValueAsVariant.IsDate():
                begin
                    DateValue := ValueAsVariant;
                    AddValue(Object, KeyName, DateValue);
                end;
            ValueAsVariant.IsOption():
                begin
                    IntegerValue := ValueAsVariant;
                    AddValue(Object, KeyName, IntegerValue);
                end;
            ValueAsVariant.IsTime():
                begin
                    TimeValue := ValueAsVariant;
                    AddValue(Object, KeyName, TimeValue);
                end;
            ValueAsVariant.IsDuration():
                begin
                    DurationValue := ValueAsVariant;
                    AddValue(Object, KeyName, DurationValue);
                end;
        end;
    end;

    procedure AddValue(var Object: JsonObject; KeyName: Text; Value: Text)
    var
        ValueToAdd: JsonValue;
    begin
        ValueToAdd.SetValue(Value);
        Object.Add(KeyName, ValueToAdd);
    end;

    procedure AddValue(var Object: JsonObject; KeyName: Text; Value: Guid)
    var
        ValueToAdd: JsonValue;
    begin
        ValueToAdd.SetValue(LowerCase(DelChr(Format(Value), '=', '{}')));
        Object.Add(KeyName, ValueToAdd);
    end;

    procedure AddValue(var Object: JsonObject; KeyName: Text; Value: Integer)
    var
        ValueToAdd: JsonValue;
    begin
        ValueToAdd.SetValue(Value);
        Object.Add(KeyName, ValueToAdd);
    end;

    procedure AddValue(var Object: JsonObject; KeyName: Text; Value: BigInteger)
    var
        ValueToAdd: JsonValue;
    begin
        ValueToAdd.SetValue(Value);
        Object.Add(KeyName, ValueToAdd);
    end;

    procedure AddValue(var Object: JsonObject; KeyName: Text; Value: Boolean)
    var
        ValueToAdd: JsonValue;
    begin
        ValueToAdd.SetValue(Value);
        Object.Add(KeyName, ValueToAdd);
    end;

    procedure AddValue(var Object: JsonObject; KeyName: Text; Value: Decimal)
    var
        ValueToAdd: JsonValue;
    begin
        ValueToAdd.SetValue(Value);
        Object.Add(KeyName, ValueToAdd);
    end;

    procedure AddValue(var Object: JsonObject; KeyName: Text; Value: Duration)
    var
        ValueToAdd: JsonValue;
    begin
        ValueToAdd.SetValue(Value);
        Object.Add(KeyName, ValueToAdd);
    end;

    procedure AddValue(var Object: JsonObject; KeyName: Text; Value: DateTime)
    var
        ValueToAdd: JsonValue;
    begin
        ValueToAdd.SetValue(Value);
        Object.Add(KeyName, ValueToAdd);
    end;

    procedure AddValue(var Object: JsonObject; KeyName: Text; Value: Date)
    var
        ValueToAdd: JsonValue;
    begin
        ValueToAdd.SetValue(Value);
        Object.Add(KeyName, ValueToAdd);
    end;

    procedure AddValue(var Object: JsonObject; KeyName: Text; Value: Time)
    var
        ValueToAdd: JsonValue;
    begin
        ValueToAdd.SetValue(Value);
        Object.Add(KeyName, ValueToAdd);
    end;

    procedure Add(var Object: JsonObject; KeyName: Text; ObjectToAdd: JsonObject)
    begin
        Object.Add(KeyName, ObjectToAdd);
    end;

    procedure Add(var Object: JsonObject; KeyName: Text; ArrayToAdd: JsonArray)
    begin
        Object.Add(KeyName, ArrayToAdd);
    end;

    procedure Add(var Objects: JsonArray; ObjectToAdd: JsonObject)
    begin
        Objects.Add(ObjectToAdd);
    end;

    procedure DownloadJsonObject(Object: JsonObject; FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        JSONAsText: Text;
        FileInStream: InStream;
        FileOutStream: OutStream;
    begin
        Object.WriteTo(JSONAsText);
        TempBlob.CreateOutStream(FileOutStream);
        FileOutStream.WriteText(JSONAsText);
        TempBlob.CreateInStream(FileInStream);
        DownloadFromStream(FileInStream, 'Download', '', '', FileName);
    end;

    procedure TryGetObject(Object: JsonObject; KeyName: Text): Integer
    var
        ValueToken: JsonToken;
    begin
        if Object.Get(KeyName, ValueToken) then
            if ValueToken.IsObject() then
                exit(1);
        if ValueToken.IsArray() then
            exit(2);
        exit(3);
    end;

    procedure GetValue(Object: JsonObject; KeyName: Text; var JsonVal: JsonValue): Boolean
    var
        Token: JsonToken;
    begin
        if not Object.Contains(KeyName) then
            exit(false);

        Object.Get(KeyName, Token);
        if not Token.IsValue() then
            exit(false);

        JsonVal := Token.AsValue();
        if JsonVal.IsNull() or JsonVal.IsUndefined() then
            exit(false);
        if JsonVal.AsText() = '' then
            exit(false);
        exit(true);
    end;

    procedure GetArray(InputAsVariant: variant; KeyName: Text): JsonArray
    var
        ValueToken: JsonToken;
        Object: JsonObject;
        Token: JsonToken;
    begin
        if InputAsVariant.IsJsonObject() then begin
            Object := InputAsVariant;
            if Object.Get(KeyName, Token) then
                exit(Token.AsArray());
        end;
        if InputAsVariant.IsJsonToken() then begin
            Token := InputAsVariant;
            if Token.AsObject().Get(KeyName, ValueToken) then
                exit(ValueToken.AsArray());
        end;
    end;

    procedure GetCodeValue(Object: JsonObject; KeyName: Text): Code[250]
    begin
        exit(GetCodeValue(Object, KeyName, ''));
    end;

    procedure GetCodeValue(Token: JsonToken; KeyName: Text): Code[250]
    begin
        exit(GetCodeValue(Token.AsObject(), KeyName, ''));
    end;

    procedure GetCodeValue(Object: JsonObject; KeyName: Text; DefaultValue: Code[250]): Code[250]
    var
        JsonVal: JsonValue;
    begin
        if GetValue(Object, KeyName, JsonVal) then
            exit(CopyStr(JsonVal.AsCode(), 1, 250))
        else
            exit(DefaultValue);
    end;

    procedure GetTextValue(Object: JsonObject; KeyName: Text): Text
    begin
        exit(GetTextValue(Object, KeyName, ''));
    end;

    procedure GetTextValue(Token: JsonToken; KeyName: Text): Text
    begin
        exit(GetTextValue(Token.AsObject(), KeyName, ''));
    end;

    procedure GetTextValue(Object: JsonObject; KeyName: Text; DefaultValue: Text): Text
    var
        JsonVal: JsonValue;
    begin
        if GetValue(Object, KeyName, JsonVal) then
            exit(JsonVal.AsText())
        else
            exit(DefaultValue);
    end;

    procedure GetGuidValue(Object: JsonObject; KeyName: Text): Guid
    begin
        exit(GetGuidValue(Object, KeyName, '{00000000-0000-0000-0000-000000000000}'));
    end;

    procedure GetGuidValue(Token: JsonToken; KeyName: Text): Guid
    begin
        exit(GetGuidValue(Token.AsObject(), KeyName, '{00000000-0000-0000-0000-000000000000}'));
    end;

    procedure GetGuidValue(Object: JsonObject; KeyName: Text; DefaultValue: Guid): Guid
    var
        JsonVal: JsonValue;
        Val: Guid;
    begin
        if GetValue(Object, KeyName, JsonVal) then
            if Evaluate(Val, JsonVal.AsText()) then
                exit(Val);

        exit(DefaultValue);
    end;

    procedure GetIntegerValue(Token: JsonToken; KeyName: Text): Integer
    begin
        exit(GetIntegerValue(Token.AsObject(), KeyName, 0));
    end;

    procedure GetIntegerValue(Object: JsonObject; KeyName: Text): Integer
    begin
        exit(GetIntegerValue(Object, KeyName, 0));
    end;

    procedure GetIntegerValue(Object: JsonObject; KeyName: Text; DefaultValue: Integer) ReturnInt: Integer
    var
        TypeHelper: Codeunit "Type Helper";
        JsonVal: JsonValue;
        IntAsVariant: Variant;
    begin
        if GetValue(Object, KeyName, JsonVal) then begin
            IntAsVariant := ReturnInt;
            if not TypeHelper.Evaluate(IntAsVariant, JsonVal.AsText(), '', '') then
                Error(CouldNotCastErr, JsonVal.AsText(), Format(IDYMField.Type::Integer));
            if IntAsVariant.IsInteger then
                ReturnInt := IntAsVariant;
        end else
            exit(DefaultValue);
    end;

    procedure GetBigIntegerValue(Object: JsonObject; KeyName: Text): BigInteger
    begin
        exit(GetBigIntegerValue(Object, KeyName, 0));
    end;

    procedure GetBigIntegerValue(Object: JsonObject; KeyName: Text; DefaultValue: BigInteger): BigInteger
    var
        JsonVal: JsonValue;
        Val: BigInteger;
    begin
        if GetValue(Object, KeyName, JsonVal) then begin
            if not Evaluate(Val, JsonVal.AsText()) then
                Error(CouldNotCastErr, JsonVal.AsText(), 'BigInteger');

            exit(JsonVal.AsBigInteger())
        end else
            exit(DefaultValue);
    end;

    procedure GetDecimalValue(Object: JsonObject; KeyName: Text): Decimal
    begin
        exit(GetDecimalValue(Object, KeyName, 0));
    end;

    procedure GetDecimalValue(Token: JsonToken; KeyName: Text): Decimal
    begin
        exit(GetDecimalValue(Token.AsObject(), KeyName, 0));
    end;

    procedure GetDecimalValue(Object: JsonObject; KeyName: Text; DefaultValue: Decimal) ReturnDecimal: Decimal
    var
        TypeHelper: Codeunit "Type Helper";
        JsonVal: JsonValue;
        DecimalAsVariant: Variant;
    begin
        if GetValue(Object, KeyName, JsonVal) then begin
            DecimalAsVariant := ReturnDecimal;
            if not TypeHelper.Evaluate(DecimalAsVariant, JsonVal.AsText(), '', '') then
                Error(CouldNotCastErr, JsonVal.AsText(), Format(IDYMField.Type::Decimal));
            if DecimalAsVariant.IsDecimal then
                ReturnDecimal := DecimalAsVariant;
        end else
            exit(DefaultValue);
    end;

    procedure GetBooleanValue(Object: JsonObject; KeyName: Text): Boolean
    begin
        exit(GetBooleanValue(Object, KeyName, false));
    end;

    procedure GetBooleanValue(Token: JsonToken; KeyName: Text): Boolean
    begin
        exit(GetBooleanValue(Token.AsObject(), KeyName, false));
    end;

    procedure GetBooleanValue(Object: JsonObject; KeyName: Text; DefaultValue: Boolean): Boolean
    var
        JsonVal: JsonValue;
        Val: Boolean;
    begin
        if GetValue(Object, KeyName, JsonVal) then begin
            if not Evaluate(Val, JsonVal.AsText()) then
                Error(CouldNotCastErr, JsonVal.AsText(), 'boolean');

            exit(JsonVal.AsBoolean())
        end else
            exit(DefaultValue);
    end;

    procedure GetDateValue(Object: JsonObject; KeyName: Text): Date
    begin
        exit(GetDateValue(Object, KeyName, 0D));
    end;

    procedure GetDateValue(Object: JsonObject; KeyName: Text; DefaultValue: Date) ReturnDate: Date
    var
        TypeHelper: Codeunit "Type Helper";
        JsonVal: JsonValue;
        DateAsVariant: Variant;
    begin
        if GetValue(Object, KeyName, JsonVal) then begin
            DateAsVariant := ReturnDate;
            if not TypeHelper.Evaluate(DateAsVariant, JsonVal.AsText(), '', '') then
                if Evaluate(ReturnDate, JsonVal.AsText()) then
                    exit
                else
                    Error(CouldNotCastErr, JsonVal.AsText(), Format(IDYMField.Type::Date));
            if DateAsVariant.IsDate then
                ReturnDate := DateAsVariant;
        end else
            exit(DefaultValue);
    end;

    procedure GetDateTimeValue(Object: JsonObject; KeyName: Text): DateTime
    begin
        exit(GetDateTimeValue(Object, KeyName, 0DT));
    end;

    procedure GetDateTimeValue(Token: JsonToken; KeyName: Text): DateTime
    var
        Object: JsonObject;
    begin
        Object := Token.AsObject();
        exit(GetDateTimeValue(Object, KeyName, 0DT));
    end;

    procedure GetDateTimeValue(Object: JsonObject; KeyName: Text; DefaultValue: DateTime) ReturnDT: DateTime
    var
        JsonVal: JsonValue;
    begin
        if GetValue(Object, KeyName, JsonVal) then
            ReturnDT := GetDateTimeValue(JsonVal.AsText())
        else
            exit(DefaultValue);
    end;

    procedure GetDateTimeValue(DateTimeInXMLFormat: Text) ReturnDT: DateTime
    var
        TypeHelper: Codeunit "Type Helper";
        DateTimeAsVariant: Variant;
        DateTimeAsText: Text;
    begin
        DateTimeAsVariant := ReturnDT;
        DateTimeAsText := DateTimeInXMLFormat;
        DateTimeAsText := DelChr(DateTimeAsText, '>', 'Z'); //Z gives an issue when the clock changes from / to summertime

        if not TypeHelper.Evaluate(DateTimeAsVariant, DateTimeAsText, '', '') then
            if Evaluate(ReturnDT, DateTimeInXMLFormat) then
                exit
            else
                Error(CouldNotCastErr, DateTimeInXMLFormat, Format(IDYMField.Type::DateTime));
        if DateTimeAsVariant.IsDateTime then begin
            ReturnDT := DateTimeAsVariant;
            if DateTimeAsText <> DateTimeInXMLFormat then //if Z was found at the end
                ReturnDT := ConvertUTCDateTimeToDT(ReturnDT);
        end;
    end;

    procedure GetObject(InputAsVariant: Variant; KeyName: Text): JsonObject
    var
        ValueToken: JsonToken;
        Object: JsonObject;
        Token: JsonToken;
    begin
        if InputAsVariant.IsJsonObject() then begin
            Object := InputAsVariant;
            Object.Get(KeyName, ValueToken);
            exit(ValueToken.AsObject());
        end;
        if InputAsVariant.IsJsonToken() then begin
            Token := InputAsVariant;
            Token.AsObject().Get(KeyName, ValueToken);
            exit(ValueToken.AsObject());
        end;
    end;

    procedure GetTimeValue(Object: JsonObject; KeyName: Text): Time
    begin
        exit(GetTimeValue(Object, KeyName, 0T));
    end;

    procedure GetTimeValue(Token: JsonToken; KeyName: Text): Time
    var
        Object: JsonObject;
    begin
        Object := Token.AsObject();
        exit(GetTimeValue(Object, KeyName, 0T));
    end;

    procedure GetTimeValue(Object: JsonObject; KeyName: Text; DefaultValue: Time) ReturnTime: Time
    var
        TypeHelper: Codeunit "Type Helper";
        JsonVal: JsonValue;
        TimeAsVariant: Variant;
        DummyDT: DateTime;
    begin
        DummyDT := 0DT;
        if GetValue(Object, KeyName, JsonVal) then begin
            TimeAsVariant := DummyDT;
            if not TypeHelper.Evaluate(TimeAsVariant, JsonVal.AsText(), '', '') then
                if Evaluate(ReturnTime, JsonVal.AsText()) then
                    exit
                else
                    Error(CouldNotCastErr, JsonVal.AsText(), Format(IDYMField.Type::Time));
            if TimeAsVariant.IsDateTime then begin
                DummyDT := TimeAsVariant;
                DummyDT := ConvertUTCDateTimeToDT(DummyDT);
                exit(DT2Time(DummyDT));
            end;
        end else
            exit(DefaultValue);
    end;

    procedure GetToken(Object: JsonObject; KeyName: Text): JsonToken
    var
        Token: JsonToken;
    begin
        Object.Get(KeyName, Token);
        exit(Token);
    end;

    procedure ImportJsonObjectFromFile() ImportedJsonObject: JsonObject
    var
        Filename: Text;
        FileInStream: InStream;
        JSONAsText: Text;
        DialogTextLbl: Label 'Select a Json file to import';
        JsonExtLbl: Label 'JSON Files (*.JSON)|*.json', Locked = true;
    begin
        Filename := '';
        if not UploadIntoStream(DialogTextLbl, '', JsonExtLbl, FileName, FileInStream) then
            exit;

        FileInStream.Read(JSONAsText);
        ImportedJsonObject.ReadFrom(JSONAsText);
    end;

    procedure IsArray(InputAsVariant: variant; KeyName: Text): Boolean
    var
        ValueToken: JsonToken;
        Object: JsonObject;
        Token: JsonToken;
    begin
        if InputAsVariant.IsJsonObject() then begin
            Object := InputAsVariant;
            if Object.Get(KeyName, Token) then
                exit(Token.IsArray());
        end;
        if InputAsVariant.IsJsonToken() then begin
            Token := InputAsVariant;
            if Token.AsObject().Get(KeyName, ValueToken) then
                exit(ValueToken.IsArray());
        end;
    end;

    procedure IsObject(InputAsVariant: variant; KeyName: Text): Boolean
    var
        ValueToken: JsonToken;
        Object: JsonObject;
        Token: JsonToken;
    begin
        if InputAsVariant.IsJsonObject() then begin
            Object := InputAsVariant;
            if Object.Get(KeyName, Token) then
                exit(Token.IsObject());
        end;
        if InputAsVariant.IsJsonToken() then begin
            Token := InputAsVariant;
            if Token.AsObject().Get(KeyName, ValueToken) then
                exit(ValueToken.IsObject());
        end;
    end;

    [TryFunction]
    procedure TryGetJsonValuePath(InputToken: JsonToken; Path: Text; var ReturnJsonValue: JsonValue)
    var
        JToken: JsonToken;
    begin
        if not InputToken.SelectToken(Path, JToken) then
            exit;
        if not JToken.IsValue() then
            exit;
        ReturnJsonValue := JToken.AsValue();
    end;

    procedure GetJsonValueByPath(InputToken: JsonToken; Path: Text): JsonValue
    var
        JToken: JsonToken;
        JsonTokenNotFoundErr: Label 'Could not find JsonToken %1', comment = '%1 refers to the value for the JSONToken.';
        JsonTokenIsNotValueErr: Label 'The Json object is malformed. Could not find Json value %1', comment = '%1 refers to the invalid value for the JSONToken';
    begin
        if not InputToken.SelectToken(Path, JToken) then
            Error(JsonTokenNotFoundErr, Path);

        if not JToken.IsValue() then
            Error(JsonTokenIsNotValueErr, Path);

        exit(JToken.AsValue());
    end;

#if not BC17  
    [Obsolete('Removed Returnvalue, use GetImportedRecords() instead after calling this function', '18.0.2')]
    procedure ImportTableDataFromJsonObject(ImportJsonObject: JsonObject; TableNo: Integer; TableName: Text; AllowModify: Boolean): RecordId;
    begin
        ImportJsonObjectToTableData(ImportJsonObject, TableNo, TableName, AllowModify);
    end;
#endif

    procedure ImportJsonObjectToTableData(ImportJsonObject: JsonObject; TableNo: Integer; TableName: Text; AllowModify: Boolean)
    var
        ImportRecordJsonObject: JsonObject;
        ImportTableJsonArray: JsonArray;
        ImportTableJsonToken: JsonToken;
    begin
        Clear(HandledRecords);
        if not ImportJsonObject.Contains(TableName) then
            exit;
        if IsArray(ImportJsonObject, TableName) then begin
            ImportTableJsonArray := GetArray(ImportJsonObject, TableName);
            foreach ImportTableJsonToken in ImportTableJsonArray do
                ImportJsonObjectToRecord(ImportTableJsonToken.AsObject(), TableNo, AllowModify);
        end else begin
            ImportRecordJsonObject := GetObject(ImportJsonObject, TableName);
            ImportJsonObjectToRecord(ImportRecordJsonObject, TableNo, AllowModify);
        end;
    end;

#if not BC17
    [Obsolete('Removed Returnvalue, use GetImportedRecords() instead after calling this function', '18.0.2')]
    procedure ImportRecordFromJsonObject(ImportJsonObject: JsonObject; TableNo: Integer; AllowModify: Boolean): RecordId
    begin
        ImportJsonObjectToRecord(ImportJsonObject, TableNo, AllowModify);
    end;
#endif

    procedure ImportJsonObjectToRecord(ImportJsonObject: JsonObject; TableNo: Integer; AllowModify: Boolean)
    var
        ImportRecordRef: RecordRef;
    begin
        ImportRecordRef.Open(TableNo);
        JsonObjectToRecordRef(ImportJsonObject, ImportRecordRef);
        if not ImportRecordRef.Insert(true) then
            if AllowModify then
                ImportRecordRef.Modify(true);
        if not HandledRecords.Contains(ImportRecordRef.RecordId) then
            HandledRecords.Add(ImportRecordRef.RecordId);
    end;

    procedure GetImportedRecords(var ImportedRecords: List of [RecordId])
    begin
        ImportedRecords := HandledRecords;
    end;

    procedure JsonObjectToRecordRef(ImportJsonObject: JsonObject; var ImportRecordRef: RecordRef)
    var
        TargetFields: Record Field;
        ImportFieldRef: FieldRef;
        ValueAsVariant: Variant;
        FieldsToImportList: List of [Text];
        PropertyToImport: Text;
        FieldNoToImport: Integer;
        ObsoleteFields: List of [Integer];
        UnsupportedFieldTypeErr: Label 'Unsupported field type %1.', Comment = '%1 = Field Type';
    begin
        ImportRecordRef.Init();

        Clear(ObsoleteFields);
        TargetFields.SetRange(TableNo, ImportRecordRef.Number());
        TargetFields.SetFilter(ObsoleteState, '%1|%2', TargetFields.ObsoleteState::Pending, TargetFields.ObsoleteState::Removed);
        if TargetFields.FindSet() then
            repeat
                ObsoleteFields.Add(TargetFields."No.");
            until TargetFields.Next() = 0;

        FieldsToImportList := ImportJsonObject.Keys();
        foreach PropertyToImport in FieldsToImportList do
            if Evaluate(FieldNoToImport, PropertyToImport) and not (ObsoleteFields.Contains(FieldNoToImport)) then
                if ImportRecordRef.FieldExist(FieldNoToImport) then begin
                    ImportFieldRef := ImportRecordRef.Field(FieldNoToImport);
                    case ImportFieldRef.Type() of
                        ImportFieldRef.Type() ::Boolean:
                            ValueAsVariant := GetBooleanValue(ImportJsonObject, PropertyToImport);
                        ImportFieldRef.Type() ::Code:
                            ValueAsVariant := GetCodeValue(ImportJsonObject, PropertyToImport);
                        ImportFieldRef.Type() ::Date:
                            ValueAsVariant := GetDateValue(ImportJsonObject, PropertyToImport);
                        ImportFieldRef.Type() ::DateTime:
                            ValueAsVariant := GetDateTimeValue(ImportJsonObject, PropertyToImport);
                        ImportFieldRef.Type() ::Decimal:
                            ValueAsVariant := GetDecimalValue(ImportJsonObject, PropertyToImport);
                        ImportFieldRef.Type() ::Guid:
                            ValueAsVariant := GetGuidValue(ImportJsonObject, PropertyToImport);
                        ImportFieldRef.Type() ::Text:
                            ValueAsVariant := GetTextValue(ImportJsonObject, PropertyToImport);
                        ImportFieldRef.Type() ::Integer,
                        ImportFieldRef.Type() ::Option:
                            ValueAsVariant := GetIntegerValue(ImportJsonObject, PropertyToImport);
                        ImportFieldRef.Type() ::Time:
                            ValueAsVariant := GetTimeValue(ImportJsonObject, PropertyToImport);
                        else
                            Error(UnsupportedFieldTypeErr, ImportFieldRef.Type());
                    end;
                    ImportFieldRef.Value(ValueAsVariant);
                end;
    end;

    procedure TableDataToJsonObject(RecordAsVariant: Variant; var ExportObject: JsonObject)
    var
        ToExportRecordRef: RecordRef;
    begin
        case true of
            RecordAsVariant.IsRecord():
                ToExportRecordRef.GetTable(RecordAsVariant);
            RecordAsVariant.IsRecordRef():
                ToExportRecordRef := RecordAsVariant;
            else
                Error(NoRecordErr);
        end;
        TableDataToJsonObject(RecordAsVariant, ToExportRecordRef.Name.Contains('Setup'), ExportObject);
    end;

    procedure TableDataToJsonObject(RecordAsVariant: Variant; OnlyExportCurrentRecord: Boolean; var ExportObject: JsonObject)
    var
        ToExportRecordRef: RecordRef;
        ExportRecordJsonObject: JsonObject;
        ExportTableJsonArray: JsonArray;
    begin
        case true of
            RecordAsVariant.IsRecord():
                ToExportRecordRef.GetTable(RecordAsVariant);
            RecordAsVariant.IsRecordRef():
                ToExportRecordRef := RecordAsVariant;
            else
                Error(NoRecordErr);
        end;

        if ToExportRecordRef.IsEmpty() then
            exit;

        if OnlyExportCurrentRecord then begin
            RecordToJsonObject(ToExportRecordRef, ExportRecordJsonObject);
            Add(ExportObject, ToExportRecordRef.Name(), ExportRecordJsonObject);
        end else begin
            ToExportRecordRef.FindSet();
            repeat
                RecordToJsonObject(ToExportRecordRef, ExportRecordJsonObject);
                ExportTableJsonArray.Add(ExportRecordJsonObject);
            until ToExportRecordRef.Next() = 0;
            Add(ExportObject, ToExportRecordRef.Name(), ExportTableJsonArray);
        end;
    end;

    procedure RecordToJsonObject(ExportRecordRef: RecordRef; var ExportObject: JsonObject)
    var
        FieldsToExport: Record "Field";
        JSONHelper: Codeunit "IDYM JSON Helper";
        ExportFieldRef: FieldRef;
        FieldNosToExclude: List of [Integer];
    begin
        Clear(ExportObject);
        FieldNosToExclude.AddRange(2000000000, 2000000001, 2000000002, 2000000003, 2000000004);
        FieldsToExport.SetRange(TableNo, ExportRecordRef.Number());
        FieldsToExport.SetRange(ObsoleteState, FieldsToExport.ObsoleteState::No);
        FieldsToExport.SetRange(Class, FieldsToExport.Class::Normal);
        FieldsToExport.SetFilter(FieldName, '<>*STID');
        if FieldsToExport.FindSet() then
            repeat
                if not FieldNosToExclude.Contains(FieldsToExport."No.") then begin
                    ExportFieldRef := ExportRecordRef.Field(FieldsToExport."No.");
                    JSONHelper.AddVariantValue(ExportObject, Format(FieldsToExport."No."), ExportFieldRef.Value());
                end;
            until FieldsToExport.Next() = 0;
    end;

    local procedure ConvertUTCDateTimeToDT(InputDTInUTC: DateTime) ReturnDT: DateTime
    var
        TimeInUTC: Text;
        TimeZoneDiffDuration: Duration;
        TimeZoneTime: Time;
        UTCTime: Time;
    begin
        // all type helper functions seem to neglect summertime.
        // E.g. TypeHelper.GetUserTimezoneOffset() returns one 1 hour when it should be 2 hours
        // therefore this uses the difference between Format(DT, 0, 9) which is in UTC and Format(T, 0, 9) which is in the user Time Zone

        TimeInUTC := Format(InputDTInUTC, 0, 9);
        TimeInUTC := CopyStr(TimeInUTC, StrPos(TimeInUTC, 'T') + 1);
        TimeInUTC := DelChr(TimeInUTC, '>', 'Z');
        Evaluate(UTCTime, TimeInUTC);

        TimeZoneTime := DT2Time(InputDTInUTC);
        TimeZoneDiffDuration := TimeZoneTime - UTCTime;
        if TimeZoneDiffDuration < 0 then //next day
            TimeZoneDiffDuration := 86400000 + TimeZoneDiffDuration; //86400000 = 24 hours
        ReturnDT := InputDTInUTC + TimeZoneDiffDuration;
    end;

    var
        IDYMField: Record Field;
        HandledRecords: List of [RecordId];
        CouldNotCastErr: Label 'Could not cast Value %1 to %2.', Comment = '%1=The value.%2=The type to cast to.';
        NoRecordErr: Label 'The RecordAsVariant parameter does not contain a record.';
}
