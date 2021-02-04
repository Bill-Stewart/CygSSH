# New-SSHKey.ps1
# Written by Bill Stewart (bstewart at iname.com)

#requires -version 2

<#
.SYNOPSIS
Creates a SSH private/public authentication key pair using ssh-keygen and restricts the permissions on the private key file.

.DESCRIPTION
Creates a SSH private/public authentication key pair using ssh-keygen and restricts the permissions on the private key file.

.PARAMETER FileName
Specifies the private key file's name. Wildcards are not permitted. The private key will be stored in this file, and the public key will have the same filename with '.pub' appended to the name. The private key file must not already exist. The default path for the private and public key files is the .ssh directory in the current user's home directory. The private key file's default filename is id_<keytype>, where <keytype> is the value of the -KeyType parameter (default is ed25519). Restricted permissions are set on the private key file such that only the SYSTEM account and the current user have full control access to the private key file.

.PARAMETER Passphrase
Specifies the passphrase for protecting the private key. The passphrase cannot contain the " character.

.PARAMETER Comment
Specifies a comment that can help identify the key. The default is '<username>@<hostname>'. The comment cannot contain the " character.

.PARAMETER KeyType
Specifies the key type: dsa, ecdsa, ecdsa-sk, ed25519, ed25519-sk, or rsa. The default is ed25519.

.PARAMETER Bits
Specifies the number of bits for the key type. The default value for this parameter depends on the -KeyType parameter:
  dsa - must be 1024 (not considered secure)
  ecdsa - must be 256, 384, or 521 (default is 521)
  rsa - minimum 1024; default is 3072 (values < 2048 not considered secure)
This parameter is ignored if -KeyType is ecdsa-sk, ed25519 or ed25519-sk.

.PARAMETER Rounds
Specifies the number of key derivation function (KDF) rounds used when saving the private key.

.PARAMETER Quiet
Prevents output.

.NOTES
If the current user's home directory is on a network server, it may not be possible to restrict the permissions on the private key file. If changing the permissions fails, a warning message will be generated. It may be desirable to specify a different path for the private key file in this case.
#>

[CmdletBinding(SupportsShouldProcess = $true,ConfirmImpact = "High")]
param(
  [String] $FileName,

  [Security.SecureString] $Passphrase,

  [String] $Comment,

  [ValidateSet("dsa","ecdsa","ecdsa-sk","ed25519","ed25519-sk","rsa")]
  [String] $KeyType = "ed25519",

  [UInt32] $Bits,

  [UInt32] $Rounds,

  [Switch] $Quiet
)

$ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent

#------------------------------------------------------------------------------
# Validate executables
#------------------------------------------------------------------------------
$CYGPATH = Join-Path $ScriptPath "cygpath"
Get-Command $CYGPATH -ErrorAction Stop | Out-Null
$DASH = Join-Path $ScriptPath "dash"
Get-Command $DASH -ErrorAction Stop | Out-Null
$SSH_KEYGEN = Join-Path $ScriptPath "ssh-keygen"
Get-Command $SSH_KEYGEN -ErrorAction Stop | Out-Null
$SETACL = Join-Path $ScriptPath "setacl"
Get-Command $SETACL -ErrorAction Stop | Out-Null

#------------------------------------------------------------------------------
# Define Windows error code constants
#------------------------------------------------------------------------------
$ERROR_INVALID_PARAMETER = 87
$ERROR_ALREADY_EXISTS    = 183

#------------------------------------------------------------------------------
# Validate parameter values
#------------------------------------------------------------------------------
switch ( $KeyType ) {
  "dsa" {
    if ( -not $PSBoundParameters.ContainsKey("Bits") ) {
      $Bits = 1024
    }
    else {
      if ( $Bits -ne 1024 ) {
        Write-Error "dsa key requires 1024 for the -Bits parameter." -Category InvalidArgument
        exit $ERROR_INVALID_PARAMETER
      }
    }
  }
  "ecdsa" {
    if ( -not $PSBoundParameters.ContainsKey("Bits") ) {
      $Bits = 521
    }
    else {
      if ( @(256,384,521) -notcontains $Bits ) {
        Write-Error "ecdsa key requires 256, 384, or 521 for the -Bits parameter." -Category InvalidArgument
        exit $ERROR_INVALID_PARAMETER
      }
    }
  }
  "ecdsa-sk" {
    # number of bits not used with this key type
  }
  "ed25519" {
    # number of bits not used with this key type
  }
  "ed25519-sk" {
    # number of bits not used with this key type
  }
  "rsa" {
    if ( -not $PSBoundParameters.ContainsKey("Bits") ) {
      $Bits = 3072
    }
    else {
      if ( $Bits -lt 1024 ) {
        Write-Error "rsa key requires at least 1024 for the -Bits parameter." -Category InvalidArgument
        exit $ERROR_INVALID_PARAMETER
      }
    }
  }
}

#------------------------------------------------------------------------------
# Define functions
#------------------------------------------------------------------------------

# Get Cygwin home directory for current user
function Get-HomeDirectory {
  & $DASH -c '/bin/cygpath -aw "$HOME"'
}

# Gets default key file path based on key type
function Get-DefaultKeyFileName {
  param(
    $keyType
  )
  Join-Path (Join-Path (Get-HomeDirectory) ".ssh") "id_$keyType"
}

# Reads a SecureString interactively using a confirmation prompt
function Read-SecureString {
  param(
    [String] $secureStringDescription = "SecureString"
  )
  # Securely compares two SecureString objects without decrypting
  function Compare-SecureString {
    param(
      [Security.SecureString] $secureString1,
      [Security.SecureString] $secureString2
    )
    try {
      $bstr1 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString1)
      $bstr2 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString2)
      $length1 = [Runtime.InteropServices.Marshal]::ReadInt32($bstr1,-4)
      $length2 = [Runtime.InteropServices.Marshal]::ReadInt32($bstr2,-4)
      if ( $length1 -ne $length2 ) {
        return $false
      }
      for ( $i = 0; $i -lt $length1; ++$i ) {
        $b1 = [Runtime.InteropServices.Marshal]::ReadByte($bstr1,$i)
        $b2 = [Runtime.InteropServices.Marshal]::ReadByte($bstr2,$i)
        if ( $b1 -ne $b2 ) {
          return $false
        }
      }
      return $true
    }
    finally {
      if ( $bstr1 -ne [IntPtr]::Zero ) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr1)
      }
      if ( $bstr2 -ne [IntPtr]::Zero ) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr2)
      }
    }
  }
  do {
    $pass1 = Read-Host "Enter $secureStringDescription" -AsSecureString
    $pass2 = Read-Host "Confirm $secureStringDescription" -AsSecureString
    $match = Compare-SecureString $pass1 $pass2
    if ( -not $match ) {
      Write-Host "Entered values do not match"
    }
  } until ( $match )
  return $pass1
}

# Converts SecureString to String
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

#------------------------------------------------------------------------------
# Main script body
#------------------------------------------------------------------------------

# Prompt interactively for filename if not specified
if ( -not $FileName ) {
  $FileName = Get-DefaultKeyFileName $KeyType
  Write-Host "Key type: $KeyType"
  $Response = Read-Host "Enter file in which to save the key ($FileName)"
  if ( $Response ) {
    $FileName = $Response
  }
}

# Private key file must not already exist
if ( Test-Path -LiteralPath $FileName ) {
  Write-Error "File '$FileName' already exists." -Category ResourceExists
  exit $ERROR_ALREADY_EXISTS
}

# Prompt for passphrase if not specified
if ( $null -eq $Passphrase ) {
  $Passphrase = Read-SecureString "passphrase (leave empty for no passphrase)"
}

# Prompt for comment if not specified
if ( $Comment -eq "" ) {
  $Comment = Read-Host ("Comment ({0}@{1})" -f $Env:USERNAME,[Net.Dns]::GetHostName())
}

# Validate comment
if ( $Comment -like '*"*' ) {
  Write-Error 'Comment cannot contain " character.' -Category InvalidArgument
  exit $ERROR_INVALID_PARAMETER
}

# Validate passphrase
$Passphrase2 = ConvertTo-String $Passphrase
if ( $Passphrase2 -like '*"*' ) {
  Write-Error 'Passphrase cannot contain " character.' -Category InvalidArgument
  exit $ERROR_INVALID_PARAMETER
}

# Create array of command-line arguments
$ArgList = @(
  "-t",$KeyType,
  "-N",('"{0}"' -f $Passphrase2),
  "-f",('"{0}"' -f (& $CYGPATH $FileName))
)
if ( $Comment -ne "" ) {
  $ArgList += "-C",$Comment
}
if ( -not (($KeyType -eq "ecdsa-sk") -or ($KeyType -eq "ed25519") -or ($KeyType -eq "ed25519-sk")) ) {
  $ArgList += "-b",$Bits
}
if ( $PSBoundParameters.ContainsKey("Rounds") ) {
  $ArgList += "-a",$Rounds
}
if ( $Quiet ) {
  $ArgList += "-q"
}

# Ensure output field separator is a space (see about_Preference_Variables)
$OFS = " "

# Run the ssh-keygen command
& $SSH_KEYGEN $ArgList
$ExitCode = $LASTEXITCODE
Remove-Variable Passphrase2

# If ssh-keygen succeeded and private key file exists, restrict permissions
if ( ($ExitCode -eq 0) -and (Test-Path -LiteralPath $FileName) ) {
  & $SETACL -ot file -on $FileName -actn ace -ace "n:S-1-5-18;p:full" -actn ace -ace ("n:{0};p:full" -f [Security.Principal.WindowsIdentity]::GetCurrent().Name) -actn setprot -op "dacl:p_nc" > $null
  $ExitCode = $LASTEXITCODE
  if ( $ExitCode -eq 0 ) {
    if ( -not $Quiet ) {
      Write-Host "Restricted permissions on file '$FileName'."
    }
  }
  else {
    Write-Warning "Unable to restrict permissions on file '$FileName'. Make sure its permissions are appropriate."
  }
}

exit $ExitCode
