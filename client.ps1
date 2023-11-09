# PowerShell Client Script for Checking in with Server
# Version: 1.0
# Author: Rich Kreider
# License: GNU General Public License (GPL)

# Configuration
$serverHost = "server_ip_or_hostname"  # Replace with the IP address or hostname of the server
$serverPort = 12345  # Replace with the server's port

# Get the computer name of the client
$computerName = $env:COMPUTERNAME

try {
    # Create a TCP client and connect to the server
    $client = [System.Net.Sockets.TcpClient]::new()
    $client.Connect($serverHost, $serverPort)
    
    # Get the client network stream and create a writer
    $stream = $client.GetStream()
    $writer = [System.IO.StreamWriter]::new($stream)
    
    # Send the computer name to the server
    $writer.WriteLine("ComputerName: $computerName")
    $writer.Flush()
    
    Write-Host "Checked in with the server as $computerName"
} catch {
    Write-Host "Failed to check in with the server. Error: $_"
} finally {
    # Close the client connection
    if ($writer) { $writer.Close() }
    if ($stream) { $stream.Close() }
    if ($client) { $client.Close() }
}
