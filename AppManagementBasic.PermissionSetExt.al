#if not BC17
permissionsetextension 11155289 "IDYM App Management Basic" extends "D365 BASIC"
{
    Permissions =
        tabledata "IDYM App License Key" = r,
        tabledata "IDYM App Version Info" = r,
        tabledata "IDYM Endpoint" = rimd,
        tabledata "IDYM Payment Setup" = rimd;
}
#endif