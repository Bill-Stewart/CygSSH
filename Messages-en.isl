#preproc ispp

; Cygwin-OpenSSH - Inno Setup messages file

#include AddBackslash(SourcePath) + "includes.iss"

[Messages]
SetupWindowTitle=Setup - %1 [{#AppFullVersion}]
WizardSelectComponents=Select Setup Type
SelectComponentsDesc=Which components should be installed?
SelectComponentsLabel2=Select the setup type you want to use. Click Next when you are ready to continue.
FinishedLabel=Setup has finished installing [name] on your computer.

[CustomMessages]

; Types
TypesFullDescription=Full installation (server and client files)
TypesClientDescription=Client installation (client files only)

; Components
ComponentsServerDescription=Server and client files
ComponentsClientDescription=Client files only

; Icons
IconsUserGuideName=User Guide
IconsUserGuideComment=Cygwin OpenSSH User Guide

; Tasks
TasksStartServiceDescription=Start OpenSSH server service
TasksModifyPathDescription=Add to %1
TasksS4ULogonFixDescription=Implement MsV1_0S4ULogon fix

; Run
RunSetPermissionsStatusMsg=Setting file system permissions...
RunConfigureFstabStatusMsg=Configuring fstab file...
RunConfigureSSHHostKeysStatusMsg=Configuring SSH host keys...
RunConfigureLocalAccessGroupStatusMsg=Configuring local access group...
RunConfigureMsV1_0S4ULogonFixStatusMsg=Configuring MsV1_0S4ULogon fix...
RunInstallServiceStatusMsg=Installing OpenSSH server service...
RunStartServiceStatusMsg=Starting OpenSSH server service...

; Path messages
PathTypeSystemMessage=system Path
PathTypeUserMessage=user Path
PathAddSuccessMessage=Successfully added "%1" to %2 Path
PathAddFailMessage=Failed to add "%1" to %2 Path - error %3
PathRemoveSuccessMessage=Successfully removed "%1" from %2 Path
PathRemoveFailMessage=Failed to remove "%1" from %2 Path - error %3

; Executable detection messages
ApplicationsRunningLogMessage=Applications are using files that need to be updated by Setup.
ApplicationsRunningInstructionMessage=Running Applications Detected
ApplicationsRunningTextMessage=The following applications and/or services are using files that need to be updated by Setup:%n%n%1%n%nSetup cannot continue unless you close the applications. If you continue, Setup will attempt to restart the services after the installation has completed.
CloseApplicationsMessage=&Close the applications and continue Setup
DontCloseApplicationsMessage=&Do not close the applications
ApplicationsStillRunningMessage=Applications are still using files that need to be updated by Setup.
RunCommandMessage=Run command: "%1" %2
ClosedApplicationsMessage=Stopped running service(s) and closed running application(s).
StartedServicesMessage=Service restart command(s) executed successfully.

; Application progress page
AppProgressPageInstallingCaption=Please wait while Setup installs %1 on your computer.
AppProgressPageStoppingMessage=Stopping applications...
AppProgressPageStartingMessage=Restarting stopped services...

; Uninstall
DeleteFileSuccess=Deleted file: %1
DeleteFileFail=Failed to delete file: %1
RemoveDirSuccess=Removed directory: %1
RemoveDirFail=Failed to remove directory: %1
