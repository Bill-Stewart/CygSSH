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
* HostType     - host server type and version
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
  $Port,

  [Int]
  $Timeout
)

begin {
  $SSH_KEYGEN = Join-Path $PSScriptRoot "ssh-keygen"
  Get-Command $SSH_KEYGEN -ErrorAction Stop | Out-Null
  $SSH_KEYSCAN = Join-Path $PSScriptRoot "ssh-keyscan"
  Get-Command $SSH_KEYSCAN -ErrorAction Stop | Out-Null

  $regexHost = '^[^ ]+ +([^:]+):([^ ]+) +(.*)'
  $regexRow = '^([^ ]+) +([^:]+):([^ ]+) +([^ ]+) +\(([^)]+)\)'

  function Get-HostKeyFingerprint {
    param(
      $computerName
    )
    $stdErr = [IO.Path]::GetTempFileName()
    $stdOut = [IO.Path]::GetTempFileName()
    $params = @{
      "FilePath"               = $SSH_KEYSCAN
      "ArgumentList"           = @()
      "PassThru"               = $true
      "RedirectStandardError"  = $stdErr
      "RedirectStandardOutput" = $StdOut
      "Wait"                   = $true
      "WindowStyle"            = [Diagnostics.ProcessWindowStyle]::Hidden
    }
    if ( $null -ne $KeyType ) {
      $params.ArgumentList += ("-t {0}" -f ($KeyType -join ','))
    }
    if ( $Port -ne 0 ) {
      $params.ArgumentList += ("-p {0}" -f $Port)
    }
    if ( $Timeout -ne 0 ) {
      $params.ArgumentList += ("-T {0}" -f $Timeout)
    }
    $params.ArgumentList += $computerName
    $process = Start-Process @params
    $exitCode = $process.ExitCode
    $errorOutput = Get-Content $stdErr
    if ( $exitCode -eq 0 ) {
      $hostMatch = [Regex]::Match(($errorOutput | Select-Object -First 1),$regexHost)
      & $SSH_KEYGEN -E $HashType -l -f $stdOut | ForEach-Object {
      $rowMatch = [Regex]::Match($_,$regexRow) 
        [PSCustomObject] @{
          "ComputerName" = $hostMatch.Groups[1].Value
          "Port"         = $hostMatch.Groups[2].Value -as [Int]
          "HostType"     = $hostMatch.Groups[3].Value
          "KeyType"      = $rowMatch.Groups[5].Value
          "Size"         = $rowMatch.Groups[1].Value -as [Int]
          "HashType"     = $rowMatch.Groups[2].Value
          "Fingerprint"  = $rowMatch.Groups[3].Value
        }
      }
    }
    else {
      if ( ($errorOutput | Select-Object -First 1) -notmatch '^#') {
        Write-Error ("Unable to get host key fingerprint from '{0}' due to the following error: '{1}'" -f
          $computerName,($errorOutput -join [Environment]::NewLine))
      }
    }
    Remove-Item $stdErr,$stdOut
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
