# Set-SSHHostKey.ps1
# Written by Bill Stewart (bstewart at iname.com)

# Runs ssh-keygen -A and configures the file permissions on the host key files
# such that only SYSTEM and and Administrators have full control (no other
# access).

#requires -version 2

<#
.SYNOPSIS
Creates SSH host key files using ssh-keygen and sets restricted permissions on the private key files.

.DESCRIPTION
Creates SSH host key files using ssh-keygen and sets restricted permissions on the private key files.
#>

$ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
$ERROR_ELEVATION_REQUIRED = 0x2E4

$CYGPATH = Join-Path $ScriptPath "cygpath"
Get-Command $CYGPATH -ErrorAction Stop | Out-Null
$SSH_KEYGEN = Join-Path $ScriptPath "ssh-keygen"
Get-Command $SSH_KEYGEN -ErrorAction Stop | Out-Null
$ICACLS = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::System)) "icacls.exe"
Get-Command $ICACLS -ErrorAction Stop | Out-Null

if ( (-not (& $CYGPATH -aw /)) ) {
  throw "cygpath command returned no output. Suspect missing Cygwin DLL(s)."
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

    [Switch]
    $asError
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

if ( -not (Test-Elevation) ) {
  Write-Error (Get-MessageDescription $ERROR_ELEVATION_REQUIRED -asError)
  exit $ERROR_ELEVATION_REQUIRED
}

& $SSH_KEYGEN -A
if ( $LASTEXITCODE -eq 0 ) {
  Get-ChildItem (& $CYGPATH -aw /etc/ssh_host_*_key) | ForEach-Object {
    & $ICACLS $_.FullName /inheritance:r /grant "*S-1-5-18:F" "*S-1-5-32-544:F" > $null
  }
}
