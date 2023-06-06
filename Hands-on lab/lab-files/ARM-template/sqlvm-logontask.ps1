Start-Transcript -Path C:\WindowsAzure\Logs\logontask.txt -Append

# Download and install Data Mirgation Assistant
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://download.microsoft.com/download/C/6/3/C63D8695-CEF2-43C3-AF0A-4989507E429B/DataMigrationAssistant.msi","C:\DataMigrationAssistant.msi")
sleep 5
$arguments = "/i `"C:\DataMigrationAssistant.msi`" /quiet"
sleep 5
Start-Process msiexec.exe -ArgumentList $arguments -Wait

sleep 5

$app = Get-Item -Path 'C:\Program Files\Microsoft Data Migration Assistant\Dma.exe' 

if($app -ne $null)
{    
    $validstatus = "Successfull"
    $validstatus
}
else {
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile("https://download.microsoft.com/download/C/6/3/C63D8695-CEF2-43C3-AF0A-4989507E429B/DataMigrationAssistant.msi","C:\DataMigrationAssistant.msi")
        sleep 5
        $arguments = "/i `"C:\DataMigrationAssistant.msi`" /quiet"
        sleep 5
        Start-Process msiexec.exe -ArgumentList $arguments -Wait
        $validstatus = "app was not found but installed by loop"
        $validstatus

      }

Unregister-ScheduledTask -TaskName "Install Lab Requirements" -Confirm:$false

Stop-Transcript
