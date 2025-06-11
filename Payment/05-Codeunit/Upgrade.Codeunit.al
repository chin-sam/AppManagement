codeunit 11155298 "IDYM Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        PopulateAppName();
    end;

    internal procedure PopulateAppName()
    var
        AppLicenseKey: Record "IDYM App License Key";
        AppInfo: ModuleInfo;
    begin
        if UpgradeTag.HasUpgradeTag(IDYMUpgradeTagDefinitions.PopulateAppNameTag()) then
            exit;
        if AppLicenseKey.FindSet(true) then
            repeat
                if AppLicenseKey."App Name" = '' then
                    if NavApp.GetModuleInfo(AppLicenseKey."App Id", AppInfo) then begin
                        AppLicenseKey."App Name" := CopyStr(AppInfo.Name, 1, MaxStrLen(AppLicenseKey."App Name"));
                        AppLicenseKey.Modify();
                    end;
            until AppLicenseKey.Next() = 0;
        UpgradeTag.SetUpgradeTag(IDYMUpgradeTagDefinitions.PopulateAppNameTag());
    end;

    var
        UpgradeTag: Codeunit "Upgrade Tag";
        IDYMUpgradeTagDefinitions: Codeunit "IDYM Upgrade Tag Definitions";
}