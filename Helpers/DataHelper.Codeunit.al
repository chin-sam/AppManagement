codeunit 11155293 "IDYM Data Helper"
{
    procedure TextToInteger(InputText: Text) ReturnInt: Integer
    begin
        exit(TextToInteger(InputText, false));
    end;

    procedure TextToInteger(InputText: Text; GiveError: Boolean) ReturnInt: Integer
    var
        TypeHelper: Codeunit "Type Helper";
        IntAsVariant: Variant;
    begin
        IntAsVariant := ReturnInt;
        if GiveError and not TypeHelper.Evaluate(IntAsVariant, InputText, '', '') then
            Error(CouldNotCastErr, InputText, Format(IDYMField.Type::Integer));
        if IntAsVariant.IsInteger then
            ReturnInt := IntAsVariant;
    end;

    procedure TextToDecimal(InputText: Text) ReturnDecimal: Decimal
    begin
        exit(TextToDecimal(InputText, false));
    end;

    procedure TextToDecimal(InputText: Text; GiveError: Boolean) ReturnDecimal: Decimal
    var
        TypeHelper: Codeunit "Type Helper";
        DecimalAsVariant: Variant;
    begin
        DecimalAsVariant := ReturnDecimal;
        if GiveError and not TypeHelper.Evaluate(DecimalAsVariant, InputText, '', '') then
            Error(CouldNotCastErr, InputText, Format(IDYMField.Type::Decimal));
        if DecimalAsVariant.IsDecimal then
            ReturnDecimal := DecimalAsVariant;
    end;

    procedure TextToDateTime(InputText: Text) ReturnDT: DateTime
    begin
        exit(TextToDateTime(InputText, false));
    end;

    procedure TextToDateTime(InputText: Text; GiveError: Boolean) ReturnDT: DateTime
    var
        TypeHelper: Codeunit "Type Helper";
        DateTimeAsVariant: Variant;
    begin
        DateTimeAsVariant := ReturnDT;
        if GiveError and not TypeHelper.Evaluate(DateTimeAsVariant, InputText, '', '') then
            Error(CouldNotCastErr, InputText, Format(IDYMField.Type::DateTime));
        if DateTimeAsVariant.IsDateTime then
            ReturnDT := DateTimeAsVariant;
    end;

    procedure TextToDate(InputText: Text) ReturnDate: Date
    begin
        exit(TextToDate(InputText, false));
    end;

    procedure TextToDate(InputText: Text; GiveError: Boolean) ReturnDate: Date
    var
        TypeHelper: Codeunit "Type Helper";
        DateAsVariant: Variant;
    begin
        DateAsVariant := ReturnDate;
        if GiveError and not TypeHelper.Evaluate(DateAsVariant, InputText, '', '') then
            Error(CouldNotCastErr, InputText, Format(IDYMField.Type::Date));
        if DateAsVariant.IsDate then
            ReturnDate := DateAsVariant;
    end;

    procedure TextToTime(InputText: Text) ReturnTime: Time
    begin
        exit(TextToTime(InputText, false));
    end;

    procedure TextToTime(InputText: Text; GiveError: Boolean) ReturnTime: Time
    var
        TypeHelper: Codeunit "Type Helper";
        TimeAsVariant: Variant;
        DummyDT: DateTime;
    begin
        DummyDT := 0DT;
        TimeAsVariant := DummyDT;
        if GiveError and not TypeHelper.Evaluate(TimeAsVariant, InputText, '', '') then
            Error(CouldNotCastErr, InputText, Format(IDYMField.Type::Time));
        if TimeAsVariant.IsDateTime then
            ReturnTime := Variant2Time(TimeAsVariant);
    end;

    var
        IDYMField: Record Field;
        CouldNotCastErr: Label 'Could not cast Value %1 to %2.', Comment = '%1=The value.%2=The type to cast to.';
}
