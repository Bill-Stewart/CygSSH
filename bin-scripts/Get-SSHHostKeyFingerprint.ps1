# Get-SSHHostKeyFingerprint.ps1
# Written by Bill Stewart (bstewart at iname.com)

#requires -version 3

<#
.SYNOPSIS
Gets SSH host key fingerprint(s) from one or more computer(s).

.DESCRIPTION
Gets SSH host key fingerprint(s) from one or more computer(s).

.PARAMETER HashType
Outputs fingerprints using this hash algorithm (md5 or sha256). the default is sha256.

.PARAMETER ComputerName
Specifies one or more computer names. Wildcards are not permitted. If you omit this parameter, the current computer is used.

.PARAMETER KeyType
Specifies the key algorithm type(s) for which to get host key fingerprints. Possible values are "dsa", "ecdsa", "ecdsa-sk", "ed25519", "ed25519-sk", and "rsa". The default is all except "dsa".

.PARAMETER Port
Connects to the specified port. The default port is 22.

.PARAMETER Timeout
Sets the timeout, in seconds, for connection attempts. If the timeout has elapsed since a connection was initiated to a computer or since the last time anything was read from that computer, the connection is closed and the computer is considered unavailable. The default timeout is 5 seconds.

.OUTPUTS
Outputs objects with the following properties:
* ComputerName - computer name
* KeyType      - host key algorithm type
* Size         - number of bits in the host key
* HashType     - hash algorithm used to display the host key fingerprint
* Fingerprint  - host key fingerprint
#>

param(
  [Parameter(Position = 0)]
  [ValidateSet("md5","sha256")]
  [String]
  $HashType = "sha256",

  [Parameter(Position = 1,ValueFromPipeline)]
  [String[]]
  $ComputerName,

  [String[]]
  $KeyType,

  [Int]
  $Port = 22,

  [Int]
  $Timeout
)

begin {
  $SSH_KEYGEN = Join-Path $PSScriptRoot "ssh-keygen"
  Get-Command $SSH_KEYGEN -ErrorAction Stop | Out-Null
  $SSH_KEYSCAN = Join-Path $PSScriptRoot "ssh-keyscan"
  Get-Command $SSH_KEYSCAN -ErrorAction Stop | Out-Null

  $RegexRow = '^([^ ]+) +([^:]+):([^ ]+) +([^ ]+) +\(([^)]+)\)'

  function Get-HostKeyFingerprint {
    param(
      $ComputerName
    )
    $scanParams = @("-p",($Port -as [String]),"-q")
    if ( $null -ne $KeyType ) {
      $scanParams += '-t',('"{0}"' -f ($KeyType -join ','))
    }
    if ( $Timeout -ne 0 ) {
      $scanParams += '-T',($Timeout -as [String])
    }
    $scanParams += '"{0}"' -f $ComputerName
    $genParams += '-E',('"{0}"' -f $HashType),'-lf','-'
    & ([scriptblock]::Create(('& "{0}" {1} | & "{2}" {3}' -f $SSH_KEYSCAN,($scanParams -join ' '),$SSH_KEYGEN,($genParams -join ' ')))) | ForEach-Object {
      $rowMatch = [Regex]::Match($_,$RegexRow)
      [PSCustomObject] @{
        "ComputerName" = $computerName
        "Port"         = $Port
        "KeyType"      = $rowMatch.Groups[5].Value
        "Size"         = $rowMatch.Groups[1].Value -as [Int]
        "HashType"     = $rowMatch.Groups[2].Value
        "Fingerprint"  = $rowMatch.Groups[3].Value
      }
    }
  }
}

process {
  if ( $ComputerName ) {
    foreach ( $ComputerNameItem in $ComputerName ) {
      Get-HostKeyFingerprint $ComputerNameItem
    }
  }
  else {
    Get-HostKeyFingerprint ([Net.Dns]::GetHostEntry("localhost").HostName)
  }
}
