page 11155295 "IDYM App Contact Card"
{
    Caption = 'Contact Information';
    PageType = NavigatePage;
    SourceTable = "Company Information";
    SourceTableTemporary = true;
    UsageCategory = None;

    Permissions = tabledata User = R;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Contact Info', Locked = true;
                ShowCaption = false;

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Company Name';
                    ToolTip = 'Specifies the company''s name and corporate form. For example, Inc. or Ltd.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Country Code';
                    ToolTip = 'Specifies the country/region of the company.';
                }
                field(ContactFirstName; ContactFirstName)
                {
                    ApplicationArea = All;
                    Caption = 'First Name';
                    ToolTip = 'Specifies the first name of the contact person in your company.';
                }
                field(ContactLastName; ContactLastName)
                {
                    ApplicationArea = All;
                    Caption = 'Last Name';
                    ToolTip = 'Specifies the last name of the contact person in your company.';
                }
                field(ContactJobTitle; ContactJobTitle)
                {
                    ApplicationArea = All;
                    Caption = 'Job Title';
                    ToolTip = 'Specifies the job title of the contact person in your company.';
                }
                field("E-Mail"; ContactEmailAddress)
                {
                    ApplicationArea = All;
                    Caption = 'E-Mail';
                    ToolTip = 'Specifies the company''s email address.';
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the company''s telephone number.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionOk)
            {
                ApplicationArea = All;
                Caption = 'OK';
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    IsActionOk := true;
                    CurrPage.Close();
                end;
            }
            action(ActionCancel)
            {
                ApplicationArea = All;
                Caption = 'Cancel';
                Image = Cancel;
                InFooterBar = true;

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    internal procedure InitContactInformation(UseCompanyInformation: Boolean)
    var
        CompanyInformation: Record "Company Information";
    begin
        Clear(ContactFirstName);
        Clear(ContactLastName);
        Clear(ContactEmailAddress);
        Clear(ContactJobTitle);
        Rec.Init();
        if UseCompanyInformation and CompanyInformation.Get() then
            Rec.TransferFields(CompanyInformation);
        Rec.Insert();
        SetContactSource();
        SplitContactName();
    end;

    local procedure SetContactSource()
    var
        User: Record User;
    begin
        if not User.Get(UserSecurityId()) then
            exit;
        if User."Full Name" <> '' then
            ContactFullName := User."Full Name"
        else
            ContactFullName := Rec."Contact Person";
        if User."Contact Email" <> '' then
            ContactEmailAddress := User."Contact Email"
        else
            ContactEmailAddress := Rec."E-Mail";
    end;

    local procedure SplitContactName()
    var
        FirstSpaceIndex: Integer;
    begin
        FirstSpaceIndex := ContactFullName.Trim().IndexOf(' ');
        if FirstSpaceIndex = 0 then begin
            ContactFirstName := ContactFullName;
            exit;
        end;
        ContactFirstName := CopyStr(ContactFullName, 1, FirstSpaceIndex - 1);
        ContactLastName := CopyStr(ContactFullName, FirstSpaceIndex + 1);
    end;

    internal procedure GetContactInformation(var ContactObject: JsonObject)
    var
        JsonHelper: Codeunit "IDYM JSON Helper";
    begin
        JsonHelper.AddValue(ContactObject, 'company', Rec.Name);
        JsonHelper.AddValue(ContactObject, 'country', Rec."Country/Region Code");
        JsonHelper.AddValue(ContactObject, 'firstName', ContactFirstName);
        JsonHelper.AddValue(ContactObject, 'lastName', ContactLastName);
        JsonHelper.AddValue(ContactObject, 'email', ContactEmailAddress);
        JsonHelper.AddValue(ContactObject, 'phone', Rec."Phone No.");
        JsonHelper.AddValue(ContactObject, 'title', ContactJobTitle);
    end;

    internal procedure IsProcessCancelled(): Boolean
    begin
        exit(not IsActionOk);
    end;

    var
        IsActionOk: Boolean;
        ContactFullName: Text;
        ContactFirstName: Text;
        ContactLastName: Text;
        ContactJobTitle: Text;
        ContactEmailAddress: Text;
}
