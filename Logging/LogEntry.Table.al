table 11155292 "IDYM Log Entry"
{
    DataClassification = SystemMetadata;
    Caption = 'Application Log';

    fields
    {
        field(1; "App ID"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'App ID';
            Editable = false;
            NotBlank = true;
        }
        field(2; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Entry No.';
            Editable = false;
            AutoIncrement = true;
        }
        field(3; "Log Action"; Enum "IDYM Log Action")
        {
            DataClassification = SystemMetadata;
            Editable = false;
            Caption = 'Log Action';
        }
        field(4; "Logging Type"; Enum "IDYM Logging Type")
        {
            DataClassification = SystemMetadata;
            Editable = false;
            Caption = 'Logging Type';

            trigger OnValidate()
            begin
                if "Logging Type" = "Logging Type"::"Detailed Information" then
                    TestField("Parent Entry No.");
            end;
        }
        field(5; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            TableRelation = User;
            Editable = false;
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(6; "Execution Date/Time"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Execution Date/Time';
            Editable = false;
        }
        field(7; "Parent Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Parent Log Entry No.';
            TableRelation = "IDYM Log Entry"."Entry No." where("App ID" = field("App ID"));
            Editable = false;

            trigger OnValidate()
            var
                ParentLogEntry: Record "IDYM Log Entry";
                InvalidParentErr: Label 'The %1 cannot refer to itself.', Comment = '%1 = fieldcaption of Parent Entry No.';
            begin
                if ("Parent Entry No." <> 0) then begin
                    if ("Parent Entry No." = "Entry No.") then
                        FieldError("Parent Entry No.", StrSubstNo(InvalidParentErr, FieldCaption("Parent Entry No.")));
                    ParentLogEntry.Get("Parent Entry No.");
                    Level := ParentLogEntry.Level + 1;
                end else
                    Level := 0;
            end;
        }
        field(10; Message; Text[1024])
        {
            DataClassification = SystemMetadata;
            Caption = 'Message';
            Editable = false;
        }
        field(11; Request; Blob)
        {
            Caption = 'Request';
            DataClassification = SystemMetadata;
        }
        field(12; Response; Blob)
        {
            Caption = 'Response';
            DataClassification = SystemMetadata;
        }
        field(13; Duration; Integer)
        {
            Caption = 'Duration (in ms)';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(14; "Object Type"; Option)
        {
            Caption = 'Object Type';
            DataClassification = SystemMetadata;
            OptionMembers = "TableData","Table",,"Report",,"Codeunit","XMLport","MenuSuite","Page","Query","System","FieldNumber",,,"PageExtension","TableExtension","Enum","EnumExtension","Profile","ProfileExtension";
            OptionCaption = 'TableData,Table,,Report,,Codeunit,XMLport,MenuSuite,Page,Query,System,FieldNumber,,,PageExtension,TableExtension,Enum,EnumExtension,Profile,ProfileExtension';
            Editable = false;
        }
        field(15; "Object ID"; Integer)
        {
            Caption = 'Object ID';
            DataClassification = SystemMetadata;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = field("Object Type"));
            Editable = false;
        }
        field(50; "User Name"; Text[50])
        {
            Caption = 'User Name';
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("User Security ID")));
        }
        field(51; "App Name"; Text[100])
        {
            Caption = 'App Name';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(52; "App Version"; Text[50])
        {
            Caption = 'App Version';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(100; Level; Integer)
        {
            Caption = 'Level';
            Editable = false;
            Description = 'Determines the level in the hierarchy between parent and child log entries (treeview)';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "App ID", "Entry No.")
        {
            Clustered = true;
        }
        // key(Key1; "App ID", "Parent Entry No.")
        // {
        // }
        key(Key2; "App ID", "Execution Date/Time")
        {
        }
        key(Key3; "App ID", Level)
        {
        }
    }
}