
# run within a folder containing Palo Alto Networks configs
Get-ChildItem -Filter *.xml | %{

    $file = $_
    [xml]$xml = Get-Content $file.FullName
    $xml.config.'mgt-config'.users.entry | select @{n='FileName';e={$file.Name}}, name, @{n='Superuser';e={$_.permissions.'role-based'.superuser}}, phash

} | Export-Csv PaloAltoUsers.csv -NoTypeInfo
