#requires -version 2

<#
.SYNOPSIS
Creates the local access group if it does not exist and updates the sshd_config file to allow only members of the local access group to log on.

.DESCRIPTION
Creates the local access group if it does not exist and updates the sshd_config file to allow only members of the local access group to log on.

.PARAMETER GroupName
Specifies the name of the local access group (i.e., the local group that grants access to the SSH server).

.PARAMETER NoConfirm
Automatically answers "yes" to all confirmation prompts.
#>

[CmdletBinding(SupportsShouldProcess = $true,ConfirmImpact = "High")]
param(
  [ValidateNotNullOrEmpty()]
  [String] $GroupName = "SSH Users",

  [Switch] $NoConfirm
)

$ERROR_ELEVATION_REQUIRED = 740

if ( -not $PSScriptRoot ) {
  $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

# Adds Win32API type definitions
Add-Type -Name Win32API `
  -MemberDefinition (Get-Content -LiteralPath (Join-Path $PSScriptRoot "Win32API.def") -ErrorAction Stop | Out-String -Width 4096) `
  -Namespace "BCA37B9C41264685AD47EEBBD02F40EF" `
  -ErrorAction Stop

$LOCAL_GROUP_COMMENT = "Members are permitted to log on to this computer using secure shell (SSH)."

# Creates a local group; returns 0 for success, non-zero for failure
function Invoke-NetLocalGroupAdd {
  param(
    [String] $groupName,
    [String] $comment
  )
  $lgrpi1 = New-Object "BCA37B9C41264685AD47EEBBD02F40EF.Win32API+LOCALGROUP_INFO_1"
  $lgrpi1.lgrpi1_name = $groupName
  $lgrpi1.lgrpi1_comment = $comment
  try {
    # Allocate memory for unmanaged LOCALGROUP_INFO_1 buffer
    $pLgrpi1 = [Runtime.InteropServices.Marshal]::AllocHGlobal([Runtime.InteropServices.Marshal]::SizeOf($lgrpi1))
    # Copy the managed object to it
    [Runtime.InteropServices.Marshal]::StructureToPtr($lgrpi1,$pLgrpi1,$false)
    $parmErr = 0
    [BCA37B9C41264685AD47EEBBD02F40EF.Win32API]::NetLocalGroupAdd(
      $null,           # servername
      1,               # level
      $pLgrpi1,        # buf
      [Ref] $parmErr)  # parm_err
  }
  finally {
    # Free the unmanaged buffer
    [Runtime.InteropServices.Marshal]::FreeHGlobal($pLgrpi1)
  }
}

# Retrieves a LOCALGROUP_INFO_1 structure for a local group; returns 0 for
# success, or non-zero for failure
function Invoke-NetLocalGroupGetInfo {
  param(
    [String] $groupName,
    [Ref] $lgrpi1
  )
  $result = 0
  $pLgrpi1 = [IntPtr]::Zero
  try {
    $result = [BCA37B9C41264685AD47EEBBD02F40EF.Win32API]::NetLocalGroupGetInfo(
      $null,           # servername
      $groupName,      # groupName
      1,               # level
      [Ref] $pLgrpi1)  # bufptr
    if ( $result -eq 0 ) {
      # Copy the unmanaged buffer to the managed object
      $lgrpi1.Value = [Runtime.InteropServices.Marshal]::PtrToStructure($pLgrpi1,[Type] [BCA37B9C41264685AD47EEBBD02F40EF.Win32API+LOCALGROUP_INFO_1])
    }
  }
  finally {
    if ( $pLgrpi1 -ne [IntPtr]::Zero ) {
      # Free the unmanaged buffer
      [Void] [BCA37B9C41264685AD47EEBBD02F40EF.Win32API]::NetApiBufferFree($pLgrpi1)
    }
  }
  return $result
}

# Gets a local group's comment (description)
function Get-LocalGroupComment {
  param(
    [String] $groupName
  )
  $result = ""
  $groupInfo = $null
  $apiResult = Invoke-NetLocalGroupGetInfo $groupName ([Ref] $groupInfo)
  if ( $apiResult -eq 0 ) {
    $result = $groupInfo.lgrpi1_comment
  }
  return $result
}

# Sets a local group's comment (description)
function Set-LocalGroupComment {
  param(
    [String] $groupName,
    [String] $comment
  )
  $lgrpi1 = $null
  $result = Invoke-NetLocalGroupGetInfo $groupName ([Ref] $lgrpi1)
  if ( $result -eq 0 ) {
    $lgrpi1.lgrpi1_comment = $comment
    try {
      $pLgrpi1 = [Runtime.InteropServices.Marshal]::AllocHGlobal([Runtime.InteropServices.Marshal]::SizeOf($lgrpi1))
      [Runtime.InteropServices.Marshal]::StructureToPtr($lgrpi1,$pLgrpi1,$false)
      $parmErr = 0
      $result = [BCA37B9C41264685AD47EEBBD02F40EF.Win32API]::NetLocalGroupSetInfo(
        $null,           # servername
        $groupName,      # groupname
        1,               # level
        $pLgrpi1,        # buf
        [Ref] $parmErr)  # parm_err
    }
    finally {
      [Runtime.InteropServices.Marshal]::FreeHGlobal($pLgrpi1)
    }
  }
  return $result
}

# Returns $true if the local group exists, or $false otherwise
function Test-LocalGroup {
  param(
    [String] $groupName
  )
  $groupInfo = $null
  (Invoke-NetLocalGroupGetInfo $groupName ([Ref] $groupInfo)) -eq 0
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

# Tests whether the current session is elevated (PSv2-compatible)
function Test-Elevation {
  ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$CYGPATH = Join-Path $PSScriptRoot "cygpath"
Get-Command $CYGPATH -ErrorAction Stop | Out-Null
$GET_ACCOUNTNAME = Join-Path $PSScriptRoot "Get-AccountName.ps1"
Get-Command $GET_ACCOUNTNAME -ErrorAction Stop | Out-Null

# Get absolute Windows path of /etc/sshd_config file
$sshdConfigPath = & $CYGPATH -aw /etc/sshd_config

if ( (-not $sshdConfigPath) ) {
  throw "cygpath command returned no output. Suspect missing Cygwin DLL(s)."
}

# Exit if session isn't elevated
if ( -not (Test-Elevation) ) {
  Write-Error (Get-MessageDescription $ERROR_ELEVATION_REQUIRED -asError)
  exit $ERROR_ELEVATION_REQUIRED
}

# Added this parameter because passing "-Confirm:0" on the powershell.exe -File
# command line throws an error (this is arguably a bug, but easily worked
# around)
if ( $NoConfirm ) {
  $ConfirmPreference = "None"
}

$sshdConfig = Get-Content -LiteralPath $sshdConfigPath -ErrorAction Stop

if ( -not (Test-LocalGroup $GroupName) ) {
  if ( $PSCmdlet.ShouldProcess($GroupName,"Create local group") ) {
    $Result = Invoke-NetLocalGroupAdd $GroupName $LOCAL_GROUP_COMMENT
    if ( $Result -ne 0 ) {
      Write-Error (Get-MessageDescription $Result -asError)
      exit $Result
    }
  }
  if ( -not (Test-LocalGroup $GroupName) ) {
    return
  }
}
else {
  if ( (Get-LocalGroupComment $GroupName) -eq "" ) {
    $Result = Set-LocalGroupComment $GroupName $LOCAL_GROUP_COMMENT
    if ( $Result -ne 0 ) {
      Write-Error (Get-MessageDescription $Result -asError)
    }
  }
}

$accountInfo = & $GET_ACCOUNTNAME ("{0}\{1}" -f ([Net.Dns]::GetHostName()),$GroupName)
if ( $accountInfo ) {
  $pattern = '^AllowGroups "SSH Users"$'
  if ( ($sshdConfig -match $pattern) -and ($accountInfo.CygwinName -ne "SSH Users") ) {
    if ( $PSCmdlet.ShouldProcess($sshdConfigPath, "Update AllowGroups setting") ) {
      $sshdConfig = $sshdConfig -replace $pattern,('AllowGroups "{0}"' -f $accountInfo.CygwinName)
      Set-Content -LiteralPath $sshdConfigPath $sshdConfig -Encoding ASCII -Force
    }
  }
}
