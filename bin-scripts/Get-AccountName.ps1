# Get-AccountName.ps1
# Written by Bill Stewart (bstewart at iname.com)

#requires -version 2

<#
.SYNOPSIS
Gets the full Windows account name and Cygwin name for an account name.

.DESCRIPTION
Gets the full Windows account name and Cygwin name for an account name.

.PARAMETER AccountName
Specifies one or more account names. Wildcards are not permitted. If you omit the account name, the current account is used.

.OUTPUTS
Outputs objects with the following properties:
* WindowsName - the full Windows account name (DOMAIN\name or COMPUTER\Name)
* CygwinName  - the associated Cygwin account name

.NOTES
If the current computer is a domain member, names are matched against the domain before the current computer's local account database.
#>

param(
  [Parameter(ValueFromPipeline)]
  [String[]]
  $AccountName
)

begin {
  $ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent

  # Adds Win32API type definitions
  Add-Type -Name Win32API `
    -MemberDefinition (Get-Content -LiteralPath (Join-Path $ScriptPath "Win32API.def") -ErrorAction Stop | Out-String -Width ([Int]::MaxValue)) `
    -Namespace "BCA37B9C41264685AD47EEBBD02F40EF" `
    -ErrorAction Stop
  $Win32API = [BCA37B9C41264685AD47EEBBD02F40EF.Win32API]

  # Uses NetGetJoinInformation Windows API to determine current computer's
  # join information; if successful, returns a PSObject with two members:
  # * IsDomainMember - $true if the computer is joined to a domain,
  #   or $false otherwise
  # * WorkgroupOrDomainName - the computer's workgroup or domain name
  # Returns nothing if it fails
  function Get-JoinInformation {
    $nameBuffer = [IntPtr]::Zero
    $joinStatus = 0
    try {
      $result = $Win32API::NetGetJoinInformation(
        $null,              # lpServer
        [Ref] $nameBuffer,  # lpNameBuffer
        [Ref] $joinStatus)  # BufferType
      if ( $result -eq 0 ) {
        New-Object PSObject -Property @{
          "IsDomainMember"        = $joinStatus -eq 3  # NetSetupDomainName
          "WorkgroupOrDomainName" = [Runtime.InteropServices.Marshal]::PtrToStringAuto($nameBuffer)
        }
      }
    }
    finally {
      if ( $nameBuffer -ne [IntPtr]::Zero ) {
        [Void] $Win32API::NetApiBufferFree($nameBuffer)
      }
    }
  }

  # Get computer's join information as a PSObject
  $JoinInfo = Get-JoinInformation
  if ( -not $JoinInfo ) {
    throw "Unable to get computer join information."
  }

  # Ignore these authority names when we output Cygwin account name
  $IgnoreAuthorities = @(
    "BUILTIN"
    "NT AUTHORITY"
  )

  # Resolves an account name to its full 'authority\name' representation
  function Resolve-AccountName {
    param(
        [Security.Principal.NTAccount]
        $name
    )
    try {
      $sid = $name.Translate([Security.Principal.SecurityIdentifier])
      $sid.Translate([Security.Principal.NTAccount]).Value
    }
    catch [Security.Principal.IdentityNotMappedException] {
    }
  }

  function Get-IdentityInfo {
    param(
      [Security.Principal.NTAccount]
      $name
    )
    $resolvedName = $null
    if ( $name.Value.IndexOf("\") -eq -1 ) {
      if ( $JoinInfo.IsDomainMember ) {
        # Assume domain account if no authority and computer is domain member
        $resolvedName = Resolve-AccountName ("{0}\{1}" -f $JoinInfo.WorkgroupOrDomainName,$name.Value)
      }
    }
    if ( $null -eq $resolvedName ) {
      $resolvedName = Resolve-AccountName $name
      if ( $null -eq $resolvedName ) {
        Write-Error "Unable to resolve account name - '$name'." -Category ObjectNotFound
        return
      }
    }
    # Create output object
    $identityObject = New-Object PSObject -Property @{
      "WindowsName" = $resolvedName
      "CygwinName"  = $null
    } | Select-Object WindowsName,CygwinName
    if ( $resolvedName.IndexOf("\") -eq -1 ) {
      # Names without authority: Cygwin name matches resolved name
      $identityObject.CygwinName = $resolvedName
    }
    else {
      $authorityName = $resolvedName.Split("\")[0]
      $accountName = $resolvedName.Split("\")[1]
      if ( $IgnoreAuthorities -contains $authorityName ) {
        $identityObject.CygwinName = $accountName
      }
      else {
        if ( $JoinInfo.IsDomainMember ) {
          if ( $authorityName -eq $JoinInfo.WorkgroupOrDomainName ) {
            $identityObject.CygwinName = $accountName
          }
          else {
            $identityObject.CygwinName = "{0}+{1}" -f $authorityName,$accountName
          }
        }
        else {
          $identityObject.CygwinName = $accountName
        }
      }
    }
    return $identityObject
  }
}

process {
  if ( $AccountName ) {
    foreach ( $AccountNameItem in $AccountName ) {
      Get-IdentityInfo $AccountNameItem
    }
  }
  else {
    Get-IdentityInfo ([Security.Principal.WindowsIdentity]::GetCurrent().Name)
  }
}
