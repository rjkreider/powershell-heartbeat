# PowerShell Server Script for Monitoring Client Check-ins
# Version: 1.0
# Author: Rich Kreider
# License: GNU General Public License (GPL)

# Configuration
$port = 12345
$timeout = 900  # 15 minutes in seconds
$smtpServer = "smtp.yourmailserver.com"
$fromEmail = "your@email.com"
$toEmail = "recipient@email.com"
$smtpUsername = "your_smtp_username"
$smtpPassword = "your_smtp_password"

# Dictionary to store connected clients and their last check-in times
$clients = @{}

# Create a TCP listener
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $port)
$listener.Start()

Write-Host "Server listening on port $port"

while ($true) {
    # Check for incoming client connections
    if ($listener.Pending()) {
        $client = $listener.AcceptTcpClient()
        $stream = $client.GetStream()
        $reader = [System.IO.StreamReader]::new($stream)
        
        # Read the client's check-in message
        $clientInfo = $reader.ReadLine()
        $clientName = $clientInfo.Split(":")[1].Trim()
        
        # Record the check-in time for the client
        if (-not $clients.ContainsKey($clientName)) {
            $clients[$clientName] = (Get-Date).AddSeconds($timeout)
        } else {
            $clients[$clientName] = (Get-Date).AddSeconds($timeout)
        }
        
        Write-Host "Received check-in from $clientName"
        
        $reader.Close()
        $stream.Close()
        $client.Close()
    }

    $currentTime = Get-Date
    $disconnectedClients = @()

    # Check if clients have exceeded the check-in timeout
    foreach ($client in $clients.GetEnumerator()) {
        $clientName = $client.Key
        $lastCheckin = $client.Value

        if ($currentTime - $lastCheckin -gt [TimeSpan]::FromSeconds($timeout)) {
            Write-Host "Client $clientName didn't check in for 15 minutes. Sending an email."
            
            # Send an email alert
            $smtpClient = New-Object System.Net.Mail.SmtpClient
            $smtpClient.Host = $smtpServer
            $smtpClient.Port = 587
            $smtpClient.Credentials = New-Object System.Net.NetworkCredential($smtpUsername, $smtpPassword)
            $smtpClient.EnableSsl = $true

            $mailMessage = New-Object System.Net.Mail.MailMessage
            $mailMessage.From = $fromEmail
            $mailMessage.Subject = "Client Check-in Alert"
            $mailMessage.Body = "Client $clientName didn't check in for 15 minutes."

            $mailMessage.To.Add($toEmail)
            
            $smtpClient.Send($mailMessage)
            $disconnectedClients += $clientName
        }
    }

    # Remove disconnected clients from the dictionary
    foreach ($client in $disconnectedClients) {
        $clients.Remove($client)
    }
    
    Start-Sleep -Seconds 60  # Check every minute
}
