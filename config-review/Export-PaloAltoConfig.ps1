#Requires -Modules ImportExcel
param([string]$InputFolder = '.\', [string]$ExcelOutputFile = '.\PaloAltoExport.xlsx')

if((Get-Item $InputFolder).PSIsContainer -eq $false)
{
    Write-Error 'Input folder is not a folder'
    return
}

$allFiles = Get-ChildItem -Path $InputFolder -Filter *.xml -File

foreach($PaloConfigFile in $allFiles)
{

    [xml]$Global:PaloConfig = Get-Content $PaloConfigFile

    $userHashes += $PaloConfig.config.'mgt-config'.users.entry | 
    select @{n='FileName';e={(Get-Item $PaloConfigFile).Name}},
    name, @{n='Superuser';e={$_.permissions.'role-based'.superuser}}, phash

    $rule_types = @{
        rulebase_security = @('//config/devices/entry/vsys/entry', './rulebase/security/rules/entry')
        pre_rulebase_sec = @('//config/devices/entry/device-group/entry', './pre-rulebase/security/rules/entry')
        post_rulebase_sec = @('//config/devices/entry/device-group/entry', './post-rulebase/security/rules/entry')
        pre_rulebase_decrypt = @('//config/devices/entry/device-group/entry', './pre-rulebase/decryption/rules/entry')
        post_rulebase_decrypt = @('//config/devices/entry/device-group/entry', './post-rulebase/decryption/rules/entry')
        }

    $fwRules += $rule_types.Keys | %{
    
        $currentKey = $_
        $fwEntries = $PaloConfig.SelectNodes($rule_types[$currentKey][0])

        Write-Host "Enumerating rules for $_"
        Write-Host ($rule_types[$currentKey][0])
        foreach($entry in $fwEntries)
        {
            Write-Host ($rule_types[$currentKey][1])
            foreach($rule in $entry.SelectNodes($rule_types[$currentKey][1]))
            {
            
                [PSCustomObject]@{
                fwname = $PaloConfig.SelectSingleNode('//config/devices/entry/deviceconfig/system').hostname
                type = $currentKey
                rulename      = $rule.name
                frominterface = $rule.from.member  -join "; "
                tointerface   = $rule.to.member  -join "; "
                source        = $rule.source.member  -join "; "
                sourcenegate  = $rule.'negate-source'
                destination   = $rule.destination.member  -join "; "
                targetnegate  = $rule.target.negate
                destnegate    = $rule.'negate-destination'
                sourceuser    = $rule.'source-user'.member  -join "; "
                category      = $rule.category.member  -join "; "
                application   = $rule.application.member  -join "; "
                service       = $rule.service.member  -join "; "
                hip_profiles  = $rule.'hip-profiles'.member  -join "; "
                action        = $rule.action  -join "; "
                description   = $rule.description  -join "; "
                disabled      = $rule.disabled  -join "; "
                logging       = $rule.'log-setting'
                }
            }

        }

    }

}


Remove-Item $ExcelOutputFile
$fileNames = $allFiles | Select-Object -ExpandProperty FullName
$fileNames | Export-Excel -Path $ExcelOutputFile -WorksheetName 'Files Parsed' -AutoSize -AutoFilter
$userHashes | Export-Excel -Path $ExcelOutputFile -WorksheetName 'Hashes' -AutoSize -AutoFilter
$fwRules | Export-Excel -Path $ExcelOutputFile -WorksheetName 'Rules' -AutoSize -AutoFilter -Show
