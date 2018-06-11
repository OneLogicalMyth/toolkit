function Merge-CSV {
param([string]$CSV,[string]$PropertyToCombine,[string[]]$DuplicateProperties)

    $CSVObj = Import-Csv $CSV
    $Merged = $CSVObj | Group-Object $DuplicateProperties
    
    Foreach($Item in $Merged){

        $Hosts = $Item.Group.$PropertyToCombine -join ','
        
        $FirstRow = $null
        $FirstRow = $Item.Group | Select-Object -First 1
        $FirstRow.$PropertyToCombine = $Hosts
        $FirstRow

    }


}

# Merge-CSV -CSV file.csv -PropertyToCombine Hostname -DuplicateProperties Detail1, Detail2, Detail3
# Will select a unquie Detail1, Detail2, Detail3 combo and combine the Hostname so that there is only one row
