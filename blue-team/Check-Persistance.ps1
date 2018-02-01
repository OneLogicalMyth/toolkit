Function Check-Persistance {

    $Shell = New-Object -ComObject WScript.Shell
    $Registry = Get-WmiObject Win32_StartupCommand -Filter "NOT Location LIKE '%startup%'"
    $Startup = Get-ChildItem "C:\Users\*\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\*","C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\*"
    
    foreach($file in $startup)
    {        
        if($file.Extension -eq '.lnk')
        {
            $ShortcutInfo = $Shell.CreateShortcut($file.FullName)

            $Out = '' | Select-Object Location, Command, Description
            $Out.Location = $ShortcutInfo.FullName
            $Out.Command = "$($ShortcutInfo.TargetPath) $($ShortcutInfo.Arguments)"
            $Out.Description = $ShortcutInfo.Description
            $Out

            Remove-Variable ShortcutInfo

        }else{

            $Out = '' | Select-Object Location, Command, Description
            $Out.Location = $file.FullName
            $Out.Command = $file.FullName
            $Out.Description = $null
            $Out
            
        }

        Remove-Variable file,out
    }

    
    foreach($item in $Registry)
    {
        $Out = '' | Select-Object Location, Command, Description
        $Out.Location = $item.Location
        $Out.Command = $item.Command
        $Out.Description = $item.Caption
        $Out
        
        Remove-Variable item,out    
    }

}
