#preproc ispp

; Cygwin-OpenSSH - Inno Setup messages file

#include AddBackslash(SourcePath) + "includes.iss"

[Messages]
SetupWindowTitle=Setup - %1 [{#AppFullVersion}]
WizardSelectComponents=Select Setup Type
SelectComponentsDesc=Which components should be installed?
SelectComponentsLabel2=Select the setup type you want to use. Click Next when you are ready to continue.
CannotContinue=Setup cannot continue. Click Back to try again, or Cancel to exit.
FinishedLabel=Setup has finished installing [name] on your computer.

[CustomMessages]

; Types
TypesFullDescription=Full installation (server and client files)
TypesClientDescription=Client installation (client files only)

; Components
ComponentsServerDescription=Server and client files
ComponentsClientDescription=Client files only

; Icons
IconsUserGuideName=CygSSH User Guide

; Tasks
TasksStartServiceDescription=&Start OpenSSH server service
TasksModifyPathDescription=&Add to %1
TasksResetConfigDescription=&Reset OpenSSH configuration files to default (use with caution!)

; Run
RunSetPermissionsStatusMsg=Setting file system permissions...
RunConfigureFstabStatusMsg=Configuring fstab file...
RunConfigureSSHHostKeysStatusMsg=Configuring SSH host keys...
RunConfigureLocalAccessGroupStatusMsg=Configuring local access group...
RunInstallServiceStatusMsg=Installing OpenSSH server service...
RunStartServiceStatusMsg=Starting OpenSSH server service...

; Reset config messages
ResetConfigFileConfirmationMessage=Restting the OpenSSH configuration files to default means you will lose any configuration customizations.%n%nAre you sure you want to continue?
ResetConfigFileRenameSuccessMessage=Successfully renamed "%1" to "%2"
ResetConfigFileRenameFailMessage=Failed to rename "%1" to "%2"

; Path messages
PathTypeSystemMessage=system Path
PathTypeUserMessage=user Path
PathAddSuccessMessage=Successfully added "%1" to %2 Path
PathAddFailMessage=Failed to add "%1" to %2 Path - error %3
PathRemoveSuccessMessage=Successfully removed "%1" from %2 Path
PathRemoveFailMessage=Failed to remove "%1" from %2 Path - error %3

; Package messages
PackageDetectedLogMessage=Existing installation of package detected
PackageNotDetectedLogMessage=No existing installations of package detected
PackageVersionLessLogMessage=This version (%1) less than installed version
PackageVersionEqualLogMessage=This version (%1) equal to installed version
PackageVersionGreaterLogMessage=This version (%1) greater than installed version
PackageUninstallStatusLogMessage=Uninstall existing package exit code = %1
PackageUninstallErrorMessage=Setup was unable to uninstall the version currently installed on the system.

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
