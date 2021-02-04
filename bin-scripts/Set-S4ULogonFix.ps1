# Set-S4ULogonFix.ps1
# Written by Bill Stewart (bstewart at iname.com)

#requires -version 2

<#
.SYNOPSIS
Enables or disables a local user account and a scheduled task that cause a local account logon at system startup.

.DESCRIPTION
Enables or disables a local user account and a scheduled task that cause a local account logon at system startup. On Windows versions older than 8.1 and Server 2012 R2, MsV1_0S4ULogon logons using a local account might not work until after at least one other logon occurs first. This fix works around this problem by causing a local account logon at system startup. If the scheduled task does not run at startup, MsV1_0S4ULogon logons using a local account may not work after a system restart until after at least one other logon occurs first.

.PARAMETER Enable
Creates/resets the local user account, grants the 'Log on as a batch job' user right to the local user account, and creates/resets the scheduled task.

.PARAMETER Disable
Disables the local user account, revokes the 'Log on as a batch job' user right from the local user account, and disables the scheduled task.

.PARAMETER UserName
Specifies the name of the local user account.

.PARAMETER TaskName
Specifies the name of the scheduled task.

.PARAMETER NoConfirm
Automatically answers "yes" to all confirmation prompts.

.PARAMETER Help
Displays help information.

.NOTES
* This fix should only be necessary on Windows versions older than 8.1/Server 2012 R2.

* This fix will not work if the local user account does not have the 'Log on as a batch job' user right. This right is required for the local user account to log on using a scheduled task.

* This fix will not work if the 'Network access: Do not allow storage of passwords and credentials for network authentication' security policy is set to 'Enabled'. This is because the scheduled task requires a stored password. If this policy is set to 'Enabled', the local user account will be created and the user right will be granted, but the scheduled task will not be created.

* A long random password is used when creating or resetting the local user account. It is not possible to retrieve this password. It should not be necessary to manually change the local account's password because the -Enable parameter will automatically generate a new random password and update both the local user account and the scheduled task. (This is useful if it is necessary to change the local user account's password.)

.LINK
https://cygwin.com/ml/cygwin/2019-03/msg00119.html
#>

[CmdletBinding(DefaultParameterSetName = "Help",SupportsShouldProcess = $true,ConfirmImpact = "High")]
param(
  [Parameter(ParameterSetName = "Help")]
  [Switch] $Help,

  [Parameter(Mandatory = $true,ParameterSetName = "Enable")]
  [Switch] $Enable,

  [Parameter(Mandatory = $true,ParameterSetName = "Disable")]
  [Switch] $Disable,

  [Parameter(ParameterSetName = "Enable")]
  [Parameter(ParameterSetName = "Disable")]
  [ValidateNotNullOrEmpty()]
  [String] $UserName = "MsV1_0S4ULogon",

  [Parameter(ParameterSetName = "Enable")]
  [Parameter(ParameterSetName = "Disable")]
  [ValidateNotNullOrEmpty()]
  [String] $TaskName = "MsV1_0S4ULogon",

  [Parameter(ParameterSetName = "Enable")]
  [Parameter(ParameterSetName = "Disable")]
  [Switch] $NoConfirm
)

$ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent

if ( $PSCmdlet.ParameterSetName -eq "Help" ) {
  Get-Help $MyInvocation.MyCommand.Path
  exit
}

# Adds Win32API type definitions
Add-Type -Name Win32API `
  -MemberDefinition (Get-Content -LiteralPath (Join-Path $ScriptPath "Win32API.def") -ErrorAction Stop | Out-String -Width ([Int]::MaxValue)) `
  -Namespace "BCA37B9C41264685AD47EEBBD02F40EF" `
  -ErrorAction Stop
$Win32API = [BCA37B9C41264685AD47EEBBD02F40EF.Win32API]

# API constants
$ERROR_INVALID_DATA       = 0x00D
$ERROR_ELEVATION_REQUIRED = 0x2E4
$TASK_ACTION_EXEC         = 0
$TASK_CREATE              = 2
$TASK_LOGON_PASSWORD      = 1
$TASK_TRIGGER_BOOT        = 8
$TASK_UPDATE              = 4
$USER_PRIV_USER           = 1
$UF_SCRIPT                = 0x00001
$UF_ACCOUNTDISABLE        = 0x00002
$UF_DONT_EXPIRE_PASSWD    = 0x10000

# Object descriptions
$USER_ACCOUNT_DESCRIPTION   = "Added by Cygwin OpenSSH - See '{0}' scheduled task" -f $TaskName
$SCHEDULED_TASK_DESCRIPTION = "Added by Cygwin OpenSSH - This task fixes the MsV1_0S4ULogon logon type on this computer by performing an initial logon at system startup. If this task does not run, MsV1_0S4ULogon logons (such as a logon to the OpenSSH server service using a local account) on this computer may not work after a system restart until after at least one user logs on."

#------------------------------------------------------------------------------
# Functions
#------------------------------------------------------------------------------

# Creates a local user account; returns 0 for success, non-zero for failure
function New-LocalUserAccount {
  param(
    [String] $userName,
    [Security.SecureString] $password,
    [String] $comment
  )
  $userInfo2 = New-Object "BCA37B9C41264685AD47EEBBD02F40EF.Win32API+USER_INFO_2"
  $userInfo2.usri2_name = $userName
  $userInfo2.usri2_password = (ConvertTo-String $password)

  # These are required when creating a new account
  $userInfo2.usri2_priv = $USER_PRIV_USER
  $userInfo2.usri2_flags = $UF_SCRIPT
  $userInfo2.usri2_acct_expires = [UInt32]::MaxValue
  $userInfo2.usri2_max_storage = [UInt32]::MaxValue

  # Set full name and comment
  $userInfo2.usri2_full_name = ""
  $userInfo2.usri2_comment = $comment

  # Set "Password never expires"
  $userInfo2.usri2_flags = $userInfo2.usri2_flags -bor $UF_DONT_EXPIRE_PASSWD

  try {
    # Allocate memory for unmanaged USER_INFO_2 buffer
    $pUserInfo2 = [Runtime.InteropServices.Marshal]::AllocHGlobal([Runtime.InteropServices.Marshal]::SizeOf($userInfo2))
    # Copy the managed object to it
    [Runtime.InteropServices.Marshal]::StructureToPtr($userInfo2,$puserInfo2,$false)
    $parmErr = 0
    $Win32API::NetUserAdd(
      $null,           # servername
      2,               # level
      $pUserInfo2,     # buf
      [Ref] $parmErr)  # parm_err
  }
  finally {
    # Free the unmanaged buffer
    [Runtime.InteropServices.Marshal]::FreeHGlobal($pUserInfo2)
  }
}

# Retrieves USER_INFO_2 object for a user; returns 0 for success, non-zero for
# failure
function Invoke-NetUserGetInfo {
  param(
    [String] $userName,
    [Ref] $userInfo2
  )
  $result = 0
  $pUserInfo2 = [IntPtr]::Zero
  try {
    $result = $Win32API::NetUserGetInfo(
      $null,              # servername
      $userName,          # username
      2,                  # level
      [Ref] $pUserInfo2)  # bufptr
    if ( $result -eq 0 ) {
      # Copy the unmanaged buffer to the managed object
      # Value property is required because it's a [Ref] parameter
      $userInfo2.Value = [Runtime.InteropServices.Marshal]::PtrToStructure($pUserInfo2,[Type] [BCA37B9C41264685AD47EEBBD02F40EF.Win32API+USER_INFO_2])
    }
  }
  finally {
    if ( $pUserInfo2 -ne [IntPtr]::Zero ) {
      # Free the unmanaged buffer
      [Void] $Win32API::NetApiBufferFree($pUserInfo2)
    }
  }
  return $result
}

# Resets the attributes of a local user account; returns 0 for success, or
# non-zero for failure
function Reset-LocalUserAccount {
  param(
    [String] $userName,
    [Security.SecureString] $password
  )
  $userInfo2 = $null
  $result = Invoke-NetUserGetInfo $userName ([Ref] $userInfo2)
  if ( $result -ne 0 ) {
    return $result
  }
  $userInfo2.usri2_password = ConvertTo-String $password
  # Enable if disabled
  if ( ($userInfo2.usri2_flags -band $UF_ACCOUNTDISABLE) -ne 0 ) {
    $userInfo2.usri2_flags = $userInfo2.usri2_flags -band (-bnot $UF_ACCOUNTDISABLE)
  }
  # Set "Password never expires" if not set
  if ( ($userInfo2.usri2_flags -band $UF_DONT_EXPIRE_PASSWD) -eq 0 ) {
    $userInfo2.usri2_flags = $userInfo2.usri2_flags -bor $UF_DONT_EXPIRE_PASSWD
  }
  # Do not change logon hours
  $userInfo2.usri2_logon_hours = [IntPtr]::Zero
  try {
    # Allocate memory for unmanaged USER_INFO_2 buffer
    $pUserInfo2 = [Runtime.InteropServices.Marshal]::AllocHGlobal([Runtime.InteropServices.Marshal]::SizeOf($userInfo2))
    # Copy the managed object to it
    [Runtime.InteropServices.Marshal]::StructureToPtr($userInfo2,$pUserInfo2,$false)
    $parmErr = 0
    $Win32API::NetUserSetInfo(
      $null,           # servername
      $userName,       # username
      2,               # level
      $pUserInfo2,     # buf
      [Ref] $parmErr)  # parm_err
  }
  finally {
    # Free the unmanaged buffer
    [Runtime.InteropServices.Marshal]::FreeHGlobal($pUserInfo2)
  }
}

# Disables a local user account; returns 0 for success, or non-zero for failure
function Disable-LocalUserAccount {
  param(
    [String] $userName
  )
  $userInfo2 = $null
  $result = Invoke-NetUserGetInfo $userName ([Ref] $userInfo2)
  if ( $result -ne 0 ) {
    return $result
  }
  if ( ($userInfo2.usri2_flags -band $UF_ACCOUNTDISABLE) -ne 0 ) {
    # Account is already disabled
    return 0
  }
  # Disable if enabled
  $userInfo2.usri2_flags = $userInfo2.usri2_flags -bor $UF_ACCOUNTDISABLE
  # Do not change logon hours
  $userInfo2.usri2_logon_hours = [IntPtr]::Zero
  try {
    # Allocate memory for unmanaged USER_INFO_2 buffer
    $pUserInfo2 = [Runtime.InteropServices.Marshal]::AllocHGlobal([Runtime.InteropServices.Marshal]::SizeOf($userInfo2))
    # Copy the managed object to it
    [Runtime.InteropServices.Marshal]::StructureToPtr($userInfo2,$pUserInfo2,$false)
    $parmErr = 0
    $Win32API::NetUserSetInfo(
      $null,           # servername
      $userName,       # username
      2,               # level
      $pUserInfo2,     # buf
      [Ref] $parmErr)  # parm_err
  }
  finally {
    # Free the unmanaged buffer
    [Runtime.InteropServices.Marshal]::FreeHGlobal($pUserInfo2)
  }
}

# Returns $true if local user exists, or $false otherwise
function Test-LocalUserAccount {
  param(
    [String] $userName
  )
  $userInfo2 = $null
  (Invoke-NetUserGetInfo $userName ([Ref] $userInfo2)) -eq 0
}

# Tests whether the current session is elevated (PSv2-compatible)
function Test-Elevation {
  ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Outputs the message associated with a message id; -asError parameter causes
# output as an error message - "Error <n> (0x<n>) - <message>"
function Get-MessageDescription {
  param(
    $messageId,
    [Switch] $asError
  )
  # message id must be Int32
  $intId = [BitConverter]::ToInt32([BitConverter]::GetBytes($messageId),0)
  $message = ([ComponentModel.Win32Exception] $intId).Message
  if ( $asError ) {
    "Error {0} (0x{0:X}) - {1}." -f $messageId,$message
  }
  else {
    "{0}." -f $message
  }
}

# Returns a random string of the specified length
function Get-RandomString {
  param(
    [UInt32] $length
  )
  $byteCount = [Math]::Ceiling((($length * 6) + 7) / 8)
  $bytes = New-Object Byte[] $byteCount
  $pRNG = New-Object Security.Cryptography.RNGCryptoServiceProvider
  $pRNG.GetBytes($bytes)
  [Convert]::ToBase64String($bytes).Substring(0,$length)
}

# Converts a SecureString to plain-text
function ConvertTo-String {
  param(
    [Security.SecureString] $secureString
  )
  try {
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
  }
  finally {
    if ( $bstr -ne [IntPtr]::Zero ) {
      [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
  }
}

# Gets a hex error code from an error string; returns $ERROR_INVALID_DATA if
# regex parsing failed
function Get-ErrorCode {
  param(
    [String] $errorString
  )
  $result = $ERROR_INVALID_DATA
  $stringValue = [Regex]::Match($errorString,'0x[\da-f]+',"IgnoreCase").Value
  if ( $stringValue ) {
    $result = [Int] $stringValue
  }
  return $result
}

# Returns $true if the scheduled task exists, or $false otherwise
function Test-ScheduledTask {
  param(
    [String] $taskName
  )
  $result = $false
  try {
    [Void] $TaskFolder.GetTask($taskName)
    $result = $true
  }
  catch {
  }
  return $result
}

# Creates scheduled task; returns 0 for success, or non-zero for failure
function New-ScheduledTask {
  param(
    [String] $taskName,
    [String] $taskUserName,
    [Security.SecureString] $password,
    [String] $description
  )
  $result = 0
  $taskDefinition = $TaskService.NewTask(0)  # Parameter must be 0
  $action = $taskDefinition.Actions.Create($TASK_ACTION_EXEC)
  $action.Path = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::System)) "hostname.exe"
  $taskDefinition.RegistrationInfo.Description = $description
  [Void] $taskDefinition.Triggers.Create($TASK_TRIGGER_BOOT)
  try {
    [Void] $TaskFolder.RegisterTaskDefinition(
      $taskName,
      $taskDefinition,
      $TASK_CREATE,
      $taskUserName,
      (ConvertTo-String $password),
      $TASK_LOGON_PASSWORD
    )
  }
  catch {
    $result = Get-ErrorCode $_.Exception.Message
  }
  return $result
}

# Resets scheduled task; returns 0 for success, or non-zero for failure
function Reset-ScheduledTask {
  param(
    [String] $taskName,
    [String] $taskUserName,
    [Security.SecureString] $password
  )
  $result = 0
  $taskDefinition = $TaskFolder.GetTask($taskName).Definition
  if ( -not $taskDefinition.Settings.Enabled ) {
    $taskDefinition.Settings.Enabled = $true
  }
  foreach ( $trigger in $taskDefinition.Triggers ) {
    if ( ($trigger.Type -eq $TASK_TRIGGER_BOOT) -and (-not $trigger.Enabled) ) {
      $trigger.Enabled = $true
    }
  }
  try {
    [Void] $TaskFolder.RegisterTaskDefinition(
      $taskName,
      $taskDefinition,
      $TASK_UPDATE,
      $taskUserName,
      (ConvertTo-String $password),
      $TASK_LOGON_PASSWORD
    )
  }
  catch {
    $result = Get-ErrorCode $_.Exception.Message
  }
  return $result
}

# Disables scheduled task; returns 0 for success, or non-zero for failure
function Disable-ScheduledTask {
  param(
    [String] $taskName
  )
  $result = 0
  try {
    $TaskFolder.GetTask($taskName).Enabled = $false
  }
  catch {
    $result = Get-ErrorCode $_.Exception.Message
  }
  return $result
}

# Converts a string to a string array, ignoring trailing newlines
function ConvertTo-Array {
  param(
    [String] $stringToConvert
  )
  $stringWithoutTrailingNewLine = $stringToConvert -replace '(\r\n)*$',''
  if ( $stringWithoutTrailingNewLine.Length -gt 0 ) {
    return ,($stringWithoutTrailingNewLine -split "`r`n")
  }
}

# Runs an executable without a window, captures all output, and returns its
# exit code
function Start-Executable {
  param(
    [String] $filePath,
    [String] $arguments,
    [Ref] $output
  )
  $result = 0
  $process = New-Object Diagnostics.Process
  $startInfo = $process.StartInfo
  $startInfo.FileName = $filePath
  $startInfo.Arguments = $arguments
  $startInfo.UseShellExecute = $false
  $startInfo.RedirectStandardError = $true
  $startInfo.RedirectStandardOutput = $true
  $startInfo.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
  try {
    if ( $process.Start() ) {
      $output.Value = [String[]] @()
      $standardOutput = ConvertTo-Array $process.StandardOutput.ReadToEnd()
      $standardError = ConvertTo-Array $process.StandardError.ReadToEnd()
      if ( $standardOutput.Count -gt 0 ) {
        $output.Value += $standardOutput
      }
      if ( $standardError.Count -gt 0 ) {
        $output.Value += $standardError
      }
      $process.WaitForExit()
      $result = $process.ExitCode
    }
  }
  catch {
    $result = $_.Exception.InnerException.ErrorCode
    if ( -not $result ) {
      $result = $ERROR_INVALID_DATA
    }
  }
  return $result
}

# Invokes Cygwin editrights tool; parses output for error code in the form
# '0x<n>' (where <n> = any sequence of hex digits); if output contains an error
# code, return that exit code; otherwise, return the process exit code;
# output contains all output from the command, and errorMessage contains the
# error message (if error code found in output)
function Invoke-Editrights {
  [CmdletBinding()]
  param(
    [String[]] $argList,
    [Ref] $output,
    [Ref] $errorMessage
  )
  $OFS = " "
  $result = Start-Executable $EDITRIGHTS $argList $output
  if ( $result -ne 0 ) {
    foreach ( $line in $output.Value ) {
      if ( $line.Trim().Length -gt 0 ) {
        $reMatch = [Regex]::Match($line,'0x[0-9a-f]+',"IgnoreCase")
        if ( $reMatch ) {
          $errorMessage.Value = $line
          $result = [Int] $reMatch.Value
          break
        }
      }
    }
  }
  return $result
}

# Gets user rights; returns 0 for success, non-zero for failure
function Get-UserRights {
  param(
    [String] $userName,
    [Ref] $userRights,
    [Ref] $errorMessage
  )
  $output = $null
  $result = Invoke-Editrights "-u",$userName,"-l" ([Ref] $output) $errorMessage
  if ( $result -eq 0 ) {
    $userRights.Value = $output
  }
  return $result
}

# Grants a user right; returns 0 for success, or non-zero for failure
function Grant-UserRight {
  param(
    [String] $userName,
    [String] $userRight,
    [Ref] $errorMessage
  )
  $output = $null
  Invoke-Editrights "-u",$userName,"-a",$userRight ([Ref] $output) $errorMessage
}

# Revokes a user right; returns 0 for success, or non-zero for failure
function Revoke-UserRight {
  param(
    [String] $userName,
    [String] $userRight,
    [Ref] $errorMessage
  )
  $output = $null
  Invoke-Editrights "-u",$userName,"-r",$userRight ([Ref] $output) $errorMessage
}

# Exit if session isn't elevated
if ( -not (Test-Elevation) ) {
  Write-Error (Get-MessageDescription $ERROR_ELEVATION_REQUIRED -asError)
  exit $ERROR_ELEVATION_REQUIRED
}

# Exit if we can't find editrights.exe
$EDITRIGHTS = Join-Path $ScriptPath "editrights"
Get-Command $EDITRIGHTS -ErrorAction Stop | Out-Null

# Added this because passing "-Confirm:0" on the powershell.exe -File command
# line throws an error (this is arguably a bug, but one we can easily work
# around)
if ( $NoConfirm ) {
  $ConfirmPreference = "None"
}

# No errors yet
$ExitCode = 0
$ErrorMessage = $null

# No user rights granted yet
$RightGranted = $false

# Connect to task scheduler service and get root task folder; exit if failure
try {
  $TaskService = New-Object -ComObject "Schedule.Service"
  $TaskService.Connect()
  $TaskFolder = $TaskService.GetFolder("\")
}
catch {
  $ExitCode = Get-ErrorCode $_.Exception.Message
  Write-Error (Get-MessageDescription $ExitCode -asError)
  exit $ExitCode
}

# Define an arbitrary random password for the user account (it will only be
# used for the scheduled task)
$AccountPassword = ConvertTo-SecureString (Get-RandomString 127) -AsPlainText -Force

switch ( $PSCmdlet.ParameterSetName ) {
  "Enable" {
    # If the local user doesn't exist, create it
    if ( -not (Test-LocalUserAccount $UserName) ) {
      if ( $PSCmdlet.ShouldProcess($UserName,"Create local user account") ) {
        $ExitCode = New-LocalUserAccount $UserName $AccountPassword $USER_ACCOUNT_DESCRIPTION
        if ( $ExitCode -ne 0 ) {
          break
        }
      }
    }
    else {
      # If the local user already exists, reset it
      if ( $PSCmdlet.ShouldProcess($UserName,"Reset local user account") ) {
        $ExitCode = Reset-LocalUserAccount $UserName $AccountPassword
        if ( $ExitCode -ne 0 ) {
          break
        }
      }
    }
    if ( Test-LocalUserAccount $UserName ) {
      # Grant user right
      if ( $PSCmdlet.ShouldProcess($UserName,"Grant 'Log on as a batch job' user right") ) {
        $UserRights = $null
        $ExitCode = Get-UserRights $UserName ([Ref] $UserRights) ([Ref] $ErrorMessage)
        if ( $ExitCode -eq 0 ) {
          $RightGranted = $UserRights -contains "SeBatchLogonRight"
          if ( -not $RightGranted ) {
            $ExitCode = Grant-UserRight $UserName "SeBatchLogonRight" ([Ref] $ErrorMessage)
            $RightGranted = $ExitCode -eq 0
          }
        }
      }
      if ( ($ExitCode -eq 0) -and $RightGranted ) {
        # If scheduled task doesn't exist, create it
        if ( -not (Test-ScheduledTask $TaskName) ) {
          if ( $PSCmdlet.ShouldProcess($TaskName,"Create scheduled task") ) {
            $ExitCode = New-ScheduledTask $TaskName $UserName $AccountPassword $SCHEDULED_TASK_DESCRIPTION
          }
        }
        else {
          # If the scheduled task already exists, reset it
          if ( $PSCmdlet.ShouldProcess($TaskName,"Reset scheduled task") ) {
            $ExitCode = Reset-ScheduledTask $TaskName $UserName $AccountPassword
          }
        }
      }
    }
  }
  "Disable" {
    # If the scheduled task exists, disable it
    if ( Test-ScheduledTask $TaskName ) {
      if ( $PSCmdlet.ShouldProcess($TaskName,"Disable scheduled task") ) {
        $ExitCode = Disable-ScheduledTask $TaskName
        if ( $ExitCode -ne 0 ) {
          break
        }
      }
    }
    else {
      Write-Verbose "Scheduled task '$TaskName' not found."
    }
    # If the local user exists, disable it and revoke the user right
    if ( Test-LocalUserAccount $UserName ) {
      if ( $PSCmdlet.ShouldProcess($UserName,"Disable local user account") ) {
        $ExitCode = Disable-LocalUserAccount $UserName
        if ( $ExitCode -ne 0 ) {
          break
        }
      }
      if ( $PSCmdlet.ShouldProcess($UserName,"Revoke 'Log on as a batch job' user right") ) {
        $UserRights = $null
        $ExitCode = Get-UserRights $UserName ([Ref] $UserRights) ([Ref] $ErrorMessage)
        if ( ($ExitCode -eq 0) -and ($UserRights -contains "SeBatchLogonRight") ) {
          $ExitCode = Revoke-UserRight $UserName "SeBatchLogonRight" ([Ref] $ErrorMessage)
        }
      }
    }
    else {
      Write-Verbose "Local user account '$UserName' not found."
    }
  }
}

if ( $ExitCode -ne 0 ) {
  if ( $ErrorMessage ) {
    Write-Error $ErrorMessage
  }
  else {
    Write-Error (Get-MessageDescription $ExitCode -asError)
  }
}

exit $ExitCode
