; GNNscan - Inno Setup Installer Script
; Targets compiled Windows Flutter executable and bundles WebView2 runtime check.

[Setup]
AppId={{C82F6D18-7F1F-43DE-875C-B24DE7AA9D2B}
AppName=GNNcyber - NETscan
AppVersion=2.6.3
AppPublisher=BigDesigner
AppPublisherURL=https://github.com/BigDesigner/GNNscan
AppSupportURL=https://github.com/BigDesigner/GNNscan
AppUpdatesURL=https://github.com/BigDesigner/GNNscan
DefaultDirName={autopf}\GNNscan
DisableProgramGroupPage=yes
LicenseFile=README.md
OutputDir=.
OutputBaseFilename=GNNcyber_NETscan_Setup
SetupIconFile=assets\app.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\gnnscan.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on shared system files

[Icons]
Name: "{autoprograms}\GNNcyber - NETscan"; Filename: "{app}\gnnscan.exe"
Name: "{autodesktop}\GNNcyber - NETscan"; Filename: "{app}\gnnscan.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\gnnscan.exe"; Description: "{cm:LaunchProgram,GNNcyber - NETscan}"; Flags: nowait postinstall skipifsilent

[Code]
// Helper function to check if Edge WebView2 Runtime is installed
function IsWebView2Installed: Boolean;
var
  RegPath: String;
  InstalledVersion: String;
begin
  RegPath := 'SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}';
  Result := RegQueryStringValue(HKLM, RegPath, 'pv', InstalledVersion) or
            RegQueryStringValue(HKCU, RegPath, 'pv', InstalledVersion);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ResultCode: Integer;
begin
  Result := '';
  if not IsWebView2Installed then
  begin
    WizardForm.StatusLabel.Caption := 'Downloading Microsoft Edge WebView2 Runtime...';
    try
      DownloadTemporaryFile('https://go.microsoft.com/fwlink/p/?LinkId=2124703', 'MicrosoftEdgeWebview2Setup.exe', '', nil);
      WizardForm.StatusLabel.Caption := 'Installing Microsoft Edge WebView2 Runtime (silent)...';
      if not Exec(ExpandConstant('{tmp}\MicrosoftEdgeWebview2Setup.exe'), '/silent /install', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
      begin
        MsgBox('Microsoft Edge WebView2 Runtime installation failed. You can install it manually from Microsoft website.', mbInformation, MB_OK);
      end;
    except
      MsgBox('Failed to download WebView2 Runtime automatically. You can install it manually.', mbInformation, MB_OK);
    end;
  end;
end;
