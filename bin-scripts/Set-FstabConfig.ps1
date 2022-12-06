# Set-FstabConfig.ps1
# Written by Bill Stewart (bstewart at iname.com)

#requires -version 2

<#
.SYNOPSIS
Creates the fstab file mounting all file systems with the 'noacl' option.

.DESCRIPTION
Creates the fstab file mounting all file systems with the 'noacl' option.

.PARAMETER NoConfirm
Automatically answers "yes" to all confirmation prompts.

.PARAMETER Force
Forces overwriting the fstab file if it already exists.
#>

[CmdletBinding(SupportsShouldProcess,ConfirmImpact = "High")]
param(
  [Switch] $NoConfirm,

  [Switch] $Force
)

$ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
$ERROR_ELEVATION_REQUIRED = 0x2E4

$CYGPATH = Join-Path $ScriptPath "cygpath"

Get-Command $CYGPATH -ErrorAction Stop | Out-Null

# Get absolute Windows path of /etc/fstab file
$fstabPath = & $CYGPATH -aw /etc/fstab

if ( (-not $fstabPath) ) {
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

# Added this parameter because passing "-Confirm:0" on the powershell.exe -File
# command line throws an error (this is arguably a bug, but easily worked
# around)
if ( $NoConfirm ) {
  $ConfirmPreference = "None"
}

if ( Test-Path $fstabPath ) {
  if ( $Force ) {
    if ( -not ($PSCmdlet.ShouldProcess($fstabPath,"Overwrite file")) ) {
      return
    }
  }
  else {
    Write-Warning "File '$fstabPath' already exists and -Force parameter was not specified -- exiting."
    return
  }
}

# Function that returns the absolute Windows path with / rather than \ and
# replacing spaces with '\040' (as needed for the /etc/fstab file)
function Get-Path {
  param(
    [String]
    $inputPath
  )
  (& $CYGPATH -am $inputPath) -replace ' ','\040'
}

# Preamble content
$fstabContent = @"
# /etc/fstab
#
#    This file is read once by the first process in a Cygwin process tree.
#    To pick up changes, restart all Cygwin processes.  For a description
#    see https://cygwin.com/cygwin-ug-net/using.html#mount-table

"@ -split [Environment]::NewLine

# Add standard mount points with 'noacl'
"/","/usr/bin","/usr/lib" | ForEach-Object {
  # '/' requires 'override'
  if ( $_ -eq "/" ) {
    $mountOptions = "binary,noacl,override"
  }
  else {
    $mountOptions = "binary,noacl"
  }
  $fstabContent += "{0} {1} ntfs {2} 0 0" -f (Get-Path $_),$_,$mountOptions
}

# Add '/cygdrive' as cygdrive
$fstabContent += "none /cygdrive cygdrive binary,noacl,posix=0,user 0 0"

# Write file
Set-Content -LiteralPath $fstabPath $fstabContent -Encoding ASCII -Force
