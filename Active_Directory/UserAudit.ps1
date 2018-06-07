# User Audit by Liam Glanfield
# 10-02-2017
# 07-06-2018 - Updatd to something useful
param($UserCLIXML)

$DaysActive = 60
$Properties = @(
'SamAccountName'
'Enabled'
'LockedOut'
'PasswordExpired'
'PasswordNeverExpires'
'CannotChangePassword'
'PasswordNotRequired'
'LastLogonDate'
'PasswordLastSet'
'LastBadPasswordAttempt'
'DoesNotRequirePreAuth'
'AllowReversiblePasswordEncryption'
'TrustedForDelegation'
'TrustedToAuthForDelegation'
'AccountExpirationDate'
'Created'
'Modified'
)
$Output = @()

Write-Progress -Activity 'Auditing user objects' -Status 'Obtaining a list of users' -Id 1 -PercentComplete 14

# grab user data
if($UserCLIXML)
{
    $TodaysDate = (Get-Item $UserCLIXML).LastWriteTime
    $Users = Import-Clixml $UserCLIXML
}else{
    Import-Module ActiveDirectory
    $Users = Get-ADUser -Filter * -Properties $Properties
    $Users | Export-Clixml ADUsers_Data.xml -Depth 2
    $TodaysDate = Get-Date
}

# add AccountActive property to the object
Write-Progress -Activity 'Auditing user objects' -Status 'Marking user accounts as active or inactive' -Id 1 -PercentComplete 28
$OnePercent = 100 / $Users.Count
$Step = 1
$Users | foreach {
    Write-Progress -Activity "Processing user $($_.samaccountname)"  -Id 2 -PercentComplete $($OnePercent * $Step)
    $Step++

    if(($_.LastLogonDate -eq $null -or $TodaysDate.adddays(-$DaysActive) -gt $_.LastLogonDate) -and ( $_.AccountExpirationDate -eq $null -or $_.AccountExpirationDate -gt $TodaysDate )){
        $_ | Add-Member -MemberType NoteProperty -Name AccountActive -Value $false
    }else{
        if($_.Enabled)
        {
            $_ | Add-Member -MemberType NoteProperty -Name AccountActive -Value $true
        }else{
            $_ | Add-Member -MemberType NoteProperty -Name AccountActive -Value $false
        }
    }
}
Write-Progress -Activity "finished"  -Id 2 -Completed


# get counts
Write-Progress -Activity 'Auditing user objects' -Status 'Getting enabled user count' -Id 1 -PercentComplete 42
$EnabledUserCount = @($Users | Where-Object { $_.Enabled -eq $true }).Count

# Process finding: Inadequate User Account Password Configuration
Write-Progress -Activity 'Auditing user objects' -Status 'Finding users with UserAccountControl issues' -Id 1 -PercentComplete 56
$PasswordIssues = $Users | Where-Object {
# First place an or statement for anything bad
($_.PasswordNotRequired -eq $true -or $_.PasswordNeverExpires -eq $true -or $_.CannotChangePassword -eq $true -or $_.AllowReversiblePasswordEncryption -eq $true) `
-and `
$_.enabled
}

# first count
Write-Progress -Activity 'Auditing user objects' -Status 'Building a UserAccountControl summary table' -Id 1 -PercentComplete 70
$PasswordNotRequired = $PasswordIssues | ?{ $_.PasswordNotRequired -eq $true }
$PasswordNeverExpires = $PasswordIssues | ?{ $_.PasswordNeverExpires -eq $true }
$CannotChangePassword = $PasswordIssues | ?{ $_.CannotChangePassword -eq $true }
$AllowReversiblePasswordEncryption = $PasswordIssues | ?{ $_.AllowReversiblePasswordEncryption -eq $true }

$SummaryTable = @()

if($PasswordNotRequired.Count -gt 0)
{
    $PasswordNotRequired_Active = "$([System.Math]::Round((100 / $PasswordNotRequired.Count) * ($PasswordNotRequired | Group-Object AccountActive | Where-Object { $_.Name -eq 'True' } | Select-Object -ExpandProperty Count)))%"
    $PasswordNotRequired_InActive = "$([System.Math]::Round((100 / $PasswordNotRequired.Count) * ($PasswordNotRequired | Group-Object AccountActive | Where-Object { $_.Name -eq 'False' } | Select-Object -ExpandProperty Count)))%"
    $SummaryTable += @{Configuration='Password Not Required';'Total User Count'=$('{0:N0}' -f $PasswordNotRequired.count);'Active Accounts'=$PasswordNotRequired_Active;'Inactive Users'=$PasswordNotRequired_InActive}
}

if($PasswordNeverExpires.Count -gt 0)
{
    $PasswordNeverExpires_Active = "$([System.Math]::Round((100 / $PasswordNeverExpires.Count) * ($PasswordNeverExpires | Group-Object AccountActive | Where-Object { $_.Name -eq 'True' } | Select-Object -ExpandProperty Count)))%"
    $PasswordNeverExpires_InActive = "$([System.Math]::Round((100 / $PasswordNeverExpires.Count) * ($PasswordNeverExpires | Group-Object AccountActive | Where-Object { $_.Name -eq 'False' } | Select-Object -ExpandProperty Count)))%"
    $SummaryTable += @{Configuration='Password Never Expires';'Total User Count'=$('{0:N0}' -f $PasswordNeverExpires.count);'Active Accounts'=$PasswordNeverExpires_Active;'Inactive Users'=$PasswordNeverExpires_InActive}
}

if($CannotChangePassword.Count -gt 0)
{
    $CannotChangePassword_Active = "$([System.Math]::Round((100 / $CannotChangePassword.Count) * ($CannotChangePassword | Group-Object AccountActive | Where-Object { $_.Name -eq 'True' } | Select-Object -ExpandProperty Count)))%"
    $CannotChangePassword_InActive = "$([System.Math]::Round((100 / $CannotChangePassword.Count) * ($CannotChangePassword | Group-Object AccountActive | Where-Object { $_.Name -eq 'False' } | Select-Object -ExpandProperty Count)))%"
    $SummaryTable += @{Configuration='Cannot Change Password';'Total User Count'=$('{0:N0}' -f $CannotChangePassword.count);'Active Accounts'=$CannotChangePassword_Active;'Inactive Users'=$CannotChangePassword_InActive}
}

if($AllowReversiblePasswordEncryption.Count -gt 0)
{
    $AllowReversiblePasswordEncryption_InActive = "$([System.Math]::Round((100 / $AllowReversiblePasswordEncryption.Count) * ($AllowReversiblePasswordEncryption | Group-Object AccountActive | Where-Object { $_.Name -eq 'False' } | Select-Object -ExpandProperty Count)))%"
    $AllowReversiblePasswordEncryption_Active = "$([System.Math]::Round((100 / $AllowReversiblePasswordEncryption.Count) * ($AllowReversiblePasswordEncryption | Group-Object AccountActive | Where-Object { $_.Name -eq 'True' } | Select-Object -ExpandProperty Count)))%"
    $AllowReversiblePasswordEncryption += @{Configuration='Allow Reversible Password Encryption';'Total User Count'=$('{0:N0}' -f $AllowReversiblePasswordEncryption.count);'Active Accounts'=$AllowReversiblePasswordEncryption_Active;'Inactive Users'=$AllowReversiblePasswordEncryption_Active}
}

# build a summary table and calc percentages
$SummaryTable = $SummaryTable | %{ New-Object psobject -Property $_ }

Write-Progress -Activity 'Auditing user objects' -Status 'Building the results hash table for UserAccountControl' -Id 1 -PercentComplete 84
$FindingDetail = @"
Out of the $('{0:N0}' -f $EnabledUserCount) enabled user accounts there were $('{0:N0}' -f $PasswordIssues.count) user accounts with inadequate configuration, the following issues were identified:
<<SummaryTable>>
"@
$Output += @{
                Title = 'Inadequate UserAccountControl Configuration'
                Detail = $FindingDetail
                Results = $($PasswordIssues | Select-Object SamAccountName, PasswordNotRequired, PasswordNeverExpires, CannotChangePassword, AllowReversiblePasswordEncryption, AccountActive)
                SummaryTable = $SummaryTable
            }

Write-Progress -Activity 'Auditing user objects' -Status 'Building the results hash table for inactive or unused accounts' -Id 1 -PercentComplete 98

$FindingDetail = "Out of the $('{0:N0}' -f $EnabledUserCount) enabled user accounts there were $('{0:N0}' -f ($Users | ?{ $_.AccountActive -eq $false -and $_.Enabled -eq $true}).count) inactive or unused user accounts."
$Output += @{
                Title = 'Inactive or Unused User Accounts'
                Detail = $FindingDetail
                Results = $($Users | ?{ $_.AccountActive -eq $false -and $_.Enabled -eq $true} | Select-Object SamAccountName, LastLogonDate, AccountExpirationDate, PasswordLastSet)
                SummaryTable = $null
            }

Write-Progress -Activity 'Auditing user objects' -Status 'All completed!' -Id 1 -PercentComplete 100
# return result
$Output | %{ New-Object psobject -Property $_ }
