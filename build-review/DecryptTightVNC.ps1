function DecryptVNC($hexPassword) {
    
    function GetBytes($Hex){
        $bytes = New-Object -TypeName byte[] -ArgumentList ($Hex.Length / 2)
        for ($i = 0; $i -lt $Hex.Length; $i += 2) {
            $bytes[$i / 2] = [Convert]::ToByte($Hex.Substring($i, 2), 16)
        }
        return $bytes
    }

    function decrypt($bytes){
        $des = [System.Security.Cryptography.DES]::Create()
        $des.IV = [byte[]](0,0,0,0,0,0,0,0)
        $des.Key = GetBytes 'e84ad660c4721ae0' # known key for TightVNC
        $des.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $des.Padding = [System.Security.Cryptography.PaddingMode]::None
        $decryptor = $des.CreateDecryptor()
        $unencryptedData = $decryptor.TransformFinalBlock($bytes, 0, 8);
        $des.Dispose()
    
        return [System.Text.Encoding]::UTF8.GetString($unencryptedData).Trim([char]0)
    }


    if([String]::IsNullOrWhiteSpace($hexPassword))
    {
        Write-Warning 'No HEX given for decryption obtaining password for TightVNC locally...'

        if((Test-Path HKLM:\Software\TightVNC\Server) -eq $false)
        {
            Write-Error "Could not find TightVNC registry path..."
            return $null
        }

        $Password = Get-ItemPropertyValue -Path HKLM:\Software\TightVNC\Server -Name Password
        $controlPassword = Get-ItemPropertyValue -Path HKLM:\Software\TightVNC\Server -Name ControlPassword

        Write-Output (decrypt $Password)
        return (decrypt $controlPassword)
    }

    return (decrypt (GetBytes $hexPassword))

}
