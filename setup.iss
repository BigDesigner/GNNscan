; GNNscan - Inno Setup Installer Script
; Targets compiled Windows Flutter executable and bundles WebView2 runtime check.

[Setup]
AppId={{C82F6D18-7F1F-43DE-875C-B24DE7AA9D2B}
AppName=GNNscan
AppVersion=2.4.0
AppPublisher=BigDesigner
AppPublisherURL=https://github.com/BigDesigner/GNNscan
AppSupportURL=https://github.com/BigDesigner/GNNscan
AppUpdatesURL=https://github.com/BigDesigner/GNNscan
DefaultDirName={autopf}\GNNscan
DisableProgramGroupPage=yes
LicenseFile=README.md
OutputDir=.
OutputBaseFilename=GNNscan_Setup
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
Name: "{autoprograms}\GNNscan"; Filename: "{app}\gnnscan.exe"
Name: "{autodesktop}\GNNscan"; Filename: "{app}\gnnscan.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\gnnscan.exe"; Description: "{cm:LaunchProgram,GNNscan}"; Flags: nowait postinstall skipifsilent

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

function InitializeSetup: Boolean;
var
  ErrorCode: Integer;
begin
  Result := True;
  if not IsWebView2Installed then
  begin
    if MsgBox('GNNscan requires Microsoft Edge WebView2 Runtime to render the dashboard interface. It does not appear to be installed.' + #13#10#13#10 +
              'Would you like to download and install it now?', mbConfirmation, MB_YESNO) = IDYES then
    begin
      ShellExec('open', 'https://developer.microsoft.com/en-us/microsoft-edge/webview2/', '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
    end;
  end;
end;
