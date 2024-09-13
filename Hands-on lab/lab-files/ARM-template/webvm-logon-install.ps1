Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension1.txt -Append

$commonscriptpath = "replacepath\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath


function Wait-Install {
    $msiRunning = 1
    $msiMessage = ""
    while($msiRunning -ne 0)
    {
        try
        {
            $Mutex = [System.Threading.Mutex]::OpenExisting("Global\_MSIExecute");
            $Mutex.Dispose();
            $DST = Get-Date
            $msiMessage = "An installer is currently running. Please wait...$DST"
            Write-Host $msiMessage 
            $msiRunning = 1
        }
        catch
        {
            $msiRunning = 0
        }
        Start-Sleep -Seconds 1
    }
}
$branchName = "microsoft-app-modernization-v2"
# Install App Service Migration Assistant
Wait-Install
Write-Host "Installing App Service Migration Assistant..."
Start-Process -file 'C:\AppServiceMigrationAssistant.msi ' -arg '/qn /l*v C:\asma_install.txt' -passthru | wait-process

# checking AppServiceMigrationAssistant installation
$Testpath = 'C:\Users\demouser\AppData\Local\Programs\azure-appService-migrationAssistant'
$Testpath1 = 'C:\AppServiceMigrationAssistant.msi '

$Folder = Test-Path -Path $Testpath
$Folder1 = Test-Path -Path $Testpath1

Write-Host "Checking for App serviceMigrationassistant installation"
if ($Folder -eq 'True' -and $Folder1 -eq 'True') {
    Write-Host "App service Migration assistant installation is succeeded"
} 
else 
{
    (New-Object System.Net.WebClient).DownloadFile('https://appmigration.microsoft.com/api/download/windows/AppServiceMigrationAssistant.msi', 'C:\AppServiceMigrationAssistant.msi')
    Start-Sleep -s 15
    Wait-Install
    Write-Host "Installing App Service Migration Assistant..."
    Start-Process -file 'C:\AppServiceMigrationAssistant.msi ' -arg '/qn /l*v C:\asma_install.txt' -passthru | wait-process
}

# Install Edge
Wait-Install
Write-Host "Installing Edge..."
Start-Process -file 'C:\MicrosoftEdgeEnterpriseX64.msi' -arg '/qn /l*v C:\edge_install.txt' -passthru | wait-process

# Install .NET Core 3.1 SDK
Wait-Install
Write-Host "Installing .NET Core 3.1 SDK..."
$pathArgs = {C:\dotnet-sdk-3.1.413-win-x64.exe /Install /Quiet /Norestart /Logs logCore31SDK.txt}
Invoke-Command -ScriptBlock $pathArgs

# Copy Web Site Files
Wait-Install
Write-Host "Copying default website files..."
Expand-Archive -LiteralPath "C:\MCW\MCW-App-modernization-$branchName\Hands-on lab\lab-files\PartsUnlimitedWebsite.zip" -DestinationPath 'C:\inetpub\wwwroot' -Force

# Copy the database connection string to the web app.
Write-Host "Updating config.json with the SQL IP Address and connection string information."
Copy-Item "C:\MCW\MCW-App-modernization-$branchName\Hands-on lab\lab-files\src\src\PartsUnlimitedWebsite\config.json" -Destination 'C:\inetpub\wwwroot' -Force

Unregister-ScheduledTask -TaskName "Install Lab Requirements" -Confirm:$false

# Restart the app for the startup to pick up the database connection string.
Write-Host "Restarting IIS"
iisreset.exe /restart

#Check if Webvm ip is accessible or not
Import-Module Az

. C:\LabFiles\AzureCreds.ps1

$AzureUserName = $AzureUserName
$AzurePassword = $AzurePassword
$DeploymentID = $DeploymentID
$SubscriptionId = $AzureSubscriptionID
$AzureTenantID = $AzureTenantID

$AppID = $env:AppID
$AppSecret = $env:AppSecret
$azuserobjectid = $env:azuserobjectid

$securePassword = $AppSecret | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $AppID, $SecurePassword
Connect-AzAccount -ServicePrincipal -Credential $cred -Tenant $AzureTenantID | Out-Null
Select-AzSubscription -SubscriptionId $SubscriptionId

Start-Sleep 200
$k = 0 
for ($i=1; ($i + $k) -le 7; $i++)
{
    $vmipdetails=Get-AzPublicIpAddress -ResourceGroupName "hands-on-lab-$DeploymentID" -Name "WebVM-ip" 

    $vmip=$vmipdetails.IpAddress
 
    $url="http://"+$vmip

    $HTTP_Request = [System.Net.WebRequest]::Create($url)

    $HTTP_Request.timeout = 120000; #2 Minutes

    # We then get a response from the site.
    $HTTP_Response = $HTTP_Request.getResponse()

    # We then get the HTTP code as an integer.
    $HTTP_Status = [int]$HTTP_Response.StatusCode
    Write-Host "Checking the status of website in the attempt $i"
    
if ($HTTP_Status -eq 200) {
     $k = 8
     $Validstatus="Succeeded"  ##Failed or Successful at the last step
     $Validmessage="Post Deployment is successful"
     Write-Host "Post Deployment is successful"
    }
else{
    $branchName = "microsoft-app-modernization-v2"
    Write-Host "Installing .NET Core 3.1 SDK..."
    $pathArgs = {C:\dotnet-sdk-3.1.413-win-x64.exe /Install /Quiet /Norestart /Logs logCore31SDK.txt}
    Invoke-Command -ScriptBlock $pathArgs

    # Copy Web Site Files
    Wait-Install
    Write-Host "Copying default website files..."
    Expand-Archive -LiteralPath "C:\MCW\MCW-App-modernization-$branchName\Hands-on lab\lab-files\PartsUnlimitedWebsite.zip" -DestinationPath 'C:\inetpub\wwwroot' -Force

    # Copy the database connection string to the web app.
    Write-Host "Updating config.json with the SQL IP Address and connection string information."
    Copy-Item "C:\MCW\MCW-App-modernization-$branchName\Hands-on lab\lab-files\src\src\PartsUnlimitedWebsite\config.json" -Destination 'C:\inetpub\wwwroot' -Force

    # Restart the app for the startup to pick up the database connection string.
    Write-Host "Restarting IIS"
    iisreset.exe /restart
} 
}

sleep 120

if ($HTTP_Status -eq 200) {
     $k = 8
     $Validstatus="Succeeded"  ##Failed or Successful at the last step
     $Validmessage="Post Deployment is successful"
     Write-Host "Post Deployment is successful"
    }
else{
    Write-Warning "Validation Failed - see log output"
    $Validstatus="Failed"  ##Failed or Successful at the last step
    $Validmessage="Post Deployment Failed"
     Write-Host "Post Deployment Failed"
} 

Sleep 50

Invoke-AzVMRunCommand -ResourceGroupName "hands-on-lab-$DeploymentID" -Name 'SqlServer2008' -CommandId 'RunPowerShellScript' -ScriptPath "C:\MCW\MCW-App-modernization-$branchName\Hands-on lab\lab-files\ARM-template\sqlvm-logontask.ps1"

CloudlabsManualAgent setStatus

CloudLabsManualAgent Start

Stop-Transcript
