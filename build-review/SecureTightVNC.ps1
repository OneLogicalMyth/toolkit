<#
    These rules are designed for domain joined machines only.
    Usage, launch PowerShell as administrator.
    
    Import-Module .\SecureTightVNC.ps1
    
    # Secure incoming connections i.e. run on a system with TightVNC installed    
    Secure-IncomingTightVNC

    # Secure outgoing connections i.e. administrative machine used for connecting to TightVNC
    Secure-OutgoingTightVNC

    # Remove all rules created and clean up
    Remove-TightVNCRules
#>

function Get-SDDL($SID){
    # Returns an allow access SDDL
    return "D:(A;;CC;;;$SID)"
}

function Create-AuthSet {
[CmdletBinding()]
param([switch]$NoCreation)

    # Check if we need to create a new one if so create it for computer and the user

    $AuthMachine = Get-NetIPsecPhase1AuthSet -DisplayName 'Computer Kerb Auth' -ErrorAction SilentlyContinue
    if($AuthMachine -eq $null -and $NoCreation -eq $false)
    {
        Write-Verbose "No NetIPsecPhase1AuthSet found, creating a new one."
        $MachineKerb = New-NetIPsecAuthProposal -Machine -Kerberos
        $AuthMachine = New-NetIPsecPhase1AuthSet -DisplayName "Computer Kerb Auth" -Proposal $MachineKerb
        Write-Verbose "NetIPsecPhase1AuthSet created."
    }
    Write-Verbose "NetIPsecPhase1AuthSet name is $($AuthMachine.Name)."

    $AuthUser = Get-NetIPsecPhase2AuthSet -DisplayName 'User Kerb Auth' -ErrorAction SilentlyContinue
    if($AuthUser -eq $null -and $NoCreation -eq $false)
    {
        Write-Verbose "No NetIPsecPhase2AuthSet found, creating a new one."
        $UserKerb = New-NetIPsecAuthProposal -User -Kerberos    
        $AuthUser = New-NetIPsecPhase2AuthSet -DisplayName "User Kerb Auth" -Proposal $UserKerb
        Write-Verbose "NetIPsecPhase2AuthSet created."
    }
    Write-Verbose "NetIPsecPhase2AuthSet name is $($AuthUser.Name)."

    # We only need the GUID returned
    return New-Object psobject -Property @{
            Auth1 = $AuthMachine.Name
            Auth2 = $AuthUser.Name
        }
}

function Remove-TightVNCRules {
[CmdletBinding()]
param()

    $IncomingRule = Get-NetIPsecRule -DisplayName 'Secure Incoming TightVNC' -ErrorAction SilentlyContinue
    $OutgoingRule = Get-NetIPsecRule -DisplayName 'Secure Outgoing TightVNC' -ErrorAction SilentlyContinue
    if($IncomingRule.DisplayName -ne $null)
    {
        $IncomingRule | Remove-NetIPsecRule -ErrorAction SilentlyContinue
    }
    if($OutgoingRule.DisplayName -ne $null)
    {
        $OutgoingRule | Remove-NetIPsecRule -ErrorAction SilentlyContinue
    }

    $AuthSet = Create-AuthSet -NoCreation
    if($AuthSet.Auth1 -ne $null)
    {
        Remove-NetIPsecPhase1AuthSet -Name $AuthSet.Auth1 -ErrorAction SilentlyContinue
    }
    if($AuthSet.Auth2 -ne $null)
    {
        Remove-NetIPsecPhase2AuthSet -Name $AuthSet.Auth2 -ErrorAction SilentlyContinue
    }    

    $FWRule = Get-NetFirewallRule -DisplayName 'Allow Authenticated TightVNC' -ErrorAction SilentlyContinue
    if($FWRule -ne $null)
    {
        $FWRule | Remove-NetFirewallRule -ErrorAction SilentlyContinue
    }
}


# Secure TightVNC Service
function Secure-IncomingTightVNC {
[CmdletBinding()]
param([int[]]$TightVNCPorts = (5800,5900))

    # get or create auth set
    $AuthSet = Create-AuthSet

    # Create a connection security rule to encapsulate and isolate the TightVNC service
    $NetSecRule = @{
        DisplayName = "Secure Incoming TightVNC"
        InboundSecurity = 'Require'
        OutboundSecurity = 'Request'
        Phase1AuthSet = $AuthSet.Auth1
        Phase2AuthSet = $AuthSet.Auth2
        Protocol = 'TCP'
        LocalPort = $TightVNCPorts
    }
    New-NetIPsecRule @NetSecRule

    # Secure the TightVNC to local administrators only
    $NetFirewallRule = @{
        DisplayName = "Allow Authenticated TightVNC"
        Direction = 'Inbound'
        LocalPort = $TightVNCPorts
        Protocol = 'TCP'
        Authentication = 'Required'
        Action = 'Allow'

        # Must be a member of the administrators group to access the service
        RemoteUser = Get-SDDL (Get-LocalGroup -Name Administrators).SID.Value
    }
    New-NetFirewallRule @NetFirewallRule
}


# Connect to TightVNC Service
function Secure-OutgoingTightVNC {
[CmdletBinding()]
param([int[]]$TightVNCPorts = (5800,5900))
   
    # get or create auth set
    $AuthSet = Create-AuthSet

    # Create a connection security rule to encapsulate and isolate the TightVNC service
    $NetSecRule = @{
        DisplayName = "Secure Outgoing TightVNC"
        InboundSecurity = 'Request'
        OutboundSecurity = 'Request'
        Phase1AuthSet = $AuthSet.Auth1
        Phase2AuthSet = $AuthSet.Auth2
        Protocol = 'TCP'
        RemotePort = $TightVNCPorts
    }
    New-NetIPsecRule @NetSecRule
}
