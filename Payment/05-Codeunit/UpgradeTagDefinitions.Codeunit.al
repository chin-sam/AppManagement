codeunit 11155301 "IDYM Upgrade Tag Definitions"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(PopulateAppNameTag());
    end;

    procedure PopulateAppNameTag(): Code[250]
    begin
        exit('IDYM-0000-PopulateAppNameTag-20231128');
    end;
}