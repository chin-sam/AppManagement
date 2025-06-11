// table 11155293 "IDYM App Setting"
// {
//     DataClassification = ToBeClassified;

//     fields
//     {
//         field(1; "App Id"; Guid)
//         {
//             DataClassification = SystemMetadata;
//             Caption = 'App ID';
//             Editable = false;
//             NotBlank = true;
//         }
//         field(2; "App Name"; Text[100])
//         {
//             Caption = 'App Name';
//             DataClassification = SystemMetadata;
//             Editable = false;
//         }
//         field(10; "Retention Period"; DateFormula)
//         {
//             Caption = 'Retention Period';
//             DataClassification = CustomerContent;
//             InitValue = '<-7D>';
//         }
//     }

//     keys
//     {
//         key(Key1; "App Id")
//         {
//             Clustered = true;
//         }
//     }
// }