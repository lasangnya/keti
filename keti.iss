; ── keti Windows installer ──────────────────────────────────────────
; Save this file as keti.iss in the PROJECT ROOT:
;   C:\Users\lasan\Desktop\keti\keti\keti.iss
; Build the app first, then compile this script:
;   flutter build windows --release
;   & "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" keti.iss

[Setup]
; A stable identity for the app. NEVER change this between versions,
; or Windows will treat new installs as a different product.
AppId={{8F3A2C91-4D6E-4B27-9C1A-0E5F7B2D3A84}
AppName=keti
AppVersion=1.0.0
AppVerName=keti 1.0.0
AppPublisher=app.keti
DefaultDirName={localappdata}\Programs\keti
DefaultGroupName=keti
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=installer\output
OutputBaseFilename=keti-setup
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\keti.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Everything Flutter's Release folder contains — exe, engine DLLs,
; plugin DLLs, and data\flutter_assets\. All of it must be installed.
; *.pdb (debug symbols) are excluded to keep the installer small.
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Excludes: "*.pdb"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\keti"; Filename: "{app}\keti.exe"
Name: "{group}\Uninstall keti"; Filename: "{uninstallexe}"
Name: "{autodesktop}\keti"; Filename: "{app}\keti.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\keti.exe"; Description: "{cm:LaunchProgram,keti}"; Flags: nowait postinstall skipifsilent
