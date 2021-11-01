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
MinVersion=6.1sp1
OutputBaseFilename={#SetupName}-{#SetupVersion}
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
WizardSmallImageFile=OpenSSH-55x55.bmp
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
Type: files; Name: "{app}\version.ini"
Type: filesandordirs; Name: "{app}\etc\defaults\*"
Type: filesandordirs; Name: "{app}\usr\share\*"
Type: filesandordirs; Name: "{app}\usr\src\*"

[UninstallDelete]
Type: files; Name: "{app}\version.ini"

[Files]
; PathMgr.dll (deleted manually at DeinitializeUninstall)
Source: "bin\PathMgr.dll"; DestDir: "{app}\bin"; Components: server; Flags: uninsneveruninstall
; UninsIS.dll - support uninstalling existing package when installing
Source: "bin\UninsIS.dll"; Flags: dontcopy
; cygwin x64 - /bin
Source: "bin-x64\*.dll";                     DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\cygcheck.exe";              DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\cygpath.exe";               DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\cygrunsrv.exe";             DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\cygstart.exe";              DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\editrights.exe";            DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\false.exe";                 DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\getent.exe";                DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\id.exe";                    DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\less.exe";                  DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\mintty.exe";                DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\mkgroup.exe";               DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\mkpasswd.exe";              DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\mount.exe";                 DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\nano.exe";                  DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\passwd.exe";                DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\rebase.exe";                DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\rsync.exe";                 DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\scp.exe";                   DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\sftp.exe";                  DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\ssh-add.exe";               DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\ssh-agent.exe";             DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\ssh-keygen.exe";            DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\ssh-keyscan.exe";           DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\ssh-pageant.exe";           DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\ssh.exe";                   DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\touch.exe";                 DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\true.exe";                  DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\umount.exe";                DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\uname.exe";                 DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\unzip.exe";                 DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\vi.exe";                    DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\xz.exe";                    DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\zip.exe";                   DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x64\cygwin-console-helper.exe"; DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: server;        Flags: ignoreversion
Source: "bin-x64\dash.exe";                  DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: server;        Flags: ignoreversion
Source: "bin-x64\tty.exe";                   DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: server;        Flags: ignoreversion
; supplemental x64 - /bin
Source: "binsupp-x64\startps.exe"; DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "binsupp-x64\posh.exe";    DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: server;        Flags: ignoreversion
Source: "binsupp-x64\winpty*";     DestDir: "{app}\bin"; Check: Is64BitInstallMode(); Components: server;        Flags: ignoreversion
; x64 - /usr/sbin
Source: "usr\sbin-x64\cygserver.exe";         DestDir: "{app}\usr\sbin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "usr\sbin-x64\ssh-keysign.exe";       DestDir: "{app}\usr\sbin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "usr\sbin-x64\ssh-pkcs11-helper.exe"; DestDir: "{app}\usr\sbin"; Check: Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "usr\sbin-x64\sftp-server.exe";       DestDir: "{app}\usr\sbin"; Check: Is64BitInstallMode(); Components: server;        Flags: ignoreversion
Source: "usr\sbin-x64\sshd.exe";              DestDir: "{app}\usr\sbin"; Check: Is64BitInstallMode(); Components: server;        Flags: ignoreversion
; cygwin x86 - /bin
Source: "bin-x86\*.dll";                     DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion solidbreak
Source: "bin-x86\cygcheck.exe";              DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\cygpath.exe";               DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\cygrunsrv.exe";             DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\cygstart.exe";              DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\editrights.exe";            DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\false.exe";                 DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\getent.exe";                DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\id.exe";                    DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\less.exe";                  DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\mintty.exe";                DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\mkgroup.exe";               DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\mkpasswd.exe";              DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\mount.exe";                 DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\nano.exe";                  DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\passwd.exe";                DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\rebase.exe";                DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\rsync.exe";                 DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\scp.exe";                   DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\sftp.exe";                  DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\ssh-add.exe";               DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\ssh-agent.exe";             DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\ssh-keygen.exe";            DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\ssh-keyscan.exe";           DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\ssh-pageant.exe";           DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\ssh.exe";                   DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\touch.exe";                 DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\true.exe";                  DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\umount.exe";                DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\uname.exe";                 DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\unzip.exe";                 DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\vi.exe";                    DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\xz.exe";                    DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\zip.exe";                   DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "bin-x86\cygwin-console-helper.exe"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: server;        Flags: ignoreversion
Source: "bin-x86\dash.exe";                  DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: server;        Flags: ignoreversion
Source: "bin-x86\tty.exe";                   DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: server;        Flags: ignoreversion
; supplemental x86 - /bin
Source: "binsupp-x86\startps.exe"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "binsupp-x86\posh.exe";    DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: server;        Flags: ignoreversion
Source: "binsupp-x86\winpty*";     DestDir: "{app}\bin"; Check: not Is64BitInstallMode(); Components: server;        Flags: ignoreversion
; x86 - /usr/sbin
Source: "usr\sbin-x86\cygserver.exe";         DestDir: "{app}\usr\sbin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "usr\sbin-x86\ssh-keysign.exe";       DestDir: "{app}\usr\sbin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "usr\sbin-x86\ssh-pkcs11-helper.exe"; DestDir: "{app}\usr\sbin"; Check: not Is64BitInstallMode(); Components: client server; Flags: ignoreversion
Source: "usr\sbin-x86\sftp-server.exe";       DestDir: "{app}\usr\sbin"; Check: not Is64BitInstallMode(); Components: server;        Flags: ignoreversion
Source: "usr\sbin-x86\sshd.exe";              DestDir: "{app}\usr\sbin"; Check: not Is64BitInstallMode(); Components: server;        Flags: ignoreversion
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
Source: "etc\nanorc";         DestDir: "{app}\etc"; Components: client server; Flags: onlyifdoesntexist uninsneveruninstall
Source: "etc\ssh_config";     DestDir: "{app}\etc"; Components: client server; Flags: onlyifdoesntexist uninsneveruninstall
Source: "etc\virc";           DestDir: "{app}\etc"; Components: client server; Flags: onlyifdoesntexist uninsneveruninstall
Source: "etc\banner.txt";     DestDir: "{app}\etc"; Components: server;        Flags: onlyifdoesntexist uninsneveruninstall
Source: "etc\passwd";         DestDir: "{app}\etc"; Components: server;        Flags: onlyifdoesntexist uninsneveruninstall
Source: "etc\profile";        DestDir: "{app}\etc"; Components: server;        Flags: onlyifdoesntexist uninsneveruninstall
Source: "etc\sshd_config";    DestDir: "{app}\etc"; Components: server;        Flags: onlyifdoesntexist uninsneveruninstall
Source: "etc\moduli";         DestDir: "{app}\etc"; Components: server
; shared - /etc/defaults/etc
Source: "etc\defaults\etc\cygserver.conf"; DestDir: "{app}\etc\defaults\etc"; Components: client server
Source: "etc\defaults\etc\nanorc";         DestDir: "{app}\etc\defaults\etc"; Components: client server
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
; source code download
Source: "{tmp}\{#SourceArchiveFileName}"; DestDir: "{app}\usr\src"; Flags: external skipifsourcedoesntexist; Tasks: downloadsource

[Dirs]
Name: "{app}\tmp";       Components: client server
Name: "{app}\var\empty"; Components: server

[Icons]
Name: "{group}\{cm:IconsUserGuideName}"; Filename: "{app}\CygSSH-UserGuide.chm"; Comment: "{cm:IconsUserGuideComment}"

[INI]
Filename: "{app}\version.ini"; Section: "Version"; Key: "Version"; String: "{#AppFullVersion}"

[Tasks]
Name: startservice;   Description: "{cm:TasksStartServiceDescription}"; Components: server; Check: not ServiceExists('{#ServiceName}')
Name: modifypath;     Description: "{cm:TasksModifyPathDescription,{code:GetSystemOrUserPath}}"; Check: not IsDirInPath(ExpandConstant('{app}\bin'))
Name: s4ulogonfix;    Description: "{cm:TasksS4ULogonFixDescription}"; Components: server; Flags: unchecked; OnlyBelowVersion: 6.3
Name: resetconfig;    Description: "{cm:TasksResetConfigDescription}"; Flags: checkedonce unchecked; Check: FileExists(ExpandConstant('{app}\etc\ssh_config')) or FileExists(ExpandConstant('{app}\etc\sshd_config'))
Name: downloadsource; Description: "{cm:TasksDownloadSourceDescription}"; Flags: checkedonce unchecked

[Run]
; Add 2 ACEs to /tmp -
; Type   Principal  Access                 Applies to
; -----  ---------  ---------------------  ---------------------------------
; Allow  Users      Modify                 Subfolders and files only
; Allow  Users      Read, write & execute  This folder, subfolders and files
; --------------------------------------------------------------------------
Filename: "{sys}\icacls.exe"; \
  Parameters: """{app}\tmp"" /grant ""*S-1-5-32-545:(OI)(CI)(IO)M"" ""*S-1-5-32-545:(OI)(CI)(RX,W)"" /T"; \
  StatusMsg: "{cm:RunSetPermissionsStatusMsg}"; \
  Components: client server; \
  Flags: runhidden

; Replace DACL for /users -
; Type   Principal       Access          Applies to
; -----  --------------  --------------  ---------------------------------
; Allow  Users           Read & execute  This folder and files[1]
; Allow  SYSTEM          Full control    This folder, subfolders and files
; Allow  Administrators  Full control    This folder, subfolders and files
; ------------------------------------------------------------------------
; [1] Only apply these permissions to objects and/or containers within
;     this container
Filename: "{sys}\icacls.exe"; \
  Parameters: """{app}\users"" /inheritance:r /grant ""*S-1-5-32-545:(OI)(NP)RX"" ""*S-1-5-18:(OI)(CI)F"" ""*S-1-5-32-544:(OI)(CI)F"""; \
  StatusMsg: "{cm:RunSetPermissionsStatusMsg}"; \
  Components: client server; \
  Flags: runhidden

; Configure fstab
Filename: "{app}\bin\startps.exe"; \
  Parameters: "-D --noninteractive --quiet --wait --windowstyle=hidden ""{app}\bin\Set-FstabConfig.ps1"""; \
  StatusMsg: "{cm:RunConfigureFstabStatusMsg}"; \
  Components: client server

; Create SSH host keys
Filename: "{app}\bin\startps.exe"; \
  Parameters: "-D --noninteractive --quiet --wait --windowstyle=hidden ""{app}\bin\Set-SSHHostKey.ps1"""; \
  StatusMsg: "{cm:RunConfigureSSHHostKeysStatusMsg}"; \
  Components: server

; Configure local access group and sshd_config file
Filename: "{app}\bin\startps.exe"; \
  Parameters: "-D --noninteractive --quiet --wait --windowstyle=hidden ""{app}\bin\Set-SSHGroup.ps1"" -- -NoConfirm"; \
  StatusMsg: "{cm:RunConfigureLocalAccessGroupStatusMsg}"; \
  Components: server

; S4U local account logon fix - OS older than 6.3 (Windows 8.1/Server 2012 R2)
Filename: "{app}\bin\startps.exe"; \
  Parameters: "-D --noninteractive --quiet --wait --windowstyle=hidden ""{app}\bin\Set-S4ULogonFix.ps1"" -- -Enable -NoConfirm"; \
  StatusMsg: "{cm:RunConfigureMsV1_0S4ULogonFixStatusMsg}"; \
  Components: server; \
  Tasks: s4ulogonfix

; Install service
Filename: "{app}\bin\startps.exe"; \
  Parameters: "-D --noninteractive --quiet --wait --windowstyle=hidden ""{app}\bin\Set-SSHService.ps1"" -- -Install -NoConfirm"; \
  StatusMsg: "{cm:RunInstallServiceStatusMsg}"; \
  Components: server; \
  Check: not ServiceExists('{#ServiceName}')

; Start service
Filename: "{app}\bin\startps.exe"; \
  Parameters: "-D --noninteractive --quiet --wait --windowstyle=hidden ""{app}\bin\Set-SSHService.ps1"" -- -Start -NoConfirm"; \
  StatusMsg: "{cm:RunStartServiceStatusMsg}"; \
  Components: server; \
  Tasks: startservice

[UninstallRun]
Filename: "{app}\bin\startps.exe"; \
  Parameters: "-D --noninteractive --quiet --wait --windowstyle=hidden ""{app}\bin\Set-SSHService.ps1"" -- -Uninstall -NoConfirm"; \
  RunOnceId: "uninstallservice"; \
  Components: server

[Code]

// Code support:
// * Add to Path or remove from Path (PathMgr.dll)
// * Support automatic uninstall with /FORCEUNINSTALL parameter (UninsIS.dll)
// * Enable S4ULogonFix by default when OS < v6.3, not domain member, and
//   interactive install
// * Executable detection: Automatic service stop/process termination and
//   service restart (Windows Restart Manager does not work correctly with
//   Cygwin services and processes); uses WMI and progress page
// * Download of source code

const
  MODIFY_PATH_TASK_NAME = 'modifypath';
  SC_MANAGER_CONNECT    = 1;
  SERVICE_QUERY_STATUS  = 4;

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
  DownloadPage: TDownloadWizardPage;
  AppProgressPage: TOutputProgressWizardPage;
  PathIsModified, S4UTaskDefaultChanged: Boolean;
  SWbemLocator, WMIService: Variant;
  RunningServices: TCygwinServiceList;

// Windows API functions
// netapi32.dll functions for setup only
function NetGetJoinInformation(lpServer: string; var lpNameBuffer: DWORD; var BufferType: DWORD): DWORD;
  external 'NetGetJoinInformation@netapi32.dll stdcall setuponly';
function NetApiBufferFree(Buffer: DWORD): DWORD;
  external 'NetApiBufferFree@netapi32.dll stdcall setuponly';
// advapi32.dll functions for service info
function OpenSCManager(lpMachineName: string; lpDatabaseName: string; dwDesiredAccess: DWORD): TSCHandle;
  external 'OpenSCManagerW@advapi32.dll stdcall';
function OpenService(hSCManager: TSCHandle; lpServiceName: string; dwDesiredAccess: DWORD): TSCHandle;
  external 'OpenServiceW@advapi32.dll stdcall';
function QueryServiceStatus(hService: TSCHandle; out lpServiceStatus: TServiceStatus): BOOL;
  external 'QueryServiceStatus@advapi32.dll stdcall';
function CloseServiceHandle(hSCObject: TSCHandle): BOOL;
  external 'CloseServiceHandle@advapi32.dll stdcall';

// PathMgr.dll functions - https://github.com/Bill-Stewart/PathMgr/
// Import AddDirToPath() and IsDirInPath() at setup time
function DLLAddDirToPath(DirName: string; PathType, AddType: DWORD): DWORD;
  external 'AddDirToPath@files:PathMgr.dll stdcall setuponly';
function DLLIsDirInPath(DirName: string; PathType: DWORD; var FindType: DWORD): DWORD;
  external 'IsDirInPath@files:PathMgr.dll stdcall setuponly';
// Import RemoveDirFromPath() at uninstall time
function DLLRemoveDirFromPath(DirName: string; PathType: DWORD): DWORD;
  external 'RemoveDirFromPath@{app}\bin\PathMgr.dll stdcall uninstallonly';

// UninsIS.dll functions - https://github.com/Bill-Stewart/UninsIS/
function DLLIsISPackageInstalled(AppId: string; Is64BitInstallMode, IsAdminInstallMode: DWORD): DWORD;
  external 'IsISPackageInstalled@files:UninsIS.dll stdcall setuponly';
function DLLCompareISPackageVersion(AppId, InstallingVersion: string;
  Is64BitInstallMode, IsAdminInstallMode: DWORD): LongInt;
  external 'CompareISPackageVersion@files:UninsIS.dll stdcall setuponly';
function DLLUninstallISPackage(AppId: string; Is64BitInstallMode, IsAdminInstallMode: DWORD): DWORD;
  external 'UninstallISPackage@files:UninsIS.dll stdcall setuponly';

// Wrapper for PathMgr.dll AddDirToPath() function
function AddDirToPath(const DirName: string): DWORD;
var
  PathType: DWORD;
  PathTypeName: string;
begin
  if IsAdminInstallMode() then
  begin
    PathType := 0;
    PathTypeName := 'system';
  end
  else
  begin
    PathType := 1;
    PathTypeName := 'user';
  end;
  // 3rd parameter 0 = append to end of path, 1 = add to beginning of path
  result := DLLAddDirToPath(DirName, PathType, 1);
  if result = 0 then
    Log(FmtMessage(CustomMessage('PathAddSuccessMessage'), [DirName, PathTypeName]))
  else
    Log(FmtMessage(CustomMessage('PathAddFailMessage'), [DirName, PathTypeName, IntToStr(result)]));
end;

// Wrapper for PathMgr.dll IsDirInPath() function
function IsDirInPath(const DirName: string): Boolean;
var
  PathType, FindType: DWORD;
begin
  if IsAdminInstallMode() then
    PathType := 0
  else
    PathType := 1;
  result := DLLIsDirInPath(DirName, PathType, FindType) = 0;
end;

// Wrapper for PathMgr.dll RemoveDirFromPath() function
function RemoveDirFromPath(const DirName: string): DWORD;
var
  PathType: DWORD;
  PathTypeName: string;
begin
  if IsAdminInstallMode() then
  begin
    PathType := 0;
    PathTypeName := 'system';
  end
  else
  begin
    PathType := 1;
    PathTypeName := 'user';
  end;
  result := DLLRemoveDirFromPath(DirName, PathType);
  if result = 0 then
    Log(FmtMessage(CustomMessage('PathRemoveSuccessMessage'), [DirName, PathTypeName]))
  else
    Log(FmtMessage(CustomMessage('PathRemoveFailMessage'), [DirName, PathTypeName, IntToStr(result)]));
end;

// Wrapper for UninsIS.dll IsISPackageInstalled() function
function IsISPackageInstalled(): Boolean;
begin
  result := DLLIsISPackageInstalled('{#AppGUID}', DWORD(Is64BitInstallMode()),
    DWORD(IsAdminInstallMode())) = 1;
  if result then
    Log(CustomMessage('PackageDetectedLogMessage'))
  else
    Log(CustomMessage('PackageNotDetectedLogMessage'));
end;

// Wrapper for UninsIS.dll CompareISPackageVersion() function
function CompareISPackageVersion(): LongInt;
begin
  result := DLLCompareISPackageVersion('{#AppGUID}', '{#AppFullVersion}',
    DWORD(Is64BitInstallMode()), DWORD(IsAdminInstallMode()));
  if result < 0 then
    Log(FmtMessage(CustomMessage('PackageVersionLessLogMessage'), ['{#AppFullVersion}']))
  else if result = 0 then
    Log(FmtMessage(CustomMessage('PackageVersionEqualLogMessage'), ['{#AppFullVersion}']))
  else
    Log(FmtMessage(CustomMessage('PackageVersionGreaterLogMessage'), ['{#AppFullVersion}']));
end;

// Wrapper for UninsIS.dll UninstallISPackage() function
function UninstallISPackage(): DWORD;
begin
  result := DLLUninstallISPackage('{#AppGUID}', DWORD(Is64BitInstallMode()),
    DWORD(IsAdminInstallMode()));
  Log(FmtMessage(CustomMessage('PackageUninstallStatusLogMessage'), [IntToStr(result)]));
end;

function ParamStrExists(const Param: string): Boolean;
var
  I: Integer;
begin
  for I := 1 to ParamCount do
  begin
    result := CompareText(Param, ParamStr(I)) = 0;
    if result then
      exit;
  end;
end;

function ServiceExists(ServiceName: string): Boolean;
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

function InitializeSetup(): Boolean;
begin
  result := true;
  // Was modifypath task selected during a previous install?
  PathIsModified := GetPreviousData(MODIFY_PATH_TASK_NAME, '') = 'true';
  // S4U task not visited yet
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

function OnDownloadProgress(const Url, FileName: string; const Progress, ProgressMax: Int64): Boolean;
begin
  result := true;
  if Progress = ProgressMax then
    Log(FmtMessage(CustomMessage('DownloadPageDownloadCompleteLogMessage'), [FileName]));
end;

procedure InitializeWizard();
begin
  DownloadPage := CreateDownloadPage(SetupMessage(msgWizardPreparing),
    SetupMessage(msgPreparingDesc), @OnDownloadProgress);
  AppProgressPage := CreateOutputProgressPage(SetupMessage(msgWizardInstalling),
    FmtMessage(CustomMessage('AppProgressPageInstallingCaption'), [ExpandConstant('{#SetupSetting("AppName")}')]));
end;

function InitializeUninstall(): Boolean;
begin
  result := true;
  // Was modifypath task selected during a previous install?
  PathIsModified := GetPreviousData(MODIFY_PATH_TASK_NAME, '') = 'true';
end;

function IsDomainMember(): Boolean;
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

procedure CurPageChanged(PageID: Integer);
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
        if not IsDomainMember() then
          WizardSelectTasks('s4ulogonfix');
        S4UTaskDefaultChanged := true;
      end;
    end;
  end;
end;

function GetSystemOrUserPath(Param: string): string;
begin
  if IsAdminInstallMode() then
    result := CustomMessage('PathTypeSystemMessage')
  else
    result := CustomMessage('PathTypeUserMessage');
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
  begin
    if PathIsModified then
      RemoveDirFromPath(ExpandConstant('{app}\bin'));
  end;
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  result := false;
  if PageID = wpSelectComponents then
  begin
    // Skip components page if not admin or if setup type was full for a
    // previous install
    result := (not IsAdminInstallMode()) or
      (IsAdminInstallMode() and (GetPreviousData('Setup Type', '') = 'full'));
  end;
end;

procedure RegisterPreviousData(PreviousDataKey: Integer);
begin
  // Note: IS removes and rewrites 'previous data' values at every reinstall
  SetPreviousData(PreviousDataKey, 'Setup Type', WizardSetupType(false));
  // Store previous or current path task selection as custom user setting
  if PathIsModified or WizardIsTaskSelected(MODIFY_PATH_TASK_NAME) then
    SetPreviousData(PreviousDataKey, MODIFY_PATH_TASK_NAME, 'true');
end;

function GetCygwinRootDir(): string;
begin
  result := ExpandConstant('{app}');
end;

// For a running Cygwin service, gets two-element output array:
// element 0 = service name, and element 1 = service display name
procedure GetServiceNamesFromProcessId(const ProcessId: DWORD; var Names: TArrayOfString);
var
  WQLQuery: string;
  SWbemObjectSet, SWbemObject: Variant;
  I: Integer;
begin
  WQLQuery := Format('SELECT Name,DisplayName FROM Win32_Service' +
    ' WHERE ProcessID = %d', [ProcessId]);
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

// Gets list of running Cygwin services (process is cygrunsrv.exe)
function GetCygwinRunningServices(CygwinRootDir: string; var Services: TCygwinServiceList): Integer;
var
  WQLQuery: string;
  SWbemObjectSet, SWbemObject: Variant;
  I: Integer;
  Names: TArrayOfString;
begin
  result := 0;
  CygwinRootDir := AddBackslash(CygwinRootDir);
  StringChangeEx(CygwinRootDir, '\', '\\', true);
  WQLQuery := Format('SELECT ExecutablePath,Name,ProcessId FROM Win32_Process' +
    ' WHERE (ExecutablePath LIKE "%s%%") AND (NAME = "cygrunsrv.exe")', [CygwinRootDir]);
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

// Gets list of running Cygwin processes (except cygrunsrv.exe, which are
// assumed to be running services)
function GetCygwinRunningProcesses(CygwinRootDir: string; var Processes: TCygwinProcessList): Integer;
var
  WQLQuery: string;
  SWbemObjectSet, SWbemObject: Variant;
  I: Integer;
begin
  result := 0;
  CygwinRootDir := AddBackslash(CygwinRootDir);
  StringChangeEx(CygwinRootDir, '\', '\\', true);
  WQLQuery := Format('SELECT ExecutablePath,Name,ProcessId FROM Win32_Process' +
    ' WHERE (ExecutablePath LIKE "%s%%") AND (Name <> "cygrunsrv.exe")', [CygwinRootDir]);
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
          Processes[I].Name := '';
          Processes[I].ExecutablePath := '';
        end;
      end;
    end;
  except
    SetArrayLength(Processes, 0);
  end; //try
end;

// Returns true if the string array contains an item (not case-sensitive)
function ArrayContainsString(var Arr: TArrayOfString; const Item: string): Boolean;
var
  I: Integer;
begin
  result := false;
  for I := 0 to GetArrayLength(Arr) - 1 do
  begin
    result := CompareText(Arr[I], Item) = 0;
    if result then
      exit;
  end;
end;

// Returns a newline-delimited string containing running Cygwin processes;
// empty return value means 'no Cygwin processes running'
function GetRunningCygwinProcesses(CygwinRootDir: string): string;
var
  ServiceCount, ProcessCount, I, J, MaxOutput: Integer;
  Services: TCygwinServiceList;
  Processes: TCygwinProcessList;
  Output: TArrayOfString;
begin
  result := '';
  ServiceCount := GetCygwinRunningServices(CygwinRootDir, Services);
  ProcessCount := GetCygwinRunningProcesses(CygwinRootDir, Processes);
  if ServiceCount + ProcessCount = 0 then
    exit;
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

// Stops running Cygwin services using 'net stop'; returns true if all were
// stopped
function StopRunningCygwinServices(CygwinRootDir: string): Boolean;
var
  Count, I, ResultCode: Integer;
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
      Log(FmtMessage(CustomMessage('RunCommandMessage'), [Command, Parameters]));
      Exec(Command, Parameters, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    end;
    result := GetCygwinRunningServices(CygwinRootDir, Services) = 0;
  end;
end;

// Terminates running cygwin processes using 'taskkill'; returns true if all
// were terminated
function TerminateRunningCygwinProcesses(CygwinRootDir: string): Boolean;
var
  Count, I, ResultCode: Integer;
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
    Log(FmtMessage(CustomMessage('RunCommandMessage'), [Command, Parameters]));
    Exec(Command, Parameters, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    result := GetCygwinRunningProcesses(CygwinRootDir, Processes) = 0;
  end;
end;

// Starts the services named in the list
function StartCygwinServices(var Services: TCygwinServiceList): Boolean;
var
  Count, I, NumStarted, ResultCode: Integer;
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
      Log(FmtMessage(CustomMessage('RunCommandMessage'), [Command, Parameters]));
      if Exec(Command, Parameters, '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and
        (ResultCode = 0) then
        NumStarted := NumStarted + 1;
    end;
    result := NumStarted = Count;
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  result := true;
  if CurPageID = wpSelectTasks then
  begin
    if WizardIsTaskSelected('resetconfig') then
    begin
      result := SuppressibleMsgBox(CustomMessage('ResetConfigFileConfirmationMessage'),  // Text
        mbConfirmation,                                                                  // Typ
        MB_YESNO,                                                                        // Buttons
        IDYES) = IDYES;                                                                  // Default
    end;
  end
  else if CurPageID = wpReady then
  begin
    // Download source code if task selected
    if WizardIsTaskSelected('downloadsource') then
    begin
      DownloadPage.Clear();
      DownloadPage.Add('{#SourceArchiveURL}', '{#SourceArchiveFileName}', '');
      DownloadPage.Show();
      try
        DownloadPage.Download();
      except
        SuppressibleMsgBox(AddPeriod(GetExceptionMessage), mbCriticalError, MB_OK, IDOK);
      finally
        DownloadPage.Hide();
      end; // try
    end;
  end;
end;

function PrepareToInstall(var NeedsRestart: Boolean): string;
var
  Installed: Boolean;
  ProcList: string;
  OK: Boolean;
  Count: Integer;
  Processes: TCygwinProcessList;
begin
  result := '';
  Installed := IsISPackageInstalled();
  if Installed then
    CompareISPackageVersion();
  if ParamStrExists('/forceuninstall') and Installed then
    UninstallISPackage();
  // Get running Cygwin processes
  ProcList := GetRunningCygwinProcesses(GetCygwinRootDir());
  if ProcList <> '' then
  begin
    Log(CustomMessage('ApplicationsRunningLogMessage'));
    OK := ParamStrExists('/closeapplications') or
      ParamStrExists('/forcecloseapplications');
    if not OK then
      OK := SuppressibleTaskDialogMsgBox(CustomMessage('ApplicationsRunningInstructionMessage'),               // Instruction
        FmtMessage(CustomMessage('ApplicationsRunningTextMessage'), [ProcList]),                               // Text
        mbCriticalError,                                                                                       // Typ
        MB_YESNO, [CustomMessage('CloseApplicationsMessage'), CustomMessage('DontCloseApplicationsMessage')],  // Buttons, ButtonLabels
        0,                                                                                                     // ShieldButton
        IDNO) = idYes;                                                                                         // Default
    if OK then
    begin
      AppProgressPage.SetText(CustomMessage('AppProgressPageStoppingMessage'), '');
      AppProgressPage.SetProgress(0, 0);
      AppProgressPage.Show();
      try
        AppProgressPage.SetProgress(1, 3);
        // Cache running service(s) in global variable for later restart
        Count := GetCygwinRunningServices(GetCygwinRootDir(), RunningServices);
        OK := (Count = 0) or (StopRunningCygwinServices(GetCygwinRootDir()));
        AppProgressPage.SetProgress(2, 3);
        if OK then
        begin
          Count := GetCygwinRunningProcesses(GetCygwinRootDir(), Processes);
          OK := (Count = 0) or (TerminateRunningCygwinProcesses(GetCygwinRootDir()));
        end;
        AppProgressPage.SetProgress(3, 3);
        if OK then
          Log(CustomMessage('ClosedApplicationsMessage'))
        else
        begin
          Log(SetupMessage(msgErrorCloseApplications));
          SuppressibleMsgBox(SetupMessage(msgErrorCloseApplications),  // Text
            mbCriticalError,                                           // Typ
            MB_OK,                                                     // Buttons
            IDOK);                                                     // Default
        end;
      finally
        AppProgressPage.Hide();
      end; //try
    end
    else
      result := CustomMessage('ApplicationsStillRunningMessage');
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  FileList: TArrayOfString;
  I: Integer;
  DateTimeString, FileName, NewFileName: string;
begin
  if CurStep = ssInstall then
  begin
    if WizardIsTaskSelected('resetconfig') then
    begin
      DateTimeString := GetDateTimeString('yyyymmddhhnnss', '-', '-');
      SetArrayLength(FileList, 2);
      FileList[0] := 'ssh_config';
      FileList[1] := 'sshd_config';
      for I := 0 to GetArrayLength(FileList) - 1 do
      begin
        FileName := ExpandConstant('{app}\etc\') + FileList[I];
        if FileExists(FileName) then
        begin
          NewFileName := ExpandConstant('{app}\etc\') + FileList[I] + '-' + DateTimeString;
          if RenameFile(FileName, NewFileName) then
            Log(FmtMessage(CustomMessage('ResetConfigFileRenameSuccessMessage'), [FileName, NewFileName]))
          else
            Log(FmtMessage(CustomMessage('ResetConfigFileRenameFailMessage'), [FileName, NewFileName]));
        end;
      end;
    end;
  end
  else if CurStep = ssPostInstall then
  begin
    if PathIsModified or WizardIsTaskSelected(MODIFY_PATH_TASK_NAME) then
      AddDirToPath(ExpandConstant('{app}\bin'));
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

procedure DeinitializeUninstall();
var
  DLLFileName, DLLPath: string;
begin
  // Unload and delete PathMgr.dll and remove dir when uninstalling
  DLLFileName := ExpandConstant('{app}\bin\PathMgr.dll');
  UnloadDLL(DLLFileName);
  if DeleteFile(DLLFileName) then
    Log(FmtMessage(CustomMessage('DeleteFileSuccess'), [DLLFileName]))
  else
    Log(FmtMessage(CustomMessage('DeleteFileFail'), [DLLFileName]));
  DLLPath := ExtractFileDir(DLLFileName);
  if RemoveDir(DLLPath) then
    Log(FmtMessage(CustomMessage('RemoveDirSuccess'), [DLLPath]))
  else
    Log(FmtMessage(CustomMessage('RemoveDirFail'), [DLLPath]));
end;
