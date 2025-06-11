table 11155290 "IDYM REST Parameters"
{
    DataClassification = SystemMetadata;
    Caption = 'REST Parameters';
    TableType = Temporary;

    fields
    {
        field(1; PK; Integer)
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }

        field(2; RestMethod; Option)
        {
            Caption = 'REST Method';
            OptionMembers = GET,POST,DELETE,PATCH,PUT;
            DataClassification = SystemMetadata;
        }

        field(3; Path; Text[2048])
        {
            Caption = 'Path';
            DataClassification = SystemMetadata;
        }

        field(4; Accept; Text[30])
        {
            Caption = 'Accept';
            DataClassification = SystemMetadata;
        }

        field(5; "Content-Type"; Text[100])
        {
            Caption = 'Content Type';
            DataClassification = SystemMetadata;
        }

        field(6; "Acceptance Environment"; Boolean)
        {
            Caption = 'Acceptance Environment';
            DataClassification = SystemMetadata;
        }

        // field(6; Username; text[100])
        // {
        //     Caption = 'Username';
        //     DataClassification = SystemMetadata;
        // }

        // field(7; Password; text[100])
        // {
        //     Caption = 'Password';
        //     DataClassification = SystemMetadata;
        // }

        field(8; "Status Code"; Integer)
        {
            Caption = 'Response Status Code';
            DataClassification = SystemMetadata;
        }

        field(10; "Sub Type"; Enum "IDYM Endpoint Sub Type")
        {
            Caption = 'Endpoint Sub Type';
            DataClassification = SystemMetadata;
        }

        field(11; "Sub No."; Code[50])
        {
            Caption = 'Endpoint Sub Type';
            DataClassification = SystemMetadata;
        }

        field(100; "Response Content"; Blob)
        {
            Caption = 'Response Content';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; PK)
        {
            Clustered = true;
        }
    }

    procedure GetRequestContent(var NewRequestHttpContent: HttpContent)
    begin
        NewRequestHttpContent := RequestHttpContent;
    end;

    procedure GetRequestAsJSONArray(): JsonArray
    var
        RequestObject: JsonArray;
    begin
        if not HasRequestContent() then
            exit;
        RequestObject.ReadFrom(GetRequestBodyAsString());
        exit(RequestObject);
    end;

    procedure GetRequestBodyAsString() RequestText: text
    var
        ContentInStream: InStream;
        Line: Text;
    begin
        if not HasRequestContent() then
            exit;
        RequestHttpContent.ReadAs(ContentInStream);
        ContentInStream.ReadText(RequestText);
        while not ContentInStream.EOS() do begin
            ContentInStream.ReadText(Line);
            RequestText += Line;
        end;
    end;

    procedure GetResponseContent(var ResponseHttpContent: HttpContent)
    var
        ContentInStream: InStream;
    begin
        "Response Content".CreateInStream(ContentInStream);
        ResponseHttpContent.Clear();
        ResponseHttpContent.WriteFrom(ContentInStream);
    end;

    procedure GetResponseBodyAsString() ResponseText: text
    var
        ContentInStream: InStream;
        Line: Text;
    begin
        if not HasResponseContent() then
            exit;
        "Response Content".CreateInStream(ContentInStream, TextEncoding::UTF8);
        ContentInStream.ReadText(ResponseText);
        while not ContentInStream.EOS() do begin
            ContentInStream.ReadText(Line);
            ResponseText += Line;
        end;
    end;

    procedure GetResponseBodyAsJSON(): JsonToken
    var
        ResponseObject: JsonToken;
    begin
        if not HasResponseContent() then
            exit;
        ResponseObject.ReadFrom(GetResponseBodyAsString());
        exit(ResponseObject);
    end;

    procedure GetResponseBodyAsJSONArray(): JsonArray
    var
        ResponseObject: JsonArray;
    begin
        if not HasResponseContent() then
            exit;
        ResponseObject.ReadFrom(GetResponseBodyAsString());
        exit(ResponseObject);
    end;

    procedure GetResponseBodyAsJsonObject(): JsonObject
    var
        ResponseJsonObject: JsonObject;
        ResponseInStream: InStream;
    begin
        if not HasResponseContent() then
            exit;
        "Response Content".CreateInStream(ResponseInStream);
        ResponseJsonObject.ReadFrom(ResponseInStream);
        exit(ResponseJsonObject);
    end;

    procedure GetResponseHeaders(var NewResponseHttpHeaders: HttpHeaders)
    begin
        NewResponseHttpHeaders := ResponseHttpHeaders;
    end;

    procedure HasRequestContent(): Boolean
    begin
        exit(RequestContentSet);
    end;

    procedure HasResponseContent(): Boolean
    begin
        exit("Response Content".HasValue());
    end;

    procedure SetRequestContent(RequestJsonObject: JsonObject)
    var
        SerializedRequest: Text;
    begin
        RequestJsonObject.WriteTo(SerializedRequest);
        RequestHttpContent.WriteFrom(SerializedRequest);
        RequestContentSet := true;
    end;

    procedure SetRequestContent(RequestJsonArray: JsonArray)
    var
        SerializedRequest: Text;
    begin
        RequestJsonArray.WriteTo(SerializedRequest);
        RequestHttpContent.WriteFrom(SerializedRequest);
        RequestContentSet := true;
    end;

    procedure SetRequestContent(RequestXmlDocument: XmlDocument)
    var
        SerializedRequest: Text;
    begin
        RequestXmlDocument.WriteTo(SerializedRequest);
        RequestHttpContent.WriteFrom(SerializedRequest);
        RequestContentSet := true;
    end;

    procedure SetRequestContent(NewRequestHttpContent: HttpContent)
    begin
        RequestHttpContent := NewRequestHttpContent;
        RequestContentSet := true;
    end;

    procedure SetRequestContent(RequestContentText: Text)
    begin
        RequestHttpContent.WriteFrom(RequestContentText);
        RequestContentSet := true;
    end;

    procedure SetResponseContent(HttpContent: HttpContent)
    var
        ContentInStream: InStream;
        ContentOutStream: OutStream;
    begin
        "Response Content".CreateInStream(ContentInStream);
        HttpContent.ReadAs(ContentInStream);

        "Response Content".CreateOutStream(ContentOutStream);
        CopyStream(ContentOutStream, ContentInStream);
    end;

    procedure SetResponseHeaders(var NewResponseHttpHeaders: HttpHeaders)
    begin
        ResponseHttpHeaders := NewResponseHttpHeaders;
    end;

    procedure SetHttpClientCertificate(NewCertificate: Text)
    begin
        ClientCertificate := NewCertificate;
    end;

    procedure GetHttpClientCertificate() Certificate: Text
    begin
        exit(ClientCertificate);
    end;

    procedure SetAdditionalRequestHttpHeaders(NewHttpHeaderValues: Dictionary of [Text, Text])
    begin
        // NOTE - IDYMHttpHeaders.Keys() is not available in runtime version '7.0'
        RequestHttpHeaderValues := NewHttpHeaderValues;
    end;

    procedure GetAdditionalRequestHttpHeaders(var NewHttpHeaderValues: Dictionary of [Text, Text])
    begin
        NewHttpHeaderValues := RequestHttpHeaderValues;
    end;

    trigger OnInsert()
    begin
        if not IsTemporary() then
            Error('You cannot use this table with non-temporary records.');
    end;

    var
        ClientCertificate: Text;
        RequestHttpContent: HttpContent;
        RequestContentSet: Boolean;
        ResponseHttpHeaders: HttpHeaders;
        RequestHttpHeaderValues: Dictionary of [Text, Text];
}