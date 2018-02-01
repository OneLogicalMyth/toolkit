Function Merge-Nessus {
param([string]$InputFolder=".\",[string]$OutputFile='__Merged_Nessus_Report__')

    begin
    {
        # convert to full path to XML save
        $InputFolder = (Resolve-Path -Path $InputFolder).Path -replace 'Microsoft.PowerShell.Core\\FileSystem::'
        # collate a list of nessus files to process
        Write-Host "Collecting a list of Nessus files from $InputFolder"
        $NessusFiles = Get-ChildItem -Path $InputFolder -Filter *.nessus        
    }

    process
    {
        # set flag to capture first file and use as template
        $First = $true

        Foreach($NessusFile in $NessusFiles)
        {
            # convert Nessus file into XML object
            [xml]$NessusData = Get-Content $NessusFile.FullName

            if($First)
            {
                # update report name
                $ReportRoot  = $NessusData
                $Report      = $NessusData.SelectSingleNode('//Report')
                $Report.name = 'Merged Report'
                $First = $false
            }else{
            
                # grab hosts from the node
                $Devices = $NessusData.SelectSingleNode('//ReportHost')

                # cycle through the hosts
                Foreach($Device in $Devices)
                {
                    Write-Host "Checking if $($Device.name) needs to be merged"
                    # check if the host exists within the primary report
                    $IsExistingHost = $Report.SelectSingleNode("//ReportHost[@name='$($Device.name)']")
                    if(-not $IsExistingHost)
                    {
                        Write-Host "$($Device.name) is being merged"
                        $NewHost = $ReportRoot.CreateElement('ReportHost')
                        $NewHost.InnerXml = $Device.InnerXml
                        $NewHost.SetAttribute('name',$Device.name)
                        $Report.AppendChild($NewHost) | Out-Null
                    }else{
                        Write-Host 'ToDo'
                    }
                    
                }# end foreach hosts            
            
        
            }# end if first


            # tidy up to stop duplicated data and incorrect results
            Remove-Variable -Name NessusData, Device, Devices -ErrorAction SilentlyContinue

        }# end foreach NessusFiles
    }

    end
    {
        # save nessus file to input folder location
        if(($OutputFile -like '*.nessus'))
        {
            $OutFile = Join-Path $InputFolder $OutputFile
        }else{
            $OutFile = Join-Path $InputFolder ($OutputFile + '.nessus')
        }

        # save merged report
        Write-Host "Saving merged report to $OutFile"
        $ReportRoot.Save($OutFile)
        

    }

}
