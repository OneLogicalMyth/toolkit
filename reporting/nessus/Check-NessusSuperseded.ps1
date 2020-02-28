Function Check-NessusSuperseded {
param($NessusFile)

    [xml]$XML = Get-Content $NessusFile


    # Get superseded update configuration
    $Superseded = $XML.SelectSingleNode('//pluginId[text()="66334"]').parentnode.selectedvalue

    # Grab targets
    $Targets = $XML.SelectSingleNode('//preference/name[text()="TARGET"]').parentnode.value

    [pscustomobject]@{
        superseded_enabled = $Superseded
        targets = $Targets
        nessus_file = $NessusFile
    }

}
