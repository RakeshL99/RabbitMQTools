#Start-QueueListener.ps1
[cmdletbinding()]
param (
    [Parameter(Mandatory=$false)] [string] $rabbitMQComputer = "localhost",
    [Parameter(Mandatory=$true)] [string] $QueueName,
    [Parameter(Mandatory=$true)] [System.Management.Automation.CredentialAttribute()] $Credential
)
#This script will listen to the RabbitMQ instance, and watch for messages coming in.
#When it detects them, it will read them in order and output them to the screen

#Is the RabbitMQ Module Loaded?
if ((Get-Module RabbitMQTools) -eq $false)
{
    throw "RabbitMQ module not loaded. Please load it before continuing."
}

$stopWatch = New-Object System.Diagnostics.Stopwatch
$stopWatch.Start()
$timeouts = 0

while ($true)
{
    #Grab a message
    $IncomingMessage = Get-RabbitMQMessage -Name $QueueName -ComputerName $rabbitMQComputer -Count 1 -Credential $Credential -Remove -VirtualHost /
    if ($IncomingMessage) {
        $Data = $IncomingMessage.Payload | ConvertFrom-Json
        Write-Host ("New user " + $Data.FirstName + " " + $Data.LastName + " with and email address of " + $Data.EmailAddress + " and a DOB of " + $Data.DOB + " was created on " + $Data.Created)
        $timeouts = 0
        $stopwatch.Restart()        
    } else {
        $elapsed = [math]::floor($stopWatch.ElapsedMilliseconds / 1000)
        Start-Sleep 5
        if ($elapsed % 30 -eq 0 -and $elapsed -gt 0) {
            $timeouts += 30
            $stopwatch.Restart()
            Write-Warning "No messages received in the last $timeouts seconds..."
        }
    }
}
