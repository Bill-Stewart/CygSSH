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
Source: "etc\nsswitch.conf"; DestDir: "{app}\etc"; Components: client server; Flags: onlyifdoesntexist uninsneveruninstall
Source: "etc\passwd";        DestDir: "{app}\etc"; Components: client server; Flags: onlyifdoesntexist uninsneveruninstall
Source: "etc\ssh_config";    DestDir: "{app}\etc"; Components: client server; Flags: onlyifdoesntexist uninsneveruninstall
Source: "etc\moduli";        DestDir: "{app}\etc"; Components: server
Source: "etc\banner.txt";    DestDir: "{app}\etc"; Components: server;        Flags: onlyifdoesntexist uninsneveruninstall
Source: "etc\profile";       DestDir: "{app}\etc"; Components: server;        Flags: onlyifdoesntexist uninsneveruninstall
Source: "etc\sshd_config";   DestDir: "{app}\etc"; Components: server;        Flags: onlyifdoesntexist uninsneveruninstall
; shared - /etc/defaults/etc
Source: "etc\defaults\etc\nsswitch.conf"; DestDir: "{app}\etc\defaults\etc"; Components: client server
Source: "etc\defaults\etc\passwd";        DestDir: "{app}\etc\defaults\etc"; Components: client server
Source: "etc\defaults\etc\ssh_config";    DestDir: "{app}\etc\defaults\etc"; Components: client server
Source: "etc\defaults\etc\banner.txt";    DestDir: "{app}\etc\defaults\etc"; Components: server
Source: "etc\defaults\etc\profile";       DestDir: "{app}\etc\defaults\etc"; Components: server
Source: "etc\defaults\etc\sshd_config";   DestDir: "{app}\etc\defaults\etc"; Components: server
; shared - /usr/share
Source: "usr\share\*"; DestDir: "{app}\usr\share"; Components: server; Flags: recursesubdirs createallsubdirs
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
  Parameters: "--noninteractive --quiet --wait --windowstyle=hidden ""{app}\bin\Set-FstabConfig.ps1"""; \
  StatusMsg: "{cm:RunConfigureFstabStatusMsg}"; \
  Components: client server

; Create SSH host keys
Filename: "{app}\bin\runposh.exe"; \
  Parameters: "--noninteractive --quiet --wait --windowstyle=hidden ""{app}\bin\Set-SSHHostKey.ps1"""; \
  StatusMsg: "{cm:RunConfigureSSHHostKeysStatusMsg}"; \
  Components: server

; Configure local access group and sshd_config file
Filename: "{app}\bin\runposh.exe"; \
  Parameters: "--noninteractive --quiet --wait --windowstyle=hidden ""{app}\bin\Set-SSHGroup.ps1"" -- -NoConfirm"; \
  StatusMsg: "{cm:RunConfigureLocalAccessGroupStatusMsg}"; \
  Components: server

; S4U local account logon fix - OS older than 6.3 (Windows 8.1/Server 2012 R2)
Filename: "{app}\bin\runposh.exe"; \
  Parameters: "--noninteractive --quiet --wait --windowstyle=hidden ""{app}\bin\Set-S4ULogonFix.ps1"" -- -Enable -NoConfirm"; \
  StatusMsg: "{cm:RunConfigureMsV1_0S4ULogonFixStatusMsg}"; \
  Components: server; \
  Tasks: s4ulogonfix

; Install service
Filename: "{app}\bin\runposh.exe"; \
  Parameters: "--noninteractive --quiet --wait --windowstyle=hidden ""{app}\bin\Set-SSHService.ps1"" -- -Install -NoConfirm"; \
  StatusMsg: "{cm:RunInstallServiceStatusMsg}"; \
  Components: server; \
  Check: not ServiceExists('{#ServiceName}')

; Start service
Filename: "{app}\bin\runposh.exe"; \
  Parameters: "--noninteractive --quiet --wait --windowstyle=hidden ""{app}\bin\Set-SSHService.ps1"" -- -Start -NoConfirm"; \
  StatusMsg: "{cm:RunStartServiceStatusMsg}"; \
  Components: server; \
  Tasks: startservice

[UninstallRun]
Filename: "{app}\bin\runposh.exe"; \
  Parameters: "--noninteractive --quiet --wait --windowstyle=hidden ""{app}\bin\Set-SSHService.ps1"" -- -Uninstall -NoConfirm"; \
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

Const
  SC_MANAGER_CONNECT   = 1;
  SERVICE_QUERY_STATUS = 4;

Type
  TSCHandle = THandle;
  TServiceStatus = Record
                   dwServiceType:             DWORD;
                   dwCurrentState:            DWORD;
                   dwControlsAccepted:        DWORD;
                   dwWin32ExitCode:           DWORD;
                   dwServiceSpecificExitCode: DWORD;
                   dwCheckPoint:              DWORD;
                   dwWaitHint:                DWORD;
                   End;
  TCygwinService = Record
                   ProcessId:      DWORD;
                   Name:           String;
                   DisplayName:    String;
                   ExecutablePath: String;
                   End;
  TCygwinServiceList = Array Of TCygwinService;
  TCygwinProcess = Record
                   ProcessId:      DWORD;
                   Name:           String;
                   ExecutablePath: String;
                   End;
  TCygwinProcessList = Array Of TCygwinProcess;

Var
  AppProgressPage: TOutputProgressWizardPage;
  ModifyPathTaskName: String;
  PathIsModified, S4UTaskDefaultChanged: Boolean;
  SWbemLocator, WMIService: Variant;
  RunningServices: TCygwinServiceList;

// Windows API function declarations
Function NetGetJoinInformation(lpServer:         String;
                               Var lpNameBuffer: DWORD;
                               Var BufferType:   DWORD): DWORD;
  External 'NetGetJoinInformation@netapi32.dll stdcall setuponly';

Function NetApiBufferFree(Buffer: DWORD): DWORD;
  External 'NetApiBufferFree@netapi32.dll stdcall setuponly';

Function OpenSCManager(lpMachineName:   String;
                       lpDatabaseName:  String;
                       dwDesiredAccess: DWORD): TSCHandle;
  External 'OpenSCManagerW@advapi32.dll stdcall';

Function OpenService(hSCManager:      TSCHandle;
                     lpServiceName:   String;
                     dwDesiredAccess: DWORD): TSCHandle;
  External 'OpenServiceW@advapi32.dll stdcall';

Function QueryServiceStatus(hService:            TSCHandle;
                            Out lpServiceStatus: TServiceStatus): BOOL;
  External 'QueryServiceStatus@advapi32.dll stdcall';

Function CloseServiceHandle(hSCObject: TSCHandle): BOOL;
  External 'CloseServiceHandle@advapi32.dll stdcall';

// Used by:
//   NextButtonClick() function
Function ParamStrExists(Const Param: String): Boolean;
  Var
    I: Integer;
  Begin
  For I := 1 To ParamCount Do
    Begin
    Result := CompareText(Param, ParamStr(I)) = 0;
    If Result Then Exit;
    End;
  End;

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
Function ServiceExists(ServiceName: String): Boolean;
  Var
    Manager, Service: TSCHandle;
    Status: TServiceStatus;
  Begin
  Result := False;
  Manager := OpenSCManager('', '', SC_MANAGER_CONNECT);
  If Manager <> 0 Then
    Try
      Service := OpenService(Manager, ServiceName, SERVICE_QUERY_STATUS);
      If Service <> 0 Then
        Try
          Result := QueryServiceStatus(Service, Status);
        Finally
          CloseServiceHandle(Service);
        End; //Try
    Finally
      CloseServiceHandle(Manager);
    End //Try
  Else
    RaiseException('OpenSCManager failed: ' + SysErrorMessage(DLLGetLastError()));
  End;

// Used by:
//   InitializeSetup() function
// Return True if we detect at least PowerShell v2, or False otherwise
Function IsPowerShell2OrHigherInstalled(): Boolean;
  Var
    RootPath, VersionString: String;
    SubkeyNames: TArrayOfString;
    HighestPSVersion, I, PSVersion: Integer;
  Begin
  RootPath := 'SOFTWARE\Microsoft\PowerShell';
  Result := RegGetSubkeyNames(HKEY_LOCAL_MACHINE, RootPath, SubkeyNames);
  If Not Result Then Exit;
  HighestPSVersion := 0;
  For I := 0 To GetArrayLength(SubkeyNames) - 1 Do
    Begin
    If RegQueryStringValue(HKEY_LOCAL_MACHINE, RootPath + '\' + SubkeyNames[I] + '\PowerShellEngine', 'PowerShellVersion', VersionString) Then
      Begin
      PSVersion := StrToIntDef(Copy(VersionString, 0, 1), 0);
      If PSVersion > HighestPSVersion Then
        HighestPSVersion := PSVersion;
      End;
    End;
  Result := HighestPSVersion >= 2;
  End;

// Requires:
//   ModifyPathTaskName global variable
//   PathIsModified global variable
//   S4UTaskDefaultChanged global variable
//   SWbemLocator global variable
//   WMIService global variable
//   IsPowerShell2OrHigherInstalled() function
Function InitializeSetup(): Boolean;
  Begin
  Result := IsPowerShell2OrHigherInstalled();
  If Not Result Then
    Begin
    Log(CustomMessage('ErrorNoPowerShellLogMessage'));
    If Not WizardSilent() Then
      MsgBox(CustomMessage('ErrorNoPowerShellGUIMessage'), mbCriticalError, MB_OK);
    Exit;
    End;
  ModifyPathTaskName := 'modifypath';
  PathIsModified := GetPreviousData('Modify Path', '') = 'true';
  S4UTaskDefaultChanged := False;
  Try
    SWbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
    WMIService := SWbemLocator.ConnectServer('', 'root\CIMV2');
  Except
    SWbemLocator := Null();
    WMIService := Null();
  End; //Try
  SetArrayLength(RunningServices, 0);
  End;

Procedure InitializeWizard();
  Begin
  AppProgressPage := CreateOutputProgressPage(SetupMessage(msgWizardInstalling),
    FmtMessage(CustomMessage('AppProgressPageInstallingCaption'), [ExpandConstant('{#SetupSetting("AppName")}')]));
  End;

// Requires:
//   PathIsModified global variable
Function InitializeUninstall(): Boolean;
  Begin
  Result := True;
  PathIsModified := GetPreviousData('Modify Path', '') = 'true';
  End;

// Requires:
//   NetGetJoinInformation() Windows API function
//   NetApiBufferFree() Windows API function
// Used by:
//   CurPageChanged() procedure
// Returns True if computer is a domain member, or False otherwise
Function IsDomainMember(): Boolean;
  Var
    NameBuffer, BufferType: DWORD;
  Begin
  Result := False;
  If NetGetJoinInformation('', NameBuffer, BufferType) = 0 Then
    Begin
    Result := BufferType = 3;  // NetSetupDomainName
    NetApiBufferFree(NameBuffer);
    End;
  End;

// Requires:
//   S4UTaskDefaultChanged global variable
//   IsDomainMember() function
Procedure CurPageChanged(PageID: Integer);
  Begin
  If PageID = wpSelectTasks Then
    Begin
    If Not WizardSilent() Then
      Begin
      // Only select if not already changed
      If Not S4UTaskDefaultChanged Then
        Begin
        // Interactive install: Set s4ulogonfix task default:
        // If not domain member, select by default (but only interactively)
        // If silent install, command line must specify the task
        If Not IsDomainMember() Then WizardSelectTasks('s4ulogonfix');
        S4UTaskDefaultChanged := True;
        End;
      End;
    End;
  End;

// Used by:
//   [Tasks] section
Function GetSystemOrUserPath(Param: String): String;
  Begin
  If IsAdminInstallMode() Then
    Result := CustomMessage('PathTypeSystemMessage')
  Else
    Result := CustomMessage('PathTypeUserMessage');
  End;

// Used by:
//   ModifyPath() function
//   IsDirInPath() function
// Gets the directory are we adding to (or removing from) the path
Function GetPathDirName(): String;
  Begin
  Result := ExpandConstant('{app}\bin');
  End;

// Used by:
//   SplitPathString() procedure
// Splits S into array Dest using Delim as delimiter
Procedure SplitString(S, Delim: String; Var Dest: TArrayOfString);
  Var
    Temp: String;
    I, P: Integer;
  Begin
  Temp := S;
  I := StringChangeEx(Temp, Delim, '', True);
  SetArrayLength(Dest, I + 1);
  For I := 0 To GetArrayLength(Dest) - 1 Do
    Begin
    P := Pos(Delim, S);
    If P > 0 Then
      Begin
      Dest[I] := Copy(S, 1, P - 1);
      Delete(S, 1, P + Length(Delim) - 1);
      End
    Else
      Dest[I] := S;
    End;
  End;

// Used by:
//   PathStringContainsDir() function
//   AddDirToPathString() function
//   RemoveDirFromPathString() function
//   UpdatePath() function
// Splits the specified semicolon-delimited path string into an array such
// that each element in the string array contains a properly formed
// directory name; array might contain empty string elements
Procedure SplitPathString(Path: String; Var Dest: TArrayOfString);
  Var
    I: Integer;
  Begin
  SplitString(Path, ';', Dest);
  For I := 0 To GetArrayLength(Dest) - 1 Do
    Dest[I] := RemoveBackslashUnlessRoot(Trim(Dest[I]));
  End;

// Requires:
//   SplitPathString() procedure
// Returns whether the semicolon-delimited path string contains the named
// directory or not; not case-sensitive; if Dir is empty or only whitespace,
// the function returns False
Function PathStringContainsDir(Path, Dir: String): Boolean;
  Var
    PathArray: TArrayOfString;
    I: Integer;
  Begin
  Result := False;
  Dir := RemoveBackslashUnlessRoot(Trim(Dir));
  If Dir = '' Then Exit;
  SplitPathString(Path, PathArray);
  For I := 0 To GetArrayLength(PathArray) - 1 Do
    Begin
    Result := CompareText(PathArray[I], Dir) = 0;
    If Result Then Exit;
    End;
  End;

// Requires:
//   PathStringContainsDir() function
//   SplitPathString() procedure
// Adds a named directory to a semicolon-delimited path string; returns path
// string with the named directory added; if Dir is empty, only whitespace, or
// already exists in the path string, the function returns the path string
// unchanged
Function AddDirToPathString(Path, Dir: String): String;
  Var
    PathArray: TArrayOfString;
    I: Integer;
  Begin
  Result := Path;
  Dir := RemoveBackslashUnlessRoot(Trim(Dir));
  If Dir = '' Then Exit;
  If PathStringContainsDir(Path, Dir) Then Exit;
  SplitPathString(Path, PathArray);
  Result := '';
  For I := 0 To GetArrayLength(PathArray) - 1 Do
    Begin
    If Trim(PathArray[I]) <> '' Then
      Begin
      If Result = '' Then
        Result := PathArray[I]
      Else
        Result := Result + ';' + PathArray[I];
      End;
    End;
  If Result <> '' Then
    Result := Result + ';' + Dir
  Else
    Result := Dir;
  End;

// Requires:
//   PathStringContainsDir() function
//   SplitPathString() procedure
// Removes a named directory from a semicolon-delimited path string; returns
// path string with all instances of the named directory removed; if Dir is
// empty, only whitespace, or doesn't exist in the path string, the function
// returns the path string unchanged
Function RemoveDirFromPathString(Path, Dir: String): String;
  Var
    PathArray: TArrayOfString;
    I: Integer;
  Begin
  Result := Path;
  Dir := RemoveBackslashUnlessRoot(Trim(Dir));
  If Dir = '' Then Exit;
  If Not PathStringContainsDir(Path, Dir) Then Exit;
  SplitPathString(Path, PathArray);
  For I := 0 To GetArrayLength(PathArray) - 1 Do
    Begin
    If CompareText(PathArray[I], Dir) = 0 Then
      PathArray[I] := '';
    End;
  Result := '';
  For I := 0 To GetArrayLength(PathArray) - 1 Do
    Begin
    If Trim(PathArray[I]) <> '' Then
      Begin
      If Result = '' Then
        Result := PathArray[I]
      Else
        Result := Result + ';' + PathArray[I];
      End;
    End;
  End;

// Requires:
//   SplitPathString() function
//   AddDirToPathString() function
//   RemoveDirFromPathString() function
// Used by:
//   ModifyPath() function
// AddOrRemove: 'add' or 'remove' (default = 'add')
// PathType: 'user' or 'system' (default = 'user')
// Dir: semicolon-delimited list of directories to add or remove
// Returns False only when a registry update fails
// (NOTE: Do not enclose path names in quotes!)
Function UpdatePath(AddOrRemove, PathType, Dir: String): Boolean;
  Var
    AddToPath: Boolean;
    RegRoot, I: Integer;
    RegPath, Path, NewPath: String;
    DirArray: TArrayOfString;
  Begin
  Result := True;
  AddToPath := CompareText(AddOrRemove, 'remove') <> 0;
  If CompareText(PathType, 'system') = 0 Then
    Begin
    RegRoot := HKEY_LOCAL_MACHINE;
    RegPath := 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment';
    End
  Else
    Begin
    RegRoot := HKEY_CURRENT_USER;
    RegPath := 'Environment';
    End;
  SplitPathString(Dir, DirArray);
  For I := 0 To GetArrayLength(DirArray) - 1 Do
    Begin
    If Trim(DirArray[I]) = '' Then Continue;
    Path := '';
    RegQueryStringValue(RegRoot, RegPath, 'Path', Path);
    If AddToPath Then
      NewPath := AddDirToPathString(Path, DirArray[I])
    Else
      NewPath := RemoveDirFromPathString(Path, DirArray[I]);
    If NewPath <> Path Then
      Begin
      Result := RegWriteExpandStringValue(RegRoot, RegPath, 'Path', NewPath);
      If Not Result Then Exit;
      End;
    End;
  End;

// Requires:
//   GetPathDirName() function
//   UpdatePath() function
// Used by:
//   CurStepChanged() function
//   CurUninstallStepChanged() function
Function ModifyPath(Const AddOrRemove: String): Boolean;
  Var
    Action, Context, DirName: String;
  Begin
  Result := True;
  If CompareText(AddOrRemove, 'remove') <> 0 Then
    Action := 'add'
  Else
    Action := 'remove';
  If IsAdminInstallMode() Then
    Context := 'system'
  Else
    Context := 'user';
  DirName := GetPathDirName();
  Result := UpdatePath(Action, Context, DirName);
  If Result Then
    Log(FmtMessage(CustomMessage('PathUpdateSuccessMessage'), [Context,Action,DirName]))
  Else
    Log(FmtMessage(CustomMessage('PathUpdateFailMessage'), [Context,Action,DirName]));
  End;

// Requires:
//   PathStringContainsDir() function
//   GetPathDirName() function
// Used by:
//   [Tasks] section
Function IsDirInPath(): Boolean;
  Var
    RegRoot: Integer;
    RegPath, Path: String;
  Begin
  Result := False;
  If IsAdminInstallMode() Then
    Begin
    RegRoot := HKEY_LOCAL_MACHINE;
    RegPath := 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment';
    End
  Else
    Begin
    RegRoot := HKEY_CURRENT_USER;
    RegPath := 'Environment';
    End;
  If RegQueryStringValue(RegRoot, RegPath, 'Path', Path) Then
    Result := PathStringContainsDir(Path, GetPathDirName());
  End;

// Requires:
//   PathIsModified global variable
//   ModifyPath() function
Procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
  Begin
  If CurUninstallStep = usUninstall Then
    Begin
    If PathIsModified Then ModifyPath('remove');
    End;
  End;

Function ShouldSkipPage(PageID: Integer): Boolean;
  Begin
  Result := False;
  If PageID = wpSelectComponents Then
    Begin
    Result := (Not IsAdminInstallMode()) Or
      (IsAdminInstallMode() And (GetPreviousData('Setup Type', '') = 'full'));
    End;
  End;

// Requires:
//   PathIsModified global variable
//   ModifyPathTaskName global variable
// IS removes and rewrites 'previous data' values at every reinstall, so at
// initialize time we cache whether modify path task had already been selected
// from a previous install
Procedure RegisterPreviousData(PreviousDataKey: Integer);
  Begin
  SetPreviousData(PreviousDataKey, 'Setup Type', WizardSetupType(False));
  // If task was previously or currently selected, write data again
  If PathIsModified Or WizardIsTaskSelected(ModifyPathTaskName) Then
    SetPreviousData(PreviousDataKey, 'Modify Path', 'true');
  End;

// Used by:
//   NextButtonClick() function
Function GetCygwinRootDir(): String;
  Begin
  Result := ExpandConstant('{app}');
  End;

// Requires:
//   WMIService global variable
// Used by:
//   GetCygwinRunningServices() function
// For a running Cygwin service, gets two-element output array:
// element 0 = service name, and element 1 = service display name
Procedure GetServiceNamesFromProcessId(Const ProcessId: DWORD; Var Names: TArrayOfString);
  Var
    WQLQuery: String;
    SWbemObjectSet, SWbemObject: Variant;
    I: Integer;
  Begin
  WQLQuery := Format('SELECT Name,DisplayName FROM Win32_Service'
    + ' WHERE ProcessID = %d', [ProcessId]);
  Try
    SWbemObjectSet := WMIService.ExecQuery(WQLQuery);
    If Not VarIsNull(SWbemObjectSet) And (SWbemObjectSet.Count > 0) Then
      Begin
      For I := 0 To SWbemObjectSet.Count - 1 Do
        Begin
        SWbemObject := SWbemObjectSet.ItemIndex(I);
        If Not VarIsNull(SWbemObject) Then
          Begin
          SetArrayLength(Names, 2);
          Names[0] := SWbemObject.Name;
          If SWbemObject.DisplayName <> '' Then
            Names[1] := SWbemObject.DisplayName
          Else
            Names[1] := Names[0];
          Break;
          End;
        End;
      End;
  Except
  End; //Try
  End;

// Used by:
//   GetRunningCygwinProcesses() function
//   StopRunningCygwinServices() function
//   NextButtonClick() function
// Requires:
//   WMIService global variable
//   GetServiceNamesFromProcessId() function
// Gets list of running Cygwin services (process is cygrunsrv.exe)
Function GetCygwinRunningServices(CygwinRootDir: String; Var Services: TCygwinServiceList): Integer;
  Var
    WQLQuery: String;
    SWbemObjectSet, SWbemObject: Variant;
    I: Integer;
    Names: TArrayOfString;
  Begin
  Result := 0;
  CygwinRootDir := AddBackslash(CygwinRootDir);
  StringChangeEx(CygwinRootDir, '\', '\\', True);
  WQLQuery := Format('SELECT ExecutablePath,Name,ProcessId FROM Win32_Process'
    + ' WHERE (ExecutablePath LIKE "%s%%") AND (NAME = "cygrunsrv.exe")', [CygwinRootDir]);
  Try
    SWbemObjectSet := WMIService.ExecQuery(WQLQuery);
    If (Not VarIsNull(SWbemObjectSet)) And (SWbemObjectSet.Count > 0) Then
      Begin
      SetArrayLength(Services, SWbemObjectSet.Count);
      For I := 0 To SWbemObjectSet.Count - 1 Do
        Begin
        SWbemObject := SWbemObjectSet.ItemIndex(I);
        If Not VarIsNull(SWbemObject) Then
          Begin
          Services[I].ProcessId := SWbemObject.ProcessId;
          GetServiceNamesFromProcessId(SWbemObject.ProcessId, Names);
          Services[I].Name := Names[0];
          Services[I].DisplayName := Names[1];
          Services[I].ExecutablePath := SWbemObject.ExecutablePath;
          Result := Result + 1;
          End
        Else
          Begin
          Services[I].ProcessId := 0;
          Services[I].Name := '';
          Services[I].DisplayName := '';
          Services[I].ExecutablePath := '';
          End;
        End;
      End;
  Except
    SetArrayLength(Services, 0);
  End; //Try
  End;

// Used by:
//   GetRunningCygwinProcesses() function
//   TerminateRunningCygwinProcesses() function
//   NextButtonClick() function
// Requires:
//   WMIService global variable
// Gets list of running Cygwin processes (except cygrunsrv.exe, which are
// assumed to be running services)
Function GetCygwinRunningProcesses(CygwinRootDir: String; Var Processes: TCygwinProcessList): Integer;
  Var
    WQLQuery: String;
    SWbemObjectSet, SWbemObject: Variant;
    I: Integer;
  Begin
  Result := 0;
  CygwinRootDir := AddBackslash(CygwinRootDir);
  StringChangeEx(CygwinRootDir, '\', '\\', True);
  WQLQuery := Format('SELECT ExecutablePath,Name,ProcessId FROM Win32_Process'
    + ' WHERE (ExecutablePath LIKE "%s%%") AND (Name <> "cygrunsrv.exe")', [CygwinRootDir]);
  Try
    SWbemObjectSet := WMIService.ExecQuery(WQLQuery);
    If (Not VarIsNull(SWbemObjectSet)) And (SWbemObjectSet.Count > 0) Then
      Begin
      SetArrayLength(Processes, SWbemObjectSet.Count);
      For I := 0 To SWbemObjectSet.Count - 1 Do
        Begin
        SWbemObject := SWbemObjectSet.ItemIndex(I);
        If Not VarIsNull(SWbemObject) Then
          Begin
          Processes[I].ProcessId := SWbemObject.ProcessId;
          Processes[I].Name := SWbemObject.Name;
          Processes[I].ExecutablePath := SWbemObject.ExecutablePath;
          Result := Result + 1;
          End
        Else
          Begin
          Processes[I].ProcessId := 0;
          Processes[I].Name := ''
          Processes[I].ExecutablePath := '';
          End;
        End;
      End;
  Except
    SetArrayLength(Processes, 0);
  End; //Try
  End;

// Used by:
//   GetRunningCygwinProcesses() function
// Returns true if the string array contains an item (not case-sensitive)
Function ArrayContainsString(Var Arr: TArrayOfString; Const Item: String): Boolean;
  Var
    I: Integer;
  Begin
  Result := False;
  For I := 0 To GetArrayLength(Arr) - 1 Do
    Begin
    Result := CompareText(Arr[I], Item) = 0;
    If Result Then Exit;
    End;
  End;

// Requires:
//   GetCygwinRunningServices() function
//   GetCygwinRunningProcesses() function
//   ArrayContainsString() function
// Returns a new-line delimited string containing running Cygwin processes;
// empty return value means 'no Cygwin processes running'
Function GetRunningCygwinProcesses(CygwinRootDir: String): String;
  Var
    ServiceCount, ProcessCount, I, J, MaxOutput: Integer;
    Services: TCygwinServiceList;
    Processes: TCygwinProcessList;
    Output: TArrayOfString;
  Begin
  Result := '';
  ServiceCount := GetCygwinRunningServices(CygwinRootDir, Services);
  ProcessCount := GetCygwinRunningProcesses(CygwinRootDir, Processes);
  If ServiceCount + ProcessCount = 0 Then Exit;
  SetArrayLength(Output, ServiceCount + ProcessCount);
  For I := 0 To ServiceCount - 1 Do
    Output[I] := Services[I].DisplayName;
  J := I;
  For I := 0 To ProcessCount - 1 Do
    If Not ArrayContainsString(Output, Processes[I].Name) Then
      Begin
      Output[J] := Processes[I].Name;
      J := J + 1;
      End;
  MaxOutput := 20;
  If GetArrayLength(Output) >= MaxOutput Then
    Begin
    J := MaxOutput;
    Output[MaxOutput - 1] := '...';
    End
  Else
    J := GetArrayLength(Output);
  For I := 0 To J - 1 Do
    If Output[I] <> '' Then
      If Result = '' Then
        Result := Output[I]
      Else
        Result := Result + #10 + Output[I];
  End;

// Requires:
//   GetCygwinRunningServices() function
// Used by:
//   NextButtonClick() function
// Stops running Cygwin services using 'net stop'; returns true if all were
// stopped
Function StopRunningCygwinServices(CygwinRootDir: String): Boolean;
  Var
    Count, I, ResultCode: Integer;
    Services: TCygwinServiceList;
    Command, Parameters: String;
  Begin
  Result := False;
  Count := GetCygwinRunningServices(CygwinRootDir, Services);
  If Count > 0 Then
    Begin
    Command := ExpandConstant('{sys}\net.exe');
    For I := 0 To Count - 1 Do
      Begin
      Parameters := Format('stop "%s"', [Services[I].Name]);
      Log(FmtMessage(CustomMessage('RunCommandMessage'), [Command,Parameters]));
      Exec(Command, Parameters, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
      End;
    Result := GetCygwinRunningServices(CygwinRootDir, Services) = 0;
    End;
  End;

// Requires:
//   GetCygwinRunningProcesses() function
// Used by:
//   NextButtonClick() function
// Terminates running cygwin processes using 'taskkill'; returns true if all
// were terminated
Function TerminateRunningCygwinProcesses(CygwinRootDir: String): Boolean;
  Var
    Count, I, ResultCode: Integer;
    Processes: TCygwinProcessList;
    Command, Parameters: String;
  Begin
  Result := False;
  Count := GetCygwinRunningProcesses(CygwinRootDir, Processes);
  If Count > 0 Then
    Begin
    Command := ExpandConstant('{sys}\taskkill.exe');
    Parameters := ' ';
    For I := 0 To Count - 1 Do
      Parameters := Parameters + Format('/PID %d ', [Processes[I].ProcessId]);
    Parameters := Parameters + '/F';
    Log(FmtMessage(CustomMessage('RunCommandMessage'), [Command,Parameters]));
    Exec(Command, Parameters, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Result := GetCygwinRunningProcesses(CygwinRootDir, Processes) = 0;
    End;
  End;

// Used by:
//   CurStepChanged() procedure
// Starts the services named in the list
Function StartCygwinServices(Var Services: TCygwinServiceList): Boolean;
  Var
    Count, I, NumStarted, ResultCode: Integer;
    Command, Parameters: String;
  Begin
  Result := False;
  Count := GetArrayLength(Services);
  If Count > 0 Then
    Begin
    Command := ExpandConstant('{sys}\net.exe');
    NumStarted := 0;
    For I := 0 To Count - 1 Do
      Begin
      Parameters := Format('start "%s"', [Services[I].Name]);
      Log(FmtMessage(CustomMessage('RunCommandMessage'), [Command,Parameters]));
      If Exec(Command, Parameters, '', SW_HIDE, ewWaitUntilTerminated, ResultCode) And (ResultCode = 0) Then
        NumStarted := NumStarted + 1;
      End;
    Result := NumStarted = Count;
    End;
  End;

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
Function NextButtonClick(CurPageID: Integer): Boolean;
  Var
    ProcList: String;
    Count: Integer;
    Processes: TCygwinProcessList;
  Begin
  Result := True;
  If CurPageID = wpReady Then
    Begin
    ProcList := GetRunningCygwinProcesses(GetCygwinRootDir());
    Result := ProcList = '';
    If Not Result Then
      Begin
      Log(CustomMessage('ApplicationsRunningLogMessage'));
      Result := ParamStrExists('/closeapplications') Or ParamStrExists('/forcecloseapplications');
      If Not Result Then
        Result := SuppressibleTaskDialogMsgBox(CustomMessage('ApplicationsRunningInstructionMessage'),
          FmtMessage(CustomMessage('ApplicationsRunningTextMessage'),[ProcList]),
          mbCriticalError,
          MB_YESNO, [CustomMessage('CloseApplicationsMessage'),CustomMessage('DontCloseApplicationsMessage')],
          0,
          IDNO) = IDYES;
      If Result Then
        Begin
        AppProgressPage.SetText(CustomMessage('AppProgressPageStoppingMessage'), '');
        AppProgressPage.SetProgress(0, 0);
        AppProgressPage.Show();
        Try
          AppProgressPage.SetProgress(1, 3);
          // Cache running service(s) in global variable for later restart
          Count := GetCygwinRunningServices(GetCygwinRootDir(), RunningServices);
          Result := (Count = 0) Or (StopRunningCygwinServices(GetCygwinRootDir()));
          AppProgressPage.SetProgress(2, 3);
          If Result Then
            Begin
            Count := GetCygwinRunningProcesses(GetCygwinRootDir(), Processes);
            Result := (Count = 0) Or (TerminateRunningCygwinProcesses(GetCygwinRootDir()));
            End;
          AppProgressPage.SetProgress(3, 3);
          If Result Then
            Log(CustomMessage('ClosedApplicationsMessage'))
          Else
            Begin
            Log(SetupMessage(msgErrorCloseApplications));
            SuppressibleMsgBox(SetupMessage(msgErrorCloseApplications), mbCriticalError, MB_OK, IDOK);
            End;
        Finally
          AppProgressPage.Hide();
        End; //Try
        End
      Else
        Log(CustomMessage('ApplicationsStillRunningMessage'));
      End;
    End;
  End;

// Requires:
//   AppProgressPage global variable
//   RunningServices global variable
//   StartCygwinServices() function
Procedure CurStepChanged(CurStep: TSetupStep);
  Begin
  If CurStep = ssPostInstall Then
    Begin
    If WizardIsTaskSelected(ModifyPathTaskName) Then
      ModifyPath('add');
    If GetArrayLength(RunningServices) > 0 Then
      Begin
      AppProgressPage.SetText(CustomMessage('AppProgressPageStartingMessage'), '');
      AppProgressPage.SetProgress(0, 0);
      AppProgressPage.Show();
      Try
        AppProgressPage.SetProgress(1, 2);
        If StartCygwinServices(RunningServices) Then
          Log(CustomMessage('StartedServicesMessage'));
        AppProgressPage.SetProgress(2, 2);
      Finally
        AppProgressPage.Hide();
      End; //Try
      End;
    End;
  End;
