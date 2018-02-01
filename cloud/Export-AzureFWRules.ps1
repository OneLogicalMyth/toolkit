Function Export-AzureFWRules {
param($OutputFolder)

    Try {
      $Context = Get-AzureRmContext -ErrorAction Stop
    } Catch {
      if ($_ -like "*Login-AzureRmAccount to login*") {
        Login-AzureRmAccount
      }
    }

    if(-not $OutputFolder)
    {
        throw 'Please provide an output folder for the results!'
        return
    }


    $global:Interfaces = Get-AzureRmNetworkInterface

    $VirtualMachines = Get-AzureRmVM -Status | Foreach{

        $VM = $_
        
        foreach($IP in $_.NetworkProfile.NetworkInterfaces)
        {
            

            $Out = '' | Select-Object VMHostName, VMResourceGroup, VMLocation, PowerState, IP, NIC, PrimaryNIC, NSG
            $Out.VMHostName = $VM.Name
            $Out.VMResourceGroup = $VM.ResourceGroupName.ToLower()
            $Out.VMLocation = $VM.Location
            $Out.PowerState = $VM.PowerState
            $Out.NIC = $IP.id.split('/')[-1]
            $Out.PrimaryNIC = $IP.Primary
            
            $Intf = $Interfaces | Where-Object { $_.ResourceGroupName -eq $Out.VMResourceGroup -and $_.Name -eq $Out.NIC }
            $Out.IP = $Intf.IpConfigurations.PrivateIpAddress
            if($Intf.NetworkSecurityGroup.Id)
            {
                $Out.NSG = $Intf.NetworkSecurityGroup.Id.split('/')[-1]
            }

            $Out
        }
    }


    $NSGs = Get-AzureRmNetworkSecurityGroup
    $NetworkSecurityGroups = foreach($NSG in $NSGs)
    {
        $Rules = $NSG.SecurityRules | Sort-Object Direction, Priority
        foreach($Rule in $Rules)
        {
            $Out = '' | Select-Object NSGName, NSGResourceGroup, NSGLocation, NICs, Subnets, RuleName, RuleDescription, Protocol, SourcePortRange, DestinationPortRange, SourceAddressPrefix, DestinationAddressPrefix, Access, Priority, Direction
            $Out.NSGName = $NSG.Name
            $Out.NSGResourceGroup = $NSG.ResourceGroupName
            $Out.NSGLocation = $NSG.Location
            if($NSG.NetworkInterfaces.id)
            {
                $Out.NICs = ( $NSG.NetworkInterfaces.id | foreach{ ($_ -split '/')[-1] } )  -join ','
            }
            if($NSG.Subnets)
            {
                $Out.Subnets = $NSG.Subnets -join ','
            }
            $Out.RuleName = $Rule.Name
            $Out.RuleDescription = $Rule.Description
            $Out.Protocol = $Rule.Protocol
            $Out.SourcePortRange = $Rule.SourcePortRange
            $Out.DestinationPortRange = $Rule.DestinationPortRange
            $Out.SourceAddressPrefix = $Rule.SourceAddressPrefix
            $Out.DestinationAddressPrefix = $Rule.DestinationAddressPrefix
            $Out.Access = $Rule.Access
            $Out.Priority = $Rule.Priority
            $Out.Direction = $Rule.Direction
            $Out

        }

    }

    # Export the results
    $NetworkSecurityGroups | Export-Csv (Join-Path $OutputFolder 'NetworkSecurityGroups.csv') -NoTypeInformation
    $VirtualMachines | Export-Csv (Join-Path $OutputFolder 'VirtualMachines.csv') -NoTypeInformation

    # Build rule HTML
    $HTMLSecurityRules = $NetworkSecurityGroups | Where-Object { $_.NICs -ne $null -or $_.subnets -ne $null } | Group-Object NSGName | Foreach {
    $Item = $_
    $ItemVMs = $VirtualMachines | Where-Object { $_.NSG -eq $Item.Name } | Select-Object VMHostName, VMResourceGroup, VMLocation, PowerState, IP, NIC, PrimaryNIC
    $ItemNSGs = $Item.Group | Select-Object RuleName, RuleDescription, Protocol, SourcePortRange, DestinationPortRange, SourceAddressPrefix, DestinationAddressPrefix, Access, Priority, Direction
@"
<div class="result">
<details>
<summary>Network Security Group - $($Item.Name)</summary>
<h3>Virtual Machines for $($Item.Name)</h3>
$($ItemVMs | ConvertTo-Html -Fragment)
<h3>Security Rules for $($Item.Name)</h3>
$($ItemNSGs | ConvertTo-Html -Fragment)
</details>
</div>
"@
    }

$HTML = @"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Azure FW Rules - $($Context.Subscription.Name)</title>
<style type="text/css">
body{font-family:Arial,Helvetica,sans-serif}table{color:#333;font-family:Helvetica,Arial,sans-serif;width:100%;border-collapse:collapse;border-spacing:0}td,th{border:1px solid transparent;height:30px;transition:all .3s}th{background:#DFDFDF;font-weight:700}td{background:#FAFAFA;text-align:center}tr:nth-child(even) td{background:#F1F1F1}tr:nth-child(odd) td{background:#FEFEFE}div.result{padding:25px;border-radius:16px;border-width:1px;border-style: solid; margin-top: 10px;}
</style>
</head>
<body>
<h1>Azure FW Rules - $($Context.Subscription.Name)</h1>
<p>Report generated at $((Get-Date).ToString())</p>
<h2>Virtual Machines with no Network Security Group</h2>
<p>These are virtual machines identified without an assigned NSG.</p>
<div class="result">
<details>
<summary>Click the arrow to show results</summary>
$($VirtualMachines | Select-Object VMHostName, VMResourceGroup, VMLocation, PowerState, IP, NIC, PrimaryNIC | ConvertTo-Html -Fragment)
</details>
</div>
<h2>Security Rules to Virtual Machines</h2>
<p>This displays the NSGs and the virtual machines asscioated with them, then security rules in place.</p>
$HTMLSecurityRules
<h2>Unused Security Rules</h2>
<p>These seucrity rules are from network security groups that do not contain a NIC or subnet assigment, thus an unrequired NSG.</p>
<div class="result">
<details>
<summary>Click the arrow to show results</summary>
$($NetworkSecurityGroups | Where-Object { $_.NICs -eq $null -and $_.subnets -eq $null } | Select-Object * -ExcludeProperty NICs,Subnets | ConvertTo-Html -Fragment)
</details>
</div>
</body>
</html>
"@

$HTML | Out-File (Join-Path $OutputFolder 'Report.html') -Encoding utf8

}
