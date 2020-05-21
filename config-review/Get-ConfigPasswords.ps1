#requires -version 5
param($SourceFolder,$OutputFolder='.\hashes')

# Function taken from;
# https://github.com/patient0x00/Decrypt-CiscoType7/blob/master/PowerShell
Function Decrypt-CiscoType7 ($Arg)
{
    $Key = $Arg
    $Constant = "tfd;kfoA,.iyewrkldJKD"
    $PassLength = $((($Key).Length) -2)/2

    $Password = New-Object System.Collections.Generic.List[string]

    $j = 0
    for($i=0; $i -lt $PassLength ; $i++)
    {
        [int]$Index = $Key[0] + $Key[1]
        $Salt = $Constant[$(($Index - 1)+$i)]

        $KeyIndexVal = $Key[$i+$j+2] + $Key[$($i+$j+3)]
        $Hex2Dec = [convert]::toint16("$KeyIndexVal",16)
        [char]$DecryptChar = $Hex2Dec -bxor $Salt

        $Password.Add($DecryptChar)
        $j++
    }
    return $([string]$Password).Replace(' ', '')
}


# Hash regex
$Regex = @(
            'username ([^ ]+) (password|passwd) ([^ ]+) (encrypted|pbkdf2)' # Cisco MD5 or SHA512
            'enable password ([^ ]+) (encrypted|pbkdf2)' # Cisco MD5 or SHA512
            'passwd ([^ ]+) (encrypted|pbkdf2)' # Cisco MD5 or SHA512
            'username ([^ ]+) privilege \d+ secret 4 ([^ ]+)' # Cisco Type 4
            'enable secret 4 ([^ ]+)' # Cisco Type 4
            '(password|key) +7 +([0-9A-F]+)' # Cisco Type 7
            '>(\$1\$[^<]+)<|"(\$1\$[^"]+)"|(\$1\$[^"]+);' # Palo Alto or Juniper Type 1
            )

# Go fishing for hashes
$Hashes = Get-ChildItem -Path $SourceFolder -Recurse | Select-String $Regex

# Output identified hashes to object
$Results = foreach($Hash in $Hashes)
{
    # Switch on line result so we can identify the hash type
    $LineResult = $Hash.Matches[0].Groups[0].Value
    switch -Wildcard ($LineResult)
    {
    # Cisco hash - Hashcat 2400
    "username*encrypted" {
                    $User = $Hash.Matches[0].Groups[1].Value
                    $PHash = $Hash.Matches[0].Groups[3].Value
                    $HashType = 2400
                }
    "enable*encrypted"   {
                    $User = 'enable'
                    $PHash = $Hash.Matches[0].Groups[1].Value
                    $HashType = 2400
                }
    "passwd*encrypted"   {
                    $User = 'passwd'
                    $PHash = $Hash.Matches[0].Groups[1].Value
                    $HashType = 2400
                }
    # Cisco hash - Hashcat 12100 - substring and replace used to make it to hashcat format
    "username*pbkdf2" {
                    $User = $Hash.Matches[0].Groups[1].Value
                    $PHash = $Hash.Matches[0].Groups[3].Value.Substring(1).Replace('$',':')
                    $HashType = 12100
                }
    "enable*pbkdf2"   {
                    $User = 'enable'
                    $PHash = $Hash.Matches[0].Groups[1].Value.Substring(1).Replace('$',':')
                    $HashType = 12100
                }
    "passwd*pbkdf2"   {
                    $User = 'passwd'
                    $PHash = $Hash.Matches[0].Groups[1].Value.Substring(1).Replace('$',':')
                    $HashType = 12100
                }
    # Cisco hash - Hashcat 5700
    "username*secret 4*" {
                    $User = $Hash.Matches[0].Groups[1].Value
                    $PHash = $Hash.Matches[0].Groups[2].Value
                    $HashType = 5700
                }
    "enable secret 4*"   {
                    $User = 'enable'
                    $PHash = $Hash.Matches[0].Groups[1].Value
                    $HashType = 5700
                }
    # Cisco hash - Type 7! :D
    "password 7*" {
                    $User = 'n/a - Cisco Type 7'
                    $PHash = (Decrypt-CiscoType7 $Hash.Matches[0].Groups[2].Value)
                    $HashType = 'Decrypted-Type7'
                }
    "key 7*"   {
                    $User = 'n/a - Cisco Type 7'
                    $PHash = (Decrypt-CiscoType7 $Hash.Matches[0].Groups[2].Value)
                    $HashType = 'Decrypted-Type7'
                }
    # Type 1
    '*$1$*'   {
                    $User = 'n/a'
                    $PHash = ($Hash.Matches[0].Groups | Select-Object -Skip 1 | Where-Object { $_.Success -eq $true } | Select-Object -ExpandProperty Value)
                    $HashType = 500
                }
    }

    # Output hash and information
    New-Object psobject -Property @{
        Filename = $Hash.Path
        LineNumber = $Hash.LineNumber 
        Username = $User
        Hash = $PHash
        HashcatNumber = $HashType
    }
}

# Save results
New-Item $OutputFolder -ErrorAction SilentlyContinue -Force -ItemType Directory | Out-Null
$Results | Export-Csv (Join-Path $OutputFolder 'HashResults.csv') -NoTypeInformation

# store hashes for hashcat
$Results | Group-Object -Property HashcatNumber | ForEach-Object {
    $HashFile = "$(Join-Path $OutputFolder $_.Name).txt"
    $Hashes = $_.Group | Select-Object -ExpandProperty Hash | Sort-Object -Unique
    $Hashes | Out-File -FilePath $HashFile    
}
