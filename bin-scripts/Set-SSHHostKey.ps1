# Set-SSHHostKey.ps1
# Written by Bill Stewart (bstewart@iname.com)

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

if ( -not $PSScriptRoot ) {
  $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

$CYGPATH = Join-Path $PSScriptRoot "cygpath"
Get-Command $CYGPATH -ErrorAction Stop | Out-Null
$SSH_KEYGEN = Join-Path $PSScriptRoot "ssh-keygen"
Get-Command $SSH_KEYGEN -ErrorAction Stop | Out-Null
$SETACL = Join-Path $PSScriptRoot "setacl"
Get-Command $SETACL -ErrorAction Stop | Out-Null

if ( (-not (& $CYGPATH -aw /)) ) {
  throw "cygpath command returned no output. Suspect missing Cygwin DLL(s)."
}

& $SSH_KEYGEN -A
if ( $LASTEXITCODE -eq 0 ) {
  Get-ChildItem (& $CYGPATH -aw /etc/ssh_host_*_key) | ForEach-Object {
    & $SETACL -on $_.FullName -ot file -actn ace -ace "n:S-1-5-18;p:full" -actn ace -ace "n:S-1-5-32-544;p:full" -actn setprot -op "dacl:p_nc" > $null
  }
}
