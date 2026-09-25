; The Literia installer for Windows. tool/package_windows_release.ps1 builds
; the app and compiles this script, passing AppVersion, BuildDir (the Flutter
; release folder), OutputDir and OutputBaseFilename.
;
; Installing over an older copy updates it: the installer closes the running
; app first, tray included, then replaces its files. The books stay where they
; are, in the user's AppData, and uninstalling leaves them too.

#ifndef AppVersion
  #error Pass the version with /DAppVersion=1.2.3
#endif
#ifndef BuildDir
  #error Pass the Flutter release folder with /DBuildDir=...
#endif
#ifndef OutputDir
  #define OutputDir "."
#endif
#ifndef OutputBaseFilename
  #define OutputBaseFilename "literia-setup"
#endif

#define AppName "Литерия"
#define AppExeName "literia.exe"
; Must match kLiteriaWindowClass, LiteriaQuitMessage() and the single
; instance mutex in windows/runner.
#define AppWindowClass "LITERIA_WINDOW"
#define AppQuitMessage "LiteriaQuit"
#define AppMutex "Local\LiteriaSingleInstance"

[Setup]
; Never change the id: an update finds the installed copy by it.
AppId={{F693B6F5-A885-4453-8E5D-7A45C79E8DF0}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=Literia
VersionInfoVersion={#AppVersion}
VersionInfoProductName={#AppName}
; Installs for the current user, without asking for administrator rights.
PrivilegesRequired=lowest
DefaultDirName={localappdata}\Programs\Literia
DisableProgramGroupPage=yes
UsePreviousAppDir=yes
UsePreviousTasks=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
; The [Code] below closes the app itself, tray and all, without asking.
CloseApplications=no
RestartApplications=no
LanguageDetectionMethod=uilanguage
ShowLanguageDialog=no
WizardStyle=modern
WizardImageFile=wizard-large-164x314.bmp,wizard-large-328x628.bmp
WizardSmallImageFile=wizard-small-55.bmp,wizard-small-83.bmp,wizard-small-110.bmp
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
OutputDir={#OutputDir}
OutputBaseFilename={#OutputBaseFilename}
Compression=lzma2/ultra64
SolidCompression=yes

[Languages]
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
ru.TrayGroup=Трей:
en.TrayGroup=Tray:
ru.StartWithWindows=Запускать вместе с Windows (значок в трее, окно откроется по клику)
en.StartWithWindows=Start with Windows (an icon in the tray; a click opens the window)

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "startup"; Description: "{cm:StartWithWindows}"; GroupDescription: "{cm:TrayGroup}"

[InstallDelete]
; The Flutter assets are replaced whole, so none from an older version linger.
Type: filesandordirs; Name: "{app}\data"
; An update where the desktop shortcut is no longer wanted removes it.
Type: files; Name: "{autodesktop}\{#AppName}.lnk"; Tasks: not desktopicon

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Registry]
; Started with Windows, the app only puts its icon in the tray.
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "Literia"; ValueData: """{app}\{#AppExeName}"" --tray"; Flags: uninsdeletevalue; Tasks: startup
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: none; ValueName: "Literia"; Flags: deletevalue; Tasks: not startup

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

[Code]
function RegisterLiteriaMessage(Name: String): Longint;
  external 'RegisterWindowMessageW@user32.dll stdcall';

// Asks a running Literia to save and quit, as "Quit" in its tray menu does,
// and waits for it. Whatever is left then, an older copy that does not know
// the request or one that hangs, is ended by force.
procedure CloseLiteria();
var
  Window: HWND;
  Waited, ResultCode: Integer;
begin
  if CheckForMutexes('{#AppMutex}') then
  begin
    Window := FindWindowByClassName('{#AppWindowClass}');
    if Window <> 0 then
      PostMessage(Window, RegisterLiteriaMessage('{#AppQuitMessage}'), 0, 0);
    Waited := 0;
    while CheckForMutexes('{#AppMutex}') and (Waited < 10000) do
    begin
      Sleep(250);
      Waited := Waited + 250;
    end;
  end;
  Exec(ExpandConstant('{sys}\taskkill.exe'), '/F /T /IM {#AppExeName}', '',
    SW_HIDE, ewWaitUntilTerminated, ResultCode);
  // taskkill returns before Windows releases the files of the processes.
  if ResultCode = 0 then
    Sleep(1000);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  CloseLiteria();
  Result := '';
end;

function InitializeUninstall(): Boolean;
begin
  CloseLiteria();
  Result := True;
end;
