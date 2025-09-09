#define MyAppName "Counter-Strike Condition Zero Cooperative Patch"
#define MyAppVersion "2.9.4"
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
Source: "czero\addons\*"; DestDir: "{app}\czero\addons"; Excludes: "cmdaccess.ini,logs,*.so,*.pmx,*.prc,*.vis"; Flags: ignoreversion recursesubdirs
Source: "czero\BotCampaignProfile.db"; DestDir: "{app}\czero"; Flags: ignoreversion
Source: "czero\career.cfg"; DestDir: "{app}\czero"; Flags: ignoreversion
Source: "czero\coop.cfg"; DestDir: "{app}\czero"; Flags: ignoreversion
Source: "czero\dlls\mp.dll"; DestDir: "{app}\czero\dlls"; Flags: ignoreversion
Source: "czero\game.cfg"; DestDir: "{app}\czero"; Flags: ignoreversion; Check: Is25Upd;
Source: "czero\game_legacy.cfg"; DestDir: "{app}\czero"; DestName: "game.cfg"; Flags: ignoreversion; Check: IsPre25;
Source: "czero\game_init.cfg"; DestDir: "{app}\czero"; Flags: ignoreversion
Source: "czero\liblist.gam"; DestDir: "{app}\czero"; Flags: ignoreversion
Source: "czero\restart.html"; DestDir: "{app}\czero"; Flags: ignoreversion
Source: "dlls\hw.dll"; DestDir: "{app}"; Flags: ignoreversion; Check: Is25Upd;
Source: "dlls\hw_legacy.dll"; DestDir: "{app}"; DestName: "hw.dll"; Flags: ignoreversion; Check: IsPre25;
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Code]    
const
  FullDescText =
    'Default version';
  PartDescText =
    'Pre-25th Anniversary build';

var
  DefaultRadioButton: TNewRadioButton;
  LegacyRadioButton: TNewRadioButton;

procedure InitializeWizard;
var
  CustomPage: TWizardPage;
  DefaultDescLabel: TLabel;
  LegacyDescLabel: TLabel;
begin
  CustomPage := CreateCustomPage(wpWelcome, 'Select your Counter-Strike: Condition Zero version:', '');
  DefaultRadioButton := TNewRadioButton.Create(WizardForm);
  DefaultRadioButton.Parent := CustomPage.Surface;
  DefaultRadioButton.Checked := True;
  DefaultRadioButton.Top := 16;
  DefaultRadioButton.Width := CustomPage.SurfaceWidth;
  DefaultRadioButton.Font.Style := [fsBold];
  DefaultRadioButton.Font.Size := 9;
  DefaultRadioButton.Caption := 'Steam'
  DefaultDescLabel := TLabel.Create(WizardForm);
  DefaultDescLabel.Parent := CustomPage.Surface;
  DefaultDescLabel.Left := 8;
  DefaultDescLabel.Top := DefaultRadioButton.Top + DefaultRadioButton.Height + 8;
  DefaultDescLabel.Width := CustomPage.SurfaceWidth; 
  DefaultDescLabel.Height := 40;
  DefaultDescLabel.AutoSize := False;
  DefaultDescLabel.Wordwrap := True;
  DefaultDescLabel.Caption := FullDescText;
  LegacyRadioButton := TNewRadioButton.Create(WizardForm);
  LegacyRadioButton.Parent := CustomPage.Surface;
  LegacyRadioButton.Top := DefaultDescLabel.Top + DefaultDescLabel.Height + 16;
  LegacyRadioButton.Width := CustomPage.SurfaceWidth;
  LegacyRadioButton.Font.Style := [fsBold];
  LegacyRadioButton.Font.Size := 9;
  LegacyRadioButton.Caption := 'Steam Legacy'
  LegacyDescLabel := TLabel.Create(WizardForm);
  LegacyDescLabel.Parent := CustomPage.Surface;
  LegacyDescLabel.Left := 8;
  LegacyDescLabel.Top := LegacyRadioButton.Top + LegacyRadioButton.Height + 8;
  LegacyDescLabel.Width := CustomPage.SurfaceWidth;
  LegacyDescLabel.Height := 40;
  LegacyDescLabel.AutoSize := False;
  LegacyDescLabel.Wordwrap := True;
  LegacyDescLabel.Caption := PartDescText;
end;

function GetSteamDir(Default: String): String;
var
  sPath: String;
begin
  sPath := 'C:\Program Files (x86)\Steam\steamapps\common\Half-Life';
  RegQueryStringValue(HKCU, 'Software\Valve\Steam','ModInstallPath', sPath);
  Result := sPath;
end;

function Is25Upd: Boolean;
begin
  Result := DefaultRadioButton.Checked;
end;

function IsPre25: Boolean;
begin
  Result := LegacyRadioButton.Checked;
end;