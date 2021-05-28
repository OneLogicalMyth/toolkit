 
 Function Invoke-TCPPortScan {
 param([ipaddress[]]$IPaddress, [int64[]]$Port, [bool]$StdOut = $true)

    $addressFamily = [System.Net.Sockets.AddressFamily]::InterNetwork
    $socketType = [System.Net.Sockets.SocketType]::Stream
    $protocolType = [System.Net.Sockets.ProtocolType]::Tcp

    foreach($IP in $IPaddress)
    {        
        if($StdOut)
        {
            $heading = "| Testing TCP ports on $IP |"
            Write-Host ""
            Write-Host ('_' * $heading.Length)
            Write-Host "| $(' ' * ($heading.Length - 4)) |"
            Write-Host $heading
            Write-Host ('-' * $heading.Length)
            Write-Host "| $(' ' * ($heading.Length - 4)) |"
        }

        $portResults = @{}

        foreach($Prt in ($Port | Select-Object -Unique))
        {
            Write-Progress -Activity "Port Scanning" -CurrentOperation "Scanning host $IP" -Status "Testing TCP port $Prt"
            $socket = New-Object System.Net.Sockets.Socket $addressFamily, $socketType, $protocolType

            try
            {
                $connection = $socket.BeginConnect($IP, $Prt, $null, $null)
                $connectionResult = $connection.AsyncWaitHandle.WaitOne( 500, $true )

                $portText = "TCP/$Prt"
                $portText += ' ' * (10 - $portText.Length)

                if($socket.Connected)
                {
                    if($StdOut)
                    {
                        $portText += " [Open]"
                        Write-Host "| " -NoNewline
                        Write-Host "$portText $(' ' * ($heading.Length - $portText.Length - 5))" -ForegroundColor Green -NoNewline
                        Write-Host " |"
                    }
                    
                    $portResults.Add($Prt, $true)
                    $socket.EndConnect($connection)

                }else{
                     
                    if($StdOut)
                    {
                        $portText += " [Closed]"
                        Write-Host "| " -NoNewline
                        Write-Host "$portText $(' ' * ($heading.Length - $portText.Length - 5))" -ForegroundColor Red -NoNewline
                        Write-Host " |"
                    }

                    $portResults.Add($Prt, $false)
                    $socket.Close()
                }
            }
            catch
            {
                if($StdOut)
                {
                    $portText += " [Closed]"
                    Write-Host "| " -NoNewline
                    Write-Host "$portText $(' ' * ($heading.Length - $portText.Length - 5))" -ForegroundColor Red -NoNewline
                    Write-Host " |"
                }
                $portResults.Add($Prt, $false)
            }
            finally
            {
                $socket.Close()
            }
        }

        if($StdOut)
        {
            Write-Host ('_' * $heading.Length)
            Write-Host ""
        }

        $IPResult = @{
            IPAddress = $IP.ToString()
            PortResults = $portResults
        }

        if(-not $StdOut)
        {
            New-Object PSCustomObject -Property $IPResult
        }
        
    }


}
