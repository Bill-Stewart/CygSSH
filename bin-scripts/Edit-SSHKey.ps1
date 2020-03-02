# Edit-SSHKey.ps1
# Written by Bill Stewart (bstewart@iname.com)

#requires -version 2

<#
.SYNOPSIS
Edits properties of an SSH private key file using ssh-keygen.

.DESCRIPTION
Edits properties of an SSH private key file using ssh-keygen.

.PARAMETER FileName
Specifies the private key file's name. If the file doesn't include a path, the current file system directory is checked, and then the .ssh directory in the current user's home directory.

.PARAMETER Comment
Edits the private key file's comment. If the private key is protected by a passphrase, you will be prompted to enter it. This parameter will overwrite an existing public key file with a new copy of the public key file containing the comment. The public key file has the same filename with .pub appended. You can use this parameter to generate a new public key file in case you lose it (just re-enter the comment or enter a new one).

.PARAMETER Passphrase
Edits the private key file's passphrase. If the private key file has a non-empty passphrase, you will be prompted to enter it first.
#>

[CmdletBinding(DefaultParameterSetName = "Help")]
param(
  [Parameter(Position = 0,Mandatory = $true,ParameterSetName = "Comment")]
  [Parameter(Position = 0,Mandatory = $true,ParameterSetName = "Passphrase")]
  [ValidateNotNullOrEmpty()]
  [String] $FileName,

  [Parameter(Mandatory = $true,ParameterSetName = "Comment")]
  [Switch] $Comment,

  [Parameter(Mandatory = $true,ParameterSetName = "Passphrase")]
  [Switch] $Passphrase,

  [Parameter(ParameterSetName = "Help")]
  [Switch] $Help
)

if ( -not $PSScriptRoot ) {
  $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

if ( $PSCmdlet.ParameterSetName -eq "Help" ) {
  Get-Help $MyInvocation.MyCommand.Path
  exit
}

# Validate executables
$CYGPATH = Join-Path $PSScriptRoot "cygpath"
Get-Command $CYGPATH -ErrorAction Stop | Out-Null
$DASH = Join-Path $PSScriptRoot "dash"
Get-Command $DASH -ErrorAction Stop | Out-Null
$SSH_KEYGEN = Join-Path $PSScriptRoot "ssh-keygen"
Get-Command $SSH_KEYGEN -ErrorAction Stop | Out-Null

$ERROR_FILE_NOT_FOUND = 2

# Get Cygwin home directory for current user
function Get-HomeDirectory {
  & $DASH -c '/bin/cygpath -aw "$HOME"'
}

# Gets default key file path
function Get-DefaultKeyFilePath {
  Join-Path (Get-HomeDirectory) ".ssh"
}

# Filename doesn't include path
if ( -not ($FileName.Contains("\") -or $FileName.Contains("/")) ) {
  # Check current file system directory
  $FullFileName = Join-Path $ExecutionContext.SessionState.Path.CurrentFileSystemLocation.Path $FileName
  if ( -not (Test-Path -LiteralPath $FullFileName) ) {
    # Check in .ssh directory in profile
    $FullFileName = Join-Path (Get-DefaultKeyFilePath) $FileName
  }
}
else {
  $FullFileName = $FileName
}

if ( -not (Test-Path -LiteralPath $FullFileName) ) {
  Write-Error "File '$FullFileName' not found." -Category ObjectNotFound
  exit $ERROR_FILE_NOT_FOUND
}

Write-Host "Key file: $FullFileName"
switch ( $PSCmdlet.ParameterSetName ) {
  "Comment" {
    & $SSH_KEYGEN -c -f (& $CYGPATH $FullFileName)
  }
  "Passphrase" {
    & $SSH_KEYGEN -p -f (& $CYGPATH $FullFileName)
  }
}
