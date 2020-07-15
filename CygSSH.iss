; CygSSH - Inno Setup installer script

#include AddBackslash(SourcePath) + "includes.iss"

[Setup]
AppId={{#AppGUID}
AllowNoIcons=yes
AppName={#AppName}
AppPublisher={#SetupAuthor}
AppVersion={#AppFullVersion}
ArchitecturesInstallIn64BitMode=x64
ChangesEnvironment=yes
CloseApplications=yes
CloseApplicationsFilter=*.chm,*.pdf,*.ps1
Compression=lzma2/ultra
DefaultDirName={autopf}\{#InstallDirName}
DefaultGroupName={#AppName}
DisableWelcomePage=no
MinVersion=6
OutputBaseFilename={#SetupName}_{#SetupVersion}
OutputDir=.
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=commandline
RestartApplications=yes
SetupIconFile={#IconFilename}
SetupMutex={#SetupName}
SolidCompression=yes
UninstallDisplayIcon={app}\{#IconFilename}
UsePreviousTasks=yes
VersionInfoCompany={#SetupCompany}
VersionInfoProductVersion={#AppFullVersion}
VersionInfoVersion={#SetupVersion}
WizardImageFile=OpenSSH-164x314.bmp
WizardSmallImageFile=OpenSSH-154x154.bmp
WizardStyle=modern

[Languages]
Name: en; MessagesFile: "compiler:Default.isl,Messages-en.isl"; LicenseFile: "License-en.rtf"; InfoBeforeFile: "Readme-en.rtf"

[Types]
Name: full;   Description: "{cm:TypesFullDescription}"; Check: IsAdminInstallMode()
Name: client; Description: "{cm:TypesClientDescription}"

[Components]
Name: server; Description: "{cm:ComponentsServerDescription}"; Types: full
Name: client; Description: "{cm:ComponentsClientDescription}"; Types: client; Flags: disablenouninstallwarning fixed

[InstallDelete]
Type: filesandordirs; Name: "{app}\usr\share\*"
Type: filesandordirs; Name: "{app}\usr\src\*"

[Files]
; cygwin x64 - /bin
Source: "bin-x64\*.dll";                     DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\cygpath.exe";               DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\cygrunsrv.exe";             DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\cygstart.exe";              DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\editrights.exe";            DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\false.exe";                 DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\getent.exe";                DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\id.exe";                    DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\less.exe";                  DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\mintty.exe";                DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\mkgroup.exe";               DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\mkpasswd.exe";              DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\mount.exe";                 DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\nano.exe";                  DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\passwd.exe";                DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\rebase.exe";                DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\rsync.exe";                 DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\scp.exe";                   DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\sftp.exe";                  DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\ssh-add.exe";               DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\ssh-agent.exe";             DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\ssh-keygen.exe";            DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\ssh-keyscan.exe";           DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\ssh-pageant.exe";           DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\ssh.exe";                   DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\touch.exe";                 DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\true.exe";                  DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\umount.exe";                DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\uname.exe";                 DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\unzip.exe";                 DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\vi.exe";                    DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\xz.exe";                    DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\zip.exe";                   DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x64\cygwin-console-helper.exe"; DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: server;        Flags: ignoreversion
Source: "bin-x64\dash.exe";                  DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: server;        Flags: ignoreversion
Source: "bin-x64\tty.exe";                   DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: server;        Flags: ignoreversion
; supplemental x64 - /bin
Source: "binsupp-x64\runposh.exe"; DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "binsupp-x64\setacl.exe";  DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "binsupp-x64\posh.exe";    DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: server;        Flags: ignoreversion
Source: "binsupp-x64\winpty*";     DestDir: "{app}\bin"; Check: Is64BitInstallMode; Components: server;        Flags: ignoreversion
; x64 - /usr/sbin
Source: "usr\sbin-x64\ssh-keysign.exe";       DestDir: "{app}\usr\sbin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "usr\sbin-x64\ssh-pkcs11-helper.exe"; DestDir: "{app}\usr\sbin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "usr\sbin-x64\cygserver.exe";         DestDir: "{app}\usr\sbin"; Check: Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "usr\sbin-x64\sftp-server.exe";       DestDir: "{app}\usr\sbin"; Check: Is64BitInstallMode; Components: server;        Flags: ignoreversion
Source: "usr\sbin-x64\sshd.exe";              DestDir: "{app}\usr\sbin"; Check: Is64BitInstallMode; Components: server;        Flags: ignoreversion
; cygwin x86 - /bin
Source: "bin-x86\*.dll";                     DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion solidbreak
Source: "bin-x86\cygpath.exe";               DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\cygrunsrv.exe";             DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\cygstart.exe";              DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\editrights.exe";            DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\false.exe";                 DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\getent.exe";                DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\id.exe";                    DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\less.exe";                  DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\mintty.exe";                DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\mkgroup.exe";               DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\mkpasswd.exe";              DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\mount.exe";                 DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\nano.exe";                  DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\passwd.exe";                DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\rebase.exe";                DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\rsync.exe";                 DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\scp.exe";                   DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\sftp.exe";                  DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\ssh-add.exe";               DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\ssh-agent.exe";             DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\ssh-keygen.exe";            DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\ssh-keyscan.exe";           DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\ssh-pageant.exe";           DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\ssh.exe";                   DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\touch.exe";                 DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\true.exe";                  DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\umount.exe";                DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\uname.exe";                 DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\unzip.exe";                 DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\vi.exe";                    DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\xz.exe";                    DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\zip.exe";                   DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "bin-x86\cygwin-console-helper.exe"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: server;        Flags: ignoreversion
Source: "bin-x86\dash.exe";                  DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: server;        Flags: ignoreversion
Source: "bin-x86\tty.exe";                   DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: server;        Flags: ignoreversion
; supplemental x86 - /bin
Source: "binsupp-x86\runposh.exe"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "binsupp-x86\setacl.exe";  DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "binsupp-x86\posh.exe";    DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: server;        Flags: ignoreversion
Source: "binsupp-x86\winpty*";     DestDir: "{app}\bin"; Check: not Is64BitInstallMode; Components: server;        Flags: ignoreversion
; x86 - /usr/sbin
Source: "usr\sbin-x86\ssh-keysign.exe";       DestDir: "{app}\usr\sbin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "usr\sbin-x86\ssh-pkcs11-helper.exe"; DestDir: "{app}\usr\sbin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "usr\sbin-x86\cygserver.exe";         DestDir: "{app}\usr\sbin"; Check: not Is64BitInstallMode; Components: client server; Flags: ignoreversion
Source: "usr\sbin-x86\sftp-server.exe";       DestDir: "{app}\usr\sbin"; Check: not Is64BitInstallMode; Components: server;        Flags: ignoreversion
Source: "usr\sbin-x86\sshd.exe";              DestDir: "{app}\usr\sbin"; Check: not Is64BitInstallMode; Components: server;        Flags: ignoreversion
; shared - /
Source: "{#IconFilename}";      DestDir: "{app}"; Components: client server; Flags: solidbreak
Source: "CygSSH-UserGuide.chm"; DestDir: "{app}"; Components: client server
Source: "CygSSH-UserGuide.pdf"; DestDir: "{app}"; Components: client server
; shared - /bin
Source: "bin-scripts\Edit-SSHKey.ps1";     DestDir: "{app}\bin"; Components: client server
Source: "bin-scripts\Get-AccountName.ps1"; DestDir: "{app}\bin"; Components: client server
Source: "bin-scripts\New-SSHKey.ps1";      DestDir: "{app}\bin"; Components: client server
Source: "bin-scripts\Set-FstabConfig.ps1"; DestDir: "{app}\bin"; Components: client server
Source: "bin-scripts\Win32API.def";        DestDir: "{app}\bin"; Components: client server
Source: "bin-scripts\Set-SSHGroup.ps1";    DestDir: "{app}\bin"; Components: server
Source: "bin-scripts\Set-SSHHostKey.ps1";  DestDir: "{app}\bin"; Components: server
Source: "bin-scripts\Set-SSHService.ps1";  DestDir: "{app}\bin"; Components: server
Source: "bin-scripts\Set-S4ULogonFix.ps1"; DestDir: "{app}\bin"; Components: server; OnlyBelowVersion: 6.3
; shared - /etc
Source: "etc\cygserver.conf"; DestDir: "{app}\etc"; Components: client server; Flags: onlyifdoesntexist uninsneveruninstall
Source: "etc\nsswitch.conf";  DestDir: "{app}\etc"; Components: client server; Flags: onlyifdoesntexist uninsneveruninstall
Source: "etc\ssh_config";     DestDir: "{app}\etc"; Components: client server; Flags: onlyifdoesntexist uninsneveruninstall
Source: "etc\virc";           DestDir: "{app}\etc"; Components: client server; Flags: onlyifdoesntexist uninsneveruninstall
Source: "etc\banner.txt";     DestDir: "{app}\etc"; Components: server;        Flags: onlyifdoesntexist uninsneveruninstall
Source: "etc\passwd";         DestDir: "{app}\etc"; Components: server;        Flags: onlyifdoesntexist uninsneveruninstall
Source: "etc\profile";        DestDir: "{app}\etc"; Components: server;        Flags: onlyifdoesntexist uninsneveruninstall
Source: "etc\sshd_config";    DestDir: "{app}\etc"; Components: server;        Flags: onlyifdoesntexist uninsneveruninstall
Source: "etc\moduli";         DestDir: "{app}\etc"; Components: server
; shared - /etc/defaults/etc
Source: "etc\defaults\etc\cygserver.conf"; DestDir: "{app}\etc\defaults\etc"; Components: client server
Source: "etc\defaults\etc\nsswitch.conf";  DestDir: "{app}\etc\defaults\etc"; Components: client server
Source: "etc\defaults\etc\ssh_config";     DestDir: "{app}\etc\defaults\etc"; Components: client server
Source: "etc\defaults\etc\virc";           DestDir: "{app}\etc\defaults\etc"; Components: client server
Source: "etc\defaults\etc\banner.txt";     DestDir: "{app}\etc\defaults\etc"; Components: server
Source: "etc\defaults\etc\passwd";         DestDir: "{app}\etc\defaults\etc"; Components: server
Source: "etc\defaults\etc\profile";        DestDir: "{app}\etc\defaults\etc"; Components: server
Source: "etc\defaults\etc\sshd_config";    DestDir: "{app}\etc\defaults\etc"; Components: server
; shared - /usr/share
Source: "usr\share\*"; DestDir: "{app}\usr\share"; Components: client server; Flags: recursesubdirs createallsubdirs
; shared - /usr/src
Source: "usr\src-was\*"; DestDir: "{app}\usr\src"; Components: client server; Flags: recursesubdirs
; shared - /users
Source: "users\SYSTEM\.ssh\*"; DestDir: "{app}\users\SYSTEM\.ssh"; Components: server; Flags: uninsneveruninstall
; shared - /var
Source: "var\log\lastlog"; DestDir: "{app}\var\log"; Components: server; Flags: onlyifdoesntexist uninsneveruninstall
Source: "var\run\utmp";    DestDir: "{app}\var\run"; Components: server; Flags: onlyifdoesntexist uninsneveruninstall

[Dirs]
Name: "{app}\tmp";       Components: client server
Name: "{app}\var\empty"; Components: server

[Icons]
Name: "{group}\{cm:IconsUserGuideName}"; Filename: "{app}\CygSSH-UserGuide.chm"; Comment: "{cm:IconsUserGuideComment}"

[Tasks]
Name: startservice; Description: "{cm:TasksStartServiceDescription}"; Components: server; Check: not ServiceExists('{#ServiceName}')
Name: modifypath;   Description: "{cm:TasksModifyPathDescription,{code:GetSystemOrUserPath}}"; Check: not IsDirInPath()
Name: s4ulogonfix;  Description: "{cm:TasksS4ULogonFixDescription}"; Components: server; Flags: unchecked; OnlyBelowVersion: 6.3

[Run]
; Add Users:RWXD for /tmp
Filename: "{app}\bin\setacl.exe"; \
  Parameters: "-on ""{app}\tmp"" -ot file -actn ace -ace n:S-1-5-32-545;p:change"; \
  StatusMsg: "{cm:RunSetPermissionsStatusMsg}"; \
  Components: client server; \
  Flags: runhidden

; Set SYSTEM:F/Administrators:F for /users
Filename: "{app}\bin\setacl.exe"; \
  Parameters: "-on ""{app}\users"" -ot file -actn ace -ace n:S-1-5-18;p:full -actn ace -ace n:S-1-5-32-544;p:full -actn setprot -op dacl:p_nc"; \
  StatusMsg: "{cm:RunSetPermissionsStatusMsg}"; \
  Components: server; \
  Flags: runhidden

; Configure fstab
Filename: "{app}\bin\runposh.exe"; \
  Parameters: "-b --noninteractive --quiet --wait --windowstyle=hidden ""{app}\bin\Set-FstabConfig.ps1"""; \
  StatusMsg: "{cm:RunConfigureFstabStatusMsg}"; \
  Components: client server

; Create SSH host keys
Filename: "{app}\bin\runposh.exe"; \
  Parameters: "-b --noninteractive --quiet --wait --windowstyle=hidden ""{app}\bin\Set-SSHHostKey.ps1"""; \
  StatusMsg: "{cm:RunConfigureSSHHostKeysStatusMsg}"; \
  Components: server

; Configure local access group and sshd_config file
Filename: "{app}\bin\runposh.exe"; \
  Parameters: "-b --noninteractive --quiet --wait --windowstyle=hidden ""{app}\bin\Set-SSHGroup.ps1"" -- -NoConfirm"; \
  StatusMsg: "{cm:RunConfigureLocalAccessGroupStatusMsg}"; \
  Components: server

; S4U local account logon fix - OS older than 6.3 (Windows 8.1/Server 2012 R2)
Filename: "{app}\bin\runposh.exe"; \
  Parameters: "-b --noninteractive --quiet --wait --windowstyle=hidden ""{app}\bin\Set-S4ULogonFix.ps1"" -- -Enable -NoConfirm"; \
  StatusMsg: "{cm:RunConfigureMsV1_0S4ULogonFixStatusMsg}"; \
  Components: server; \
  Tasks: s4ulogonfix

; Install service
Filename: "{app}\bin\runposh.exe"; \
  Parameters: "-b --noninteractive --quiet --wait --windowstyle=hidden ""{app}\bin\Set-SSHService.ps1"" -- -EnvVarOptions disable_pcon -Install -NoConfirm"; \
  StatusMsg: "{cm:RunInstallServiceStatusMsg}"; \
  Components: server; \
  Check: not ServiceExists('{#ServiceName}')

; Start service
Filename: "{app}\bin\runposh.exe"; \
  Parameters: "-b --noninteractive --quiet --wait --windowstyle=hidden ""{app}\bin\Set-SSHService.ps1"" -- -Start -NoConfirm"; \
  StatusMsg: "{cm:RunStartServiceStatusMsg}"; \
  Components: server; \
  Tasks: startservice

[UninstallRun]
Filename: "{app}\bin\runposh.exe"; \
  Parameters: "-b --noninteractive --quiet --wait --windowstyle=hidden ""{app}\bin\Set-SSHService.ps1"" -- -Uninstall -NoConfirm"; \
  RunOnceId: "uninstallservice"; \
  Components: server

[Code]

// Code support:
// * Verify PowerShell v2 or later installed before allowing install
// * Add to Path or remove from Path
// * Enable S4ULogonFix by default when OS < v6.3, not domain member, and
//   interactive install
// * Executable detection: Automatic service stop/process termination and
//   service restart (Windows Restart Manager does not work correctly with
//   Cygwin services and processes); uses WMI and progress page

const
  SC_MANAGER_CONNECT   = 1;
  SERVICE_QUERY_STATUS = 4;

type
  TSCHandle = THandle;
  TServiceStatus = record
    dwServiceType:             DWORD;
    dwCurrentState:            DWORD;
    dwControlsAccepted:        DWORD;
    dwWin32ExitCode:           DWORD;
    dwServiceSpecificExitCode: DWORD;
    dwCheckPoint:              DWORD;
    dwWaitHint:                DWORD;
    end;
  TCygwinService = record
    ProcessId:      DWORD;
    Name:           string;
    DisplayName:    string;
    ExecutablePath: string;
    end;
  TCygwinServiceList = array of TCygwinService;
  TCygwinProcess = record
    ProcessId:      DWORD;
    Name:           string;
    ExecutablePath: string;
    end;
  TCygwinProcessList = array of TCygwinProcess;

var
  AppProgressPage: TOutputProgressWizardPage;
  ModifyPathTaskName: string;
  PathIsModified, S4UTaskDefaultChanged: boolean;
  SWbemLocator, WMIService: variant;
  RunningServices: TCygwinServiceList;

// Windows API function declarations
function NetGetJoinInformation(lpServer:         string;
                               var lpNameBuffer: DWORD;
                               var BufferType:   DWORD): DWORD;
  external 'NetGetJoinInformation@netapi32.dll stdcall setuponly';

function NetApiBufferFree(Buffer: DWORD): DWORD;
  external 'NetApiBufferFree@netapi32.dll stdcall setuponly';

function OpenSCManager(lpMachineName:   string;
                       lpDatabaseName:  string;
                       dwDesiredAccess: DWORD): TSCHandle;
  external 'OpenSCManagerW@advapi32.dll stdcall';

function OpenService(hSCManager:      TSCHandle;
                     lpServiceName:   string;
                     dwDesiredAccess: DWORD): TSCHandle;
  external 'OpenServiceW@advapi32.dll stdcall';

function QueryServiceStatus(hService:            TSCHandle;
                            Out lpServiceStatus: TServiceStatus): BOOL;
  external 'QueryServiceStatus@advapi32.dll stdcall';

function CloseServiceHandle(hSCObject: TSCHandle): BOOL;
  external 'CloseServiceHandle@advapi32.dll stdcall';

// Used by:
//   NextButtonClick() function
function ParamStrExists(const Param: string): boolean;
  var
    I: integer;
  begin
  for I := 1 to ParamCount do
    begin
    result := CompareText(Param, ParamStr(I)) = 0;
    if result then exit;
    end;
  end;

// Requires:
//   OpenSCManager() Windows API function
//   OpenService() Windows API function
//   QueryServiceStatus() Windows API function
//   CloseServiceHandle() Windows API function
// Used by:
//   [Tasks] section
//   [Run] section
// Get whether service exists
// Acknowledgment: TLama (https://stackoverflow.com/questions/32463808/)
function ServiceExists(ServiceName: string): boolean;
  var
    Manager, Service: TSCHandle;
    Status: TServiceStatus;
  begin
  result := false;
  manager := OpenSCManager('', '', SC_MANAGER_CONNECT);
  if Manager <> 0 then
    try
      Service := OpenService(Manager, ServiceName, SERVICE_QUERY_STATUS);
      if Service <> 0 then
        try
          result := QueryServiceStatus(Service, Status);
        finally
          CloseServiceHandle(Service);
        end; //try
    finally
      CloseServiceHandle(Manager);
    end //try
  else
    RaiseException('OpenSCManager failed: ' + SysErrorMessage(DLLGetLastError()));
  end;

// Used by:
//   InitializeSetup() function
// Return true if we detect at least PowerShell v2, or false otherwise
function IsPowerShell2OrHigherInstalled(): boolean;
  var
    RootPath, VersionString: string;
    SubkeyNames: TArrayOfString;
    HighestPSVersion, I, PSVersion: integer;
  begin
  RootPath := 'SOFTWARE\Microsoft\PowerShell';
  result := RegGetSubkeyNames(HKEY_LOCAL_MACHINE, RootPath, SubkeyNames);
  if not result then exit;
  HighestPSVersion := 0;
  for I := 0 to GetArrayLength(SubkeyNames) - 1 do
    begin
    if RegQueryStringValue(HKEY_LOCAL_MACHINE, RootPath + '\' + SubkeyNames[I] + '\PowerShellEngine', 'PowerShellVersion', VersionString) then
      begin
      PSVersion := StrToIntDef(Copy(VersionString, 0, 1), 0);
      if PSVersion > HighestPSVersion then
        HighestPSVersion := PSVersion;
      end;
    end;
  result := HighestPSVersion >= 2;
  end;

// Requires:
//   ModifyPathTaskName global variable
//   PathIsModified global variable
//   S4UTaskDefaultChanged global variable
//   SWbemLocator global variable
//   WMIService global variable
//   IsPowerShell2OrHigherInstalled() function
function InitializeSetup(): boolean;
  begin
  result := IsPowerShell2OrHigherInstalled();
  if not result then
    begin
    Log(CustomMessage('ErrorNoPowerShellLogMessage'));
    if not WizardSilent() then
      MsgBox(CustomMessage('ErrorNoPowerShellGUIMessage'), mbCriticalError, MB_OK);
    exit;
    end;
  ModifyPathTaskName := 'modifypath';
  PathIsModified := GetPreviousData('Modify Path', '') = 'true';
  S4UTaskDefaultChanged := false;
  try
    SWbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
    WMIService := SWbemLocator.ConnectServer('', 'root\CIMV2');
  except
    SWbemLocator := Null();
    WMIService := Null();
  end; //try
  SetArrayLength(RunningServices, 0);
  end;

procedure InitializeWizard();
  begin
  AppProgressPage := CreateOutputProgressPage(SetupMessage(msgWizardInstalling),
    FmtMessage(CustomMessage('AppProgressPageInstallingCaption'), [ExpandConstant('{#SetupSetting("AppName")}')]));
  end;

// Requires:
//   PathIsModified global variable
function InitializeUninstall(): boolean;
  begin
  result := true;
  PathIsModified := GetPreviousData('Modify Path', '') = 'true';
  end;

// Requires:
//   NetGetJoinInformation() Windows API function
//   NetApiBufferFree() Windows API function
// Used by:
//   CurPageChanged() procedure
// Returns true if computer is a domain member, or false otherwise
function IsDomainMember(): boolean;
  var
    NameBuffer, BufferType: DWORD;
  begin
  result := false;
  if NetGetJoinInformation('', NameBuffer, BufferType) = 0 then
    begin
    result := BufferType = 3;  // NetSetupDomainName
    NetApiBufferFree(NameBuffer);
    end;
  end;

// Requires:
//   S4UTaskDefaultChanged global variable
//   IsDomainMember() function
procedure CurPageChanged(PageID: integer);
  begin
  if PageID = wpSelectTasks then
    begin
    if not WizardSilent() then
      begin
      // Only select if not already changed
      if not S4UTaskDefaultChanged then
        begin
        // Interactive install: Set s4ulogonfix task default:
        // If not domain member, select by default (but only interactively)
        // If silent install, command line must specify the task
        if not IsDomainMember() then WizardSelectTasks('s4ulogonfix');
        S4UTaskDefaultChanged := true;
        end;
      end;
    end;
  end;

// Used by:
//   [Tasks] section
function GetSystemOrUserPath(Param: string): string;
  begin
  if IsAdminInstallMode() then
    result := CustomMessage('PathTypeSystemMessage')
  else
    result := CustomMessage('PathTypeUserMessage');
  end;

// Used by:
//   ModifyPath() function
//   IsDirInPath() function
// Gets the directory are we adding to (or removing from) the path
function GetPathDirName(): string;
  begin
  result := ExpandConstant('{app}\bin');
  end;

// Used by:
//   SplitPathString() procedure
// Splits S into array Dest using Delim as delimiter
procedure SplitString(S, Delim: string; var Dest: TArrayOfString);
  var
    Temp: string;
    I, P: integer;
  begin
  Temp := S;
  I := StringChangeEx(Temp, Delim, '', true);
  SetArrayLength(Dest, I + 1);
  for I := 0 to GetArrayLength(Dest) - 1 do
    begin
    P := Pos(Delim, S);
    if P > 0 then
      begin
      Dest[I] := Copy(S, 1, P - 1);
      Delete(S, 1, P + Length(Delim) - 1);
      end
    else
      Dest[I] := S;
    end;
  end;

// Used by:
//   PathStringContainsDir() function
//   AddDirToPathString() function
//   RemoveDirFromPathString() function
//   UpdatePath() function
// Splits the specified semicolon-delimited path string into an array such
// that each element in the string array contains a properly formed
// directory name; array might contain empty string elements
procedure SplitPathString(Path: string; var Dest: TArrayOfString);
  var
    I: integer;
  begin
  SplitString(Path, ';', Dest);
  for I := 0 to GetArrayLength(Dest) - 1 do
    Dest[I] := RemoveBackslashUnlessRoot(Trim(Dest[I]));
  end;

// Requires:
//   SplitPathString() procedure
// Returns whether the semicolon-delimited path string contains the named
// directory or not; not case-sensitive; if Dir is empty or only whitespace,
// the function returns false
function PathStringContainsDir(Path, Dir: string): boolean;
  var
    PathArray: TArrayOfString;
    I: integer;
  begin
  result := false;
  Dir := RemoveBackslashUnlessRoot(Trim(Dir));
  if Dir = '' then exit;
  SplitPathString(Path, PathArray);
  for I := 0 to GetArrayLength(PathArray) - 1 do
    begin
    result := CompareText(PathArray[I], Dir) = 0;
    if result then exit;
    end;
  end;

// Requires:
//   PathStringContainsDir() function
//   SplitPathString() procedure
// Adds a named directory to a semicolon-delimited path string; returns path
// string with the named directory added; if Dir is empty, only whitespace, or
// already exists in the path string, the function returns the path string
// unchanged
function AddDirToPathString(Path, Dir: string): string;
  var
    PathArray: TArrayOfString;
    I: integer;
  begin
  result := Path;
  Dir := RemoveBackslashUnlessRoot(Trim(Dir));
  if Dir = '' then exit;
  if PathStringContainsDir(Path, Dir) then exit;
  SplitPathString(Path, PathArray);
  result := '';
  for I := 0 to GetArrayLength(PathArray) - 1 do
    begin
    if Trim(PathArray[I]) <> '' then
      begin
      if result = '' then
        result := PathArray[I]
      else
        result := result + ';' + PathArray[I];
      end;
    end;
  if result <> '' then
    result := result + ';' + Dir
  else
    result := Dir;
  end;

// Requires:
//   PathStringContainsDir() function
//   SplitPathString() procedure
// Removes a named directory from a semicolon-delimited path string; returns
// path string with all instances of the named directory removed; if Dir is
// empty, only whitespace, or doesn't exist in the path string, the function
// returns the path string unchanged
function RemoveDirFromPathString(Path, dir: string): string;
  var
    PathArray: TArrayOfString;
    I: integer;
  begin
  result := Path;
  Dir := RemoveBackslashUnlessRoot(Trim(Dir));
  if Dir = '' then exit;
  if not PathStringContainsDir(Path, Dir) then exit;
  SplitPathString(Path, PathArray);
  for I := 0 to GetArrayLength(PathArray) - 1 do
    begin
    if CompareText(PathArray[I], Dir) = 0 then
      PathArray[I] := '';
    end;
  result := '';
  for I := 0 to GetArrayLength(PathArray) - 1 do
    begin
    if Trim(PathArray[I]) <> '' then
      begin
      if result = '' then
        result := PathArray[I]
      else
        result := result + ';' + PathArray[I];
      end;
    end;
  end;

// Requires:
//   SplitPathString() function
//   AddDirToPathString() function
//   RemoveDirFromPathString() function
// Used by:
//   ModifyPath() function
// AddOrRemove: 'add' or 'remove' (default = 'add')
// PathType: 'user' or 'system' (default = 'user')
// Dir: semicolon-delimited list of directories to add or remove
// Returns false only when a registry update fails
// (NOTE: Do not enclose path names in quotes!)
function UpdatePath(AddOrRemove, PathType, Dir: string): boolean;
  var
    AddToPath: boolean;
    RegRoot, I: integer;
    RegPath, Path, NewPath: string;
    DirArray: TArrayOfString;
  begin
  result := true;
  AddToPath := CompareText(AddOrRemove, 'remove') <> 0;
  if CompareText(PathType, 'system') = 0 then
    begin
    RegRoot := HKEY_LOCAL_MACHINE;
    RegPath := 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment';
    end
  else
    begin
    RegRoot := HKEY_CURRENT_USER;
    RegPath := 'Environment';
    end;
  SplitPathString(Dir, DirArray);
  for I := 0 to GetArrayLength(DirArray) - 1 do
    begin
    if Trim(DirArray[I]) = '' then continue;
    Path := '';
    RegQueryStringValue(RegRoot, RegPath, 'Path', Path);
    if AddToPath then
      NewPath := AddDirToPathString(Path, DirArray[I])
    else
      NewPath := RemoveDirFromPathString(Path, DirArray[I]);
    if NewPath <> Path then
      begin
      result := RegWriteExpandStringValue(RegRoot, RegPath, 'Path', NewPath);
      if not result then exit;
      end;
    end;
  end;

// Requires:
//   GetPathDirName() function
//   UpdatePath() function
// Used by:
//   CurStepChanged() function
//   CurUninstallStepChanged() function
function ModifyPath(const AddOrRemove: string): boolean;
  var
    Action, Context, DirName: string;
  begin
  result := true;
  if CompareText(AddOrRemove, 'remove') <> 0 then
    Action := 'add'
  else
    Action := 'remove';
  if IsAdminInstallMode() then
    Context := 'system'
  else
    Context := 'user';
  DirName := GetPathDirName();
  result := UpdatePath(Action, Context, DirName);
  if result then
    Log(FmtMessage(CustomMessage('PathUpdateSuccessMessage'), [Context,Action,DirName]))
  else
    Log(FmtMessage(CustomMessage('PathUpdateFailMessage'), [Context,Action,DirName]));
  end;

// Requires:
//   PathStringContainsDir() function
//   GetPathDirName() function
// Used by:
//   [Tasks] section
function IsDirInPath(): boolean;
  var
    RegRoot: integer;
    RegPath, Path: string;
  begin
  result := false;
  if IsAdminInstallMode() then
    begin
    RegRoot := HKEY_LOCAL_MACHINE;
    RegPath := 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment';
    end
  else
    begin
    RegRoot := HKEY_CURRENT_USER;
    RegPath := 'Environment';
    end;
  if RegQueryStringValue(RegRoot, RegPath, 'Path', Path) then
    result := PathStringContainsDir(Path, GetPathDirName());
  end;

// Requires:
//   PathIsModified global variable
//   ModifyPath() function
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
  begin
  if CurUninstallStep = usUninstall then
    begin
    if PathIsModified then ModifyPath('remove');
    end;
  end;

function ShouldSkipPage(PageID: integer): boolean;
  begin
  result := false;
  if PageID = wpSelectComponents then
    begin
    result := (not IsAdminInstallMode()) or
      (IsAdminInstallMode() and (GetPreviousData('Setup Type', '') = 'full'));
    end;
  end;

// Requires:
//   PathIsModified global variable
//   ModifyPathTaskName global variable
// IS removes and rewrites 'previous data' values at every reinstall, so at
// initialize time we cache whether modify path task had already been selected
// from a previous install
procedure RegisterPreviousData(PreviousDataKey: integer);
  begin
  SetPreviousData(PreviousDataKey, 'Setup Type', WizardSetupType(false));
  // If task was previously or currently selected, write data again
  if PathIsModified or WizardIsTaskSelected(ModifyPathTaskName) then
    SetPreviousData(PreviousDataKey, 'Modify Path', 'true');
  end;

// Used by:
//   NextButtonClick() function
function GetCygwinRootDir(): string;
  begin
  result := ExpandConstant('{app}');
  end;

// Requires:
//   WMIService global variable
// Used by:
//   GetCygwinRunningServices() function
// For a running Cygwin service, gets two-element output array:
// element 0 = service name, and element 1 = service display name
procedure GetServiceNamesFromProcessId(const ProcessId: DWORD; var Names: TArrayOfString);
  var
    WQLQuery: string;
    SWbemObjectSet, SWbemObject: variant;
    I: integer;
  begin
  WQLQuery := Format('SELECT Name,DisplayName FROM Win32_Service'
    + ' WHERE ProcessID = %d', [ProcessId]);
  try
    SWbemObjectSet := WMIService.ExecQuery(WQLQuery);
    if not VarIsNull(SWbemObjectSet) and (SWbemObjectSet.Count > 0) then
      begin
      for I := 0 to SWbemObjectSet.Count - 1 do
        begin
        SWbemObject := SWbemObjectSet.ItemIndex(I);
        if not VarIsNull(SWbemObject) then
          begin
          SetArrayLength(Names, 2);
          Names[0] := SWbemObject.Name;
          if SWbemObject.DisplayName <> '' then
            Names[1] := SWbemObject.DisplayName
          else
            Names[1] := Names[0];
          break;
          end;
        end;
      end;
  except
  end; //try
  end;

// Used by:
//   GetRunningCygwinProcesses() function
//   StopRunningCygwinServices() function
//   NextButtonClick() function
// Requires:
//   WMIService global variable
//   GetServiceNamesFromProcessId() function
// Gets list of running Cygwin services (process is cygrunsrv.exe)
function GetCygwinRunningServices(CygwinRootDir: string; var Services: TCygwinServiceList): integer;
  var
    WQLQuery: string;
    SWbemObjectSet, SWbemObject: variant;
    I: integer;
    Names: TArrayOfString;
  begin
  result := 0;
  CygwinRootDir := AddBackslash(CygwinRootDir);
  StringChangeEx(CygwinRootDir, '\', '\\', true);
  WQLQuery := Format('SELECT ExecutablePath,Name,ProcessId FROM Win32_Process'
    + ' WHERE (ExecutablePath LIKE "%s%%") AND (NAME = "cygrunsrv.exe")', [CygwinRootDir]);
  try
    SWbemObjectSet := WMIService.ExecQuery(WQLQuery);
    if (not VarIsNull(SWbemObjectSet)) and (SWbemObjectSet.Count > 0) then
      begin
      SetArrayLength(Services, SWbemObjectSet.Count);
      for I := 0 to SWbemObjectSet.Count - 1 do
        begin
        SWbemObject := SWbemObjectSet.ItemIndex(I);
        if not VarIsNull(SWbemObject) then
          begin
          Services[I].ProcessId := SWbemObject.ProcessId;
          GetServiceNamesFromProcessId(SWbemObject.ProcessId, Names);
          Services[I].Name := Names[0];
          Services[I].DisplayName := Names[1];
          Services[I].ExecutablePath := SWbemObject.ExecutablePath;
          result := result + 1;
          end
        else
          begin
          Services[I].ProcessId := 0;
          Services[I].Name := '';
          Services[I].DisplayName := '';
          Services[I].ExecutablePath := '';
          end;
        end;
      end;
  except
    SetArrayLength(Services, 0);
  end; //try
  end;

// Used by:
//   GetRunningCygwinProcesses() function
//   TerminateRunningCygwinProcesses() function
//   NextButtonClick() function
// Requires:
//   WMIService global variable
// Gets list of running Cygwin processes (except cygrunsrv.exe, which are
// assumed to be running services)
function GetCygwinRunningProcesses(CygwinRootDir: string; var Processes: TCygwinProcessList): integer;
  var
    WQLQuery: string;
    SWbemObjectSet, SWbemObject: variant;
    I: integer;
  begin
  result := 0;
  CygwinRootDir := AddBackslash(CygwinRootDir);
  StringChangeEx(CygwinRootDir, '\', '\\', true);
  WQLQuery := Format('SELECT ExecutablePath,Name,ProcessId FROM Win32_Process'
    + ' WHERE (ExecutablePath LIKE "%s%%") AND (Name <> "cygrunsrv.exe")', [CygwinRootDir]);
  try
    SWbemObjectSet := WMIService.ExecQuery(WQLQuery);
    if (not VarIsNull(SWbemObjectSet)) and (SWbemObjectSet.Count > 0) then
      begin
      SetArrayLength(Processes, SWbemObjectSet.Count);
      for I := 0 to SWbemObjectSet.Count - 1 do
        begin
        SWbemObject := SWbemObjectSet.ItemIndex(I);
        if not VarIsNull(SWbemObject) then
          begin
          Processes[I].ProcessId := SWbemObject.ProcessId;
          Processes[I].Name := SWbemObject.Name;
          Processes[I].ExecutablePath := SWbemObject.ExecutablePath;
          result := result + 1;
          end
        else
          begin
          Processes[I].ProcessId := 0;
          Processes[I].Name := ''
          Processes[I].ExecutablePath := '';
          end;
        end;
      end;
  except
    SetArrayLength(Processes, 0);
  end; //try
  end;

// Used by:
//   GetRunningCygwinProcesses() function
// Returns true if the string array contains an item (not case-sensitive)
function ArrayContainsString(var Arr: TArrayOfString; const Item: string): boolean;
  var
    I: integer;
  begin
  result := false;
  for I := 0 to GetArrayLength(Arr) - 1 do
    begin
    result := CompareText(Arr[I], Item) = 0;
    if result then exit;
    end;
  end;

// Requires:
//   GetCygwinRunningServices() function
//   GetCygwinRunningProcesses() function
//   ArrayContainsString() function
// Returns a new-line delimited string containing running Cygwin processes;
// empty return value means 'no Cygwin processes running'
function GetRunningCygwinProcesses(CygwinRootDir: string): string;
  var
    ServiceCount, ProcessCount, I, J, MaxOutput: integer;
    Services: TCygwinServiceList;
    Processes: TCygwinProcessList;
    Output: TArrayOfString;
  begin
  result := '';
  ServiceCount := GetCygwinRunningServices(CygwinRootDir, Services);
  ProcessCount := GetCygwinRunningProcesses(CygwinRootDir, Processes);
  if ServiceCount + ProcessCount = 0 then exit;
  SetArrayLength(Output, ServiceCount + ProcessCount);
  for I := 0 to ServiceCount - 1 do
    Output[I] := Services[I].DisplayName;
  J := I;
  for I := 0 to ProcessCount - 1 do
    if not ArrayContainsString(Output, Processes[I].Name) then
      begin
      Output[J] := Processes[I].Name;
      J := J + 1;
      end;
  MaxOutput := 20;
  if GetArrayLength(Output) >= MaxOutput then
    begin
    J := MaxOutput;
    Output[MaxOutput - 1] := '...';
    end
  else
    J := GetArrayLength(Output);
  for I := 0 to J - 1 do
    if Output[I] <> '' then
      if result = '' then
        result := Output[I]
      else
        result := result + #10 + Output[I];
  end;

// Requires:
//   GetCygwinRunningServices() function
// Used by:
//   NextButtonClick() function
// Stops running Cygwin services using 'net stop'; returns true if all were
// stopped
function StopRunningCygwinServices(CygwinRootDir: string): boolean;
  var
    Count, I, ResultCode: integer;
    Services: TCygwinServiceList;
    Command, Parameters: string;
  begin
  result := false;
  Count := GetCygwinRunningServices(CygwinRootDir, Services);
  if Count > 0 then
    begin
    Command := ExpandConstant('{sys}\net.exe');
    for I := 0 to Count - 1 do
      begin
      Parameters := Format('stop "%s"', [Services[I].Name]);
      Log(FmtMessage(CustomMessage('RunCommandMessage'), [Command,Parameters]));
      Exec(Command, Parameters, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
      end;
    result := GetCygwinRunningServices(CygwinRootDir, Services) = 0;
    end;
  end;

// Requires:
//   GetCygwinRunningProcesses() function
// Used by:
//   NextButtonClick() function
// Terminates running cygwin processes using 'taskkill'; returns true if all
// were terminated
function TerminateRunningCygwinProcesses(CygwinRootDir: string): boolean;
  var
    Count, I, ResultCode: integer;
    Processes: TCygwinProcessList;
    Command, Parameters: string;
  begin
  result := false;
  Count := GetCygwinRunningProcesses(CygwinRootDir, Processes);
  if Count > 0 then
    begin
    Command := ExpandConstant('{sys}\taskkill.exe');
    Parameters := ' ';
    for I := 0 to Count - 1 do
      Parameters := Parameters + Format('/PID %d ', [Processes[I].ProcessId]);
    Parameters := Parameters + '/F';
    Log(FmtMessage(CustomMessage('RunCommandMessage'), [Command,Parameters]));
    Exec(Command, Parameters, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    result := GetCygwinRunningProcesses(CygwinRootDir, Processes) = 0;
    end;
  end;

// Used by:
//   CurStepChanged() procedure
// Starts the services named in the list
function StartCygwinServices(var Services: TCygwinServiceList): boolean;
  var
    Count, I, NumStarted, ResultCode: integer;
    Command, Parameters: string;
  begin
  result := false;
  Count := GetArrayLength(Services);
  if Count > 0 then
    begin
    Command := ExpandConstant('{sys}\net.exe');
    NumStarted := 0;
    for I := 0 to Count - 1 do
      begin
      Parameters := Format('start "%s"', [Services[I].Name]);
      Log(FmtMessage(CustomMessage('RunCommandMessage'), [Command,Parameters]));
      if Exec(Command, Parameters, '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0) then
        NumStarted := NumStarted + 1;
      end;
    result := NumStarted = Count;
    end;
  end;

// Requires:
//   AppProgressPage global variable
//   RunningServices global variable
//   GetRunningCygwinProcesses() function
//   ParamStrExists() function
//   GetCygwinRootDir() function
//   GetCygwinRunningServices() function
//   StopRunningCygwinServices() function
//   GetCygwinRunningProcesses() function
//   TerminateRunningCygwinProcesses() function
function NextButtonClick(CurPageID: integer): boolean;
  var
    ProcList: string;
    Count: integer;
    Processes: TCygwinProcessList;
  begin
  result := true;
  if CurPageID = wpReady then
    begin
    ProcList := GetRunningCygwinProcesses(GetCygwinRootDir());
    result := ProcList = '';
    if not result then
      begin
      Log(CustomMessage('ApplicationsRunningLogMessage'));
      result := ParamStrExists('/closeapplications') or ParamStrExists('/forcecloseapplications');
      if not result then
        result := SuppressibleTaskDialogMsgBox(CustomMessage('ApplicationsRunningInstructionMessage'),
          FmtMessage(CustomMessage('ApplicationsRunningTextMessage'),[ProcList]),
          mbCriticalError,
          MB_YESNO, [CustomMessage('CloseApplicationsMessage'),CustomMessage('DontCloseApplicationsMessage')],
          0,
          IDNO) = IDYES;
      if result then
        begin
        AppProgressPage.SetText(CustomMessage('AppProgressPageStoppingMessage'), '');
        AppProgressPage.SetProgress(0, 0);
        AppProgressPage.Show();
        try
          AppProgressPage.SetProgress(1, 3);
          // Cache running service(s) in global variable for later restart
          Count := GetCygwinRunningServices(GetCygwinRootDir(), RunningServices);
          result := (Count = 0) or (StopRunningCygwinServices(GetCygwinRootDir()));
          AppProgressPage.SetProgress(2, 3);
          if result then
            begin
            Count := GetCygwinRunningProcesses(GetCygwinRootDir(), Processes);
            result := (Count = 0) or (TerminateRunningCygwinProcesses(GetCygwinRootDir()));
            end;
          AppProgressPage.SetProgress(3, 3);
          if result then
            Log(CustomMessage('ClosedApplicationsMessage'))
          else
            begin
            Log(SetupMessage(msgErrorCloseApplications));
            SuppressibleMsgBox(SetupMessage(msgErrorCloseApplications), mbCriticalError, MB_OK, IDOK);
            end;
        finally
          AppProgressPage.Hide();
        end; //try
        end
      else
        Log(CustomMessage('ApplicationsStillRunningMessage'));
      end;
    end;
  end;

// Requires:
//   AppProgressPage global variable
//   RunningServices global variable
//   StartCygwinServices() function
procedure CurStepChanged(CurStep: TSetupStep);
  begin
  if CurStep = ssPostInstall then
    begin
    if WizardIsTaskSelected(ModifyPathTaskName) then
      ModifyPath('add');
    if GetArrayLength(RunningServices) > 0 then
      begin
      AppProgressPage.SetText(CustomMessage('AppProgressPageStartingMessage'), '');
      AppProgressPage.SetProgress(0, 0);
      AppProgressPage.Show();
      try
        AppProgressPage.SetProgress(1, 2);
        if StartCygwinServices(RunningServices) then
          Log(CustomMessage('StartedServicesMessage'));
        AppProgressPage.SetProgress(2, 2);
      finally
        AppProgressPage.Hide();
      end; //try
      end;
    end;
  end;
