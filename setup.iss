; GNNcyber - NETscan - Inno Setup Installer Script
; Targets compiled Windows Flutter executable and bundles WebView2 runtime check.

#define MyAppName "GNNcyber - NETscan"
#define MyAppVersion "2.16.0"
#define MyAppPublisher "BigDesigner"
#define MyAppURL "https://github.com/BigDesigner"
#define MyAppExeName "netscan.exe"

[Setup]
AppId={{C82F6D18-7F1F-43DE-875C-B24DE7AA9D2B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL=https://github.com/BigDesigner/gnncyber-netscan
AppUpdatesURL=https://github.com/BigDesigner/gnncyber-netscan
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
LicenseFile=LICENSE
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
Source: "build\windows\x64\runner\Release\netscan.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on shared system files

[Icons]
Name: "{autoprograms}\GNNcyber - NETscan"; Filename: "{app}\netscan.exe"
Name: "{autodesktop}\GNNcyber - NETscan"; Filename: "{app}\netscan.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\netscan.exe"; Description: "{cm:LaunchProgram,GNNcyber - NETscan}"; Flags: nowait postinstall skipifsilent
; Download and install WebView2 with native Microsoft UI so user sees progress
Filename: "powershell.exe"; Parameters: "-NoProfile -Command ""Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/p/?LinkId=2124703' -OutFile '$env:TEMP\MicrosoftEdgeWebview2Setup.exe'; Start-Process -FilePath '$env:TEMP\MicrosoftEdgeWebview2Setup.exe' -Wait"""; StatusMsg: "Downloading WebView2 Runtime... (Please wait, an installer window will appear)"; Check: not IsWebView2Installed; Flags: runhidden
; Download and install Visual C++ Redistributable with passive progress UI
Filename: "powershell.exe"; Parameters: "-NoProfile -Command ""Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile '$env:TEMP\vc_redist.x64.exe'; Start-Process -FilePath '$env:TEMP\vc_redist.x64.exe' -ArgumentList '/passive /norestart' -Wait"""; StatusMsg: "Downloading Visual C++ Redistributable... (Please wait, an installer window will appear)"; Check: not IsVCRedistInstalled; Flags: runhidden

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

// Helper function to check if Visual C++ Redistributable (x64) is installed
function IsVCRedistInstalled: Boolean;
var
  RegPath: String;
  InstalledVersion: Cardinal;
begin
  RegPath := 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64';
  Result := RegQueryDWordValue(HKLM, RegPath, 'Installed', InstalledVersion) and (InstalledVersion = 1);
end;

function InitializeSetup(): Boolean;
begin
  Result := True;
end;
