# Set-SSHService.ps1
# Written by Bill Stewart (bstewart@iname.com)

#requires -version 2

<#
.SYNOPSIS
Manages the OpenSSH Server service.

.DESCRIPTION
Manages the OpenSSH Server service.

.PARAMETER Install
Installs the service, creates the local privsep user account, and adds a firewall rule to allow connections.

.PARAMETER ServiceName
Specifies the service's name.

.PARAMETER ServiceDisplayName
Specifies the service's display name.

.PARAMETER EnvVarOptions
Specifies a CYGWIN environment variable value for the service.

.PARAMETER Uninstall
Uninstalls the service, removes the firewall rule, and disables the local privsep user account. An attempt is made to stop the service first before uninstalling it. If the stop attempt fails, the service is not uninstalled and the firewall rule is not removed.

.PARAMETER Start
Starts the service if it is not running.

.PARAMETER Stop
Stops the service if it is running.

.PARAMETER NoConfirm
Automatically answers "yes" to all confirmation prompts.

.PARAMETER ResetPrivsepAccount
Resets the password and account properties for the local privsep user account.

.PARAMETER Help
Displays help information.

.NOTES
The local privsep account (sshd) is not strictly required, but it enables use of the ChrootDirectory setting in sshd_config to restrict a remote user's access to a single directory (normally used with SFTP). If the privsep account is not enabled, the ChrootDirectory setting in sshd_config will not work.
#>

[CmdletBinding(DefaultParameterSetName = "Help",SupportsShouldProcess = $true,ConfirmImpact = "High")]
param(
  [Parameter(ParameterSetName = "Help")]
  [Switch] $Help,

  [Parameter(Mandatory = $true,ParameterSetName = "Install")]
  [Switch] $Install,

  [Parameter(Mandatory = $true,ParameterSetName = "Uninstall")]
  [Switch] $Uninstall,

  [Parameter(Mandatory = $true,ParameterSetName = "Start")]
  [Switch] $Start,

  [Parameter(Mandatory = $true,ParameterSetName = "Stop")]
  [Switch] $Stop,

  [Parameter(Mandatory = $true,ParameterSetName = "ResetPrivsepAccount")]
  [Switch] $ResetPrivsepAccount,

  [Parameter(ParameterSetName = "Install")]
  [Parameter(ParameterSetName = "Uninstall")]
  [Parameter(ParameterSetName = "Start")]
  [Parameter(ParameterSetName = "Stop")]
  [ValidateNotNullOrEmpty()]
  [String] $ServiceName = "opensshd",

  [Parameter(ParameterSetName = "Install")]
  [ValidateNotNullOrEmpty()]
  [String] $ServiceDisplayName = "OpenSSH Server",

  [Parameter(ParameterSetName = "Install")]
  [String] $EnvVarOptions,

  [Parameter(ParameterSetName = "Install")]
  [Parameter(ParameterSetName = "Uninstall")]
  [Parameter(ParameterSetName = "Start")]
  [Parameter(ParameterSetName = "Stop")]
  [Parameter(ParameterSetName = "ResetPrivsepAccount")]
  [Switch] $NoConfirm
)

if ( -not $PSScriptRoot ) {
  $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

if ( $PSCmdlet.ParameterSetName -eq "Help" ) {
  Get-Help $MyInvocation.MyCommand.Path
  exit
}

# Adds Win32API type definitions
Add-Type -Name Win32API `
  -MemberDefinition (Get-Content -LiteralPath (Join-Path $PSScriptRoot "Win32API.def") -ErrorAction Stop | Out-String -Width 4096) `
  -Namespace "BCA37B9C41264685AD47EEBBD02F40EF" `
  -ErrorAction Stop

# API constants
$ERROR_INVALID_DATA           = 0x00D
$ERROR_ELEVATION_REQUIRED     = 0x2E4
$ERROR_SERVICE_DOES_NOT_EXIST = 1060
$ERROR_SERVICE_EXISTS         = 1073
$USER_PRIV_USER               = 1
$UF_SCRIPT                    = 0x00001
$UF_ACCOUNTDISABLE            = 0x00002
$UF_DONT_EXPIRE_PASSWD        = 0x10000

# sshd privilege separation account name
$SSHD_PRIVSEP_ACCOUNT_NAME = "sshd"

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

# Creates a local user account; returns 0 for success, non-zero for failure
function New-LocalUserAccount {
  param(
    [String] $userName,
    [String] $comment
  )
  $userInfo2 = New-Object "BCA37B9C41264685AD47EEBBD02F40EF.Win32API+USER_INFO_2"
  $userInfo2.usri2_name = $userName
  $userInfo2.usri2_password = (Get-RandomString 127)

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
    [BCA37B9C41264685AD47EEBBD02F40EF.Win32API]::NetUserAdd(
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
    $result = [BCA37B9C41264685AD47EEBBD02F40EF.Win32API]::NetUserGetInfo(
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
      [Void] [BCA37B9C41264685AD47EEBBD02F40EF.Win32API]::NetApiBufferFree($pUserInfo2)
    }
  }
  return $result
}

# Resets the attributes of a local user account; returns 0 for success, or
# non-zero for failure
function Reset-LocalUserAccount {
  param(
    [String] $userName
  )
  $userInfo2 = $null
  $result = Invoke-NetUserGetInfo $userName ([Ref] $userInfo2)
  if ( $result -ne 0 ) {
    return $result
  }
  # Reset password
  $userInfo2.usri2_password = (Get-RandomString 127)
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
    [BCA37B9C41264685AD47EEBBD02F40EF.Win32API]::NetUserSetInfo(
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
    [BCA37B9C41264685AD47EEBBD02F40EF.Win32API]::NetUserSetInfo(
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

# Invokes cygrunsrv; checks stderr for the string 'error <n>' (where <n> is any
# sequence of digits) for an exit code and exits with that exit code if found;
# otherwise, the function exits with cygrunsrv's exit code
function Invoke-Cygrunsrv {
  [CmdletBinding()]
  param(
    [String[]] $argList
  )
  $OFS = " "
  $output = $null
  $result = Start-Executable $CYGRUNSRV $argList ([Ref] $output)
  if ( $result -ne 0 ) {
    foreach ( $line in $output ) {
      if ( $line.Trim().Length -gt 0 ) {
        $reMatch = [Regex]::Match($line,'error (\d+)',"IgnoreCase")
        if ( $reMatch ) {
          $result = [Int] $reMatch.Groups[1].Value
          break
        }
      }
    }
  }
  return $result
}

# Adds firewall rule
function New-FirewallRule {
  param(
    [String] $ruleName,
    [String] $fileName
  )
  & $NETSH advfirewall firewall add rule name=$ruleName dir=in action=allow program=$fileName > $null 2>&1
}

# Removes firewall rule
function Remove-FirewallRule {
  param(
    [String] $ruleName,
    [String] $fileName
  )
  & $NETSH advfirewall firewall delete rule name=$ruleName dir=in program=$fileName > $null 2>&1
}

# Added this parameter because passing "-Confirm:0" on the powershell.exe -File
# command line throws an error (this is arguably a bug, but easily worked
# around)
if ( $NoConfirm ) {
  $ConfirmPreference = "None"
}

# Exit if session isn't elevated
if ( -not (Test-Elevation) ) {
  Write-Error (Get-MessageDescription $ERROR_ELEVATION_REQUIRED -asError)
  exit $ERROR_ELEVATION_REQUIRED
}

# Validate executables
$CYGPATH = Join-Path $PSScriptRoot "cygpath"
Get-Command $CYGPATH -ErrorAction Stop | Out-Null
$CYGRUNSRV = Join-Path $PSScriptRoot "cygrunsrv"
Get-Command $CYGRUNSRV -ErrorAction Stop | Out-Null
$NETSH = Join-Path ([Environment]::SystemDirectory) "netsh"
Get-Command $NETSH -ErrorAction Stop | Out-Null

# No errors yet
$ExitCode = 0

switch ( $PSCmdlet.ParameterSetName ) {
  "Install" {
    if ( Get-Service $ServiceName -ErrorAction SilentlyContinue ) {
      $ExitCode = $ERROR_SERVICE_EXISTS
      break
    }
    if ( -not (Test-LocalUserAccount $SSHD_PRIVSEP_ACCOUNT_NAME) ) {
      [Void] (New-LocalUserAccount $SSHD_PRIVSEP_ACCOUNT_NAME "sshd privsep account")
    }
    else {
      [Void] (Reset-LocalUserAccount $SSHD_PRIVSEP_ACCOUNT_NAME)
    }
    $ArgList = @(
      ('-I "{0}"' -f $ServiceName)
      ('-d "{0}"' -f $ServiceDisplayName)
      ('-c /bin')
      ('-f "Allows this computer to accept SSH (secure shell) connection requests."')
      ('-p /usr/sbin/sshd')
      ('-a -D')
      ('-y tcpip')
    )
    if ( $EnvVarOptions ) {
      $ArgList += '-e CYGWIN={0}' -f $EnvVarOptions
    }
    $FullName = "{0} ('{1}')" -f $ServiceName,$ServiceDisplayName
    if ( $PSCmdlet.ShouldProcess($FullName,"Install service") ) {
      $ExitCode = Invoke-Cygrunsrv $ArgList
      if ( $ExitCode -eq 0 ) {
        New-FirewallRule $FullName (& $CYGPATH -aw /usr/sbin/sshd)
      }
    }
  }
  "Uninstall" {
    $Service = Get-Service $ServiceName -ErrorAction SilentlyContinue
    if ( -not $Service ) {
      $ExitCode = $ERROR_SERVICE_DOES_NOT_EXIST
      break
    }
    $FullName = "{0} ('{1}')" -f $ServiceName,$Service.DisplayName
    if ( $PSCmdlet.ShouldProcess($FullName,"Uninstall service") ) {
      if ( $Service.Status -ne "Stopped" ) {
        $ExitCode = Invoke-Cygrunsrv "-E",$ServiceName
        if ( $ExitCode -ne 0 ) {
          break
        }
      }
      $ExitCode = Invoke-Cygrunsrv "-R",$ServiceName
      if ( $ExitCode -eq 0 ) {
        Remove-FirewallRule $FullName (& $CYGPATH -aw /usr/sbin/sshd)
        [Void] (Disable-LocalUserAccount $SSHD_PRIVSEP_ACCOUNT_NAME)
      }
    }
  }
  "Start" {
    $Service = Get-Service $ServiceName -ErrorAction SilentlyContinue
    if ( -not $Service ) {
      $ExitCode = $ERROR_SERVICE_DOES_NOT_EXIST
      break
    }
    $FullName = "{0} ('{1}')" -f $ServiceName,$Service.DisplayName
    if ( $PSCmdlet.ShouldProcess($FullName,"Start service") ) {
      if ( $Service.Status -ne "Running" ) {
        $ExitCode = Invoke-Cygrunsrv "-S",$ServiceName
      }
    }
  }
  "Stop" {
    $Service = Get-Service $ServiceName -ErrorAction SilentlyContinue
    if ( -not $Service ) {
      $ExitCode = $ERROR_SERVICE_DOES_NOT_EXIST
      break
    }
    $FullName = "{0} '{1}'" -f $ServiceName,$Service.DisplayName
    if ( $PSCmdlet.ShouldProcess($FullName,"Stop service") ) {
      if ( $Service.Status -ne "Stopped" ) {
        $ExitCode = Invoke-Cygrunsrv "-E",$ServiceName
      }
    }
  }
  "ResetPrivsepAccount" {
    if ( $PSCmdlet.ShouldProcess($SSHD_PRIVSEP_ACCOUNT_NAME,"Reset password and local user account properties") ) {
      $ExitCode = Reset-LocalUserAccount $SSHD_PRIVSEP_ACCOUNT_NAME
    }
  }
}

if ( $ExitCode -ne 0 ) {
  Write-Error (Get-MessageDescription $ExitCode -asError)
}

exit $ExitCode
