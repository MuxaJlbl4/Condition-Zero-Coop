#define MyAppName "Counter-Strike Condition Zero Cooperative Patch"
#define MyAppVersion "2.8.2"
#define MyAppPublisher "MuLLlaH9!"
#define MyAppURL "https://github.com/MuxaJlbl4/Condition-Zero-Coop"

[Setup]
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
VersionInfoVersion={#MyAppVersion}
DefaultDirName={code:GetSteamDir}
DefaultGroupName={#MyAppName}
DirExistsWarning=no
DisableProgramGroupPage=yes
OutputBaseFilename=Condition-Zero-Coop-{#MyAppVersion}
Compression=lzma
SolidCompression=yes
Uninstallable=no
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "czero\addons\*"; DestDir: "{app}\czero\addons"; Excludes: "cmdaccess.ini,logs,*.so,*.bat,*.pmx,*.prc,*.vis"; Flags: ignoreversion recursesubdirs
Source: "czero\BotCampaignProfile.db"; DestDir: "{app}\czero"; Flags: ignoreversion
Source: "czero\career.cfg"; DestDir: "{app}\czero"; Flags: ignoreversion
Source: "czero\coop.cfg"; DestDir: "{app}\czero"; Flags: ignoreversion
Source: "czero\dlls\mp.dll"; DestDir: "{app}\czero\dlls"; Flags: ignoreversion
Source: "czero\liblist.gam"; DestDir: "{app}\czero"; Flags: ignoreversion
Source: "czero\restart.html"; DestDir: "{app}\czero"; Flags: ignoreversion
Source: "hw.dll"; DestDir: "{app}"; Flags: ignoreversion
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Code]
function GetSteamDir(Default: String): String;
var
  sPath: String;
begin
  sPath := 'C:\Program Files (x86)\Steam\steamapps\common\Half-Life';
  RegQueryStringValue(HKCU, 'Software\Valve\Steam','ModInstallPath', sPath);
  Result := sPath;
end;
