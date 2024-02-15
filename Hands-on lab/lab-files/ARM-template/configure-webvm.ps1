param (
    [Parameter(Mandatory=$False)] [string] $SqlIP = "",
    [Parameter(Mandatory=$False)] [string] $SqlPass = "",
    [Parameter(Mandatory = $true)]
    [string]
    $AzureUserName,

    [string]
    $AzurePassword,

    [string]
    $ODLID,

    [string]
    $InstallCloudLabsShadow,

    [string]
    $DeploymentID,
    
    [string]
    $AzureTenantID,
  
    [string]
    $AzureSubscriptionID,
  
    [string]
    $adminPassword
)

Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append

$vmAdminUsername="demouser"
$trainerUserName="trainer"
$trainerUserPassword="$adminPassword"

Install-WindowsFeature -name Web-Server -IncludeManagementTools

$branchName = "microsoft-app-modernization-v2"

# Download and extract the starter solution files
# ZIP File sometimes gets corrupted
Write-Host "Downloading MCW-App-modernization from GitHub" -ForegroundColor Green
New-Item -ItemType directory -Path C:\MCW
while((Get-ChildItem -Directory C:\MCW | Measure-Object).Count -eq 0 )
{
    (New-Object System.Net.WebClient).DownloadFile("https://github.com/CloudLabs-MCW/MCW-App-modernization/zipball/$branchName", 'C:\MCW.zip')
     Expand-Archive -LiteralPath 'C:\MCW.zip' -DestinationPath 'C:\MCW' -Force
}

# Verify, download and extract the starter solution files
$Path = "C:\MCW\MCW-App-modernization-$branchName\Hands-on lab\lab-files\ARM-template\webvm-logon-install.ps1"
$branchName = "microsoft-app-modernization-v2"

if(Test-Path -Path $Path -PathType Leaf)
{
 Write-Host "File exists!"
}
else
{
do
{
(New-Object System.Net.WebClient).DownloadFile("https://github.com/CloudLabs-MCW/MCW-App-modernization/archive/refs/heads/$branchName.zip", 'C:\MCW.zip')
Expand-Archive -LiteralPath 'C:\MCW.zip' -DestinationPath 'C:\MCW' -Force
$data = "Test-Path -Path $Path -PathType Leaf"
}Until($data)

 Write-Host "Downloaded Files"

}

#rename the random branch name
$item = get-item "C:\MCW\*"
Rename-Item $item -NewName "MCW-App-modernization-$branchName"

# Replace SQL Connection String
$item = "C:\MCW\MCW-App-modernization-$branchName"
Write-Host "Server=$SqlIP;Database=PartsUnlimited;User Id=PUWebSite;Password=$SqlPass;"
# The config.release.json file is populated with configuration data during compile and release from VS.  config.json is used by the solution on the WebM.
((Get-Content -path "$item\Hands-on lab\lab-files\src\src\PartsUnlimitedWebsite\config.release.json" -Raw) -replace 'SETCONNECTIONSTRING',"Server=$SqlIP;Database=PartsUnlimited;User Id=PUWebSite;Password=$adminPassword;") | Set-Content -Path "$item\Hands-on lab\lab-files\src\src\PartsUnlimitedWebsite\config.json"

#Import Common Functions
$path = pwd
$path=$path.Path
$commonscriptpath = "$path" + "\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath


# Enable Embedded shadow
Enable-CloudLabsEmbeddedShadow $vmAdminUsername $trainerUserName $trainerUserPassword

CloudLabsManualAgent Install

CreateCredFile $AzureUserName $AzurePassword $AzureTenantID $AzureSubscriptionID $DeploymentID
az provider register --namespace "Microsoft.LoadTestService"

# Schedule Installs for first Logon
$argument = "-File `"C:\MCW\MCW-App-modernization-$branchName\Hands-on lab\lab-files\ARM-template\webvm-logon-install.ps1`""
$triggerAt = New-ScheduledTaskTrigger -AtLogOn -User demouser
$action = New-ScheduledTaskAction -Execute "powershell" -Argument $argument 
Register-ScheduledTask -TaskName "Install Lab Requirements" -Trigger $triggerAt -Action $action -User demouser

#Replace Path

(Get-Content C:\MCW\MCW-App-modernization-microsoft-app-modernization-v2\'Hands-on lab'\lab-files\ARM-template\webvm-logon-install.ps1) -replace "replacepath","$Path" | Set-Content C:\MCW\MCW-App-modernization-microsoft-app-modernization-v2\'Hands-on lab'\lab-files\ARM-template\webvm-logon-install.ps1 -Verbos

#Autologin
$Username = "demouser"
$Pass = "$adminPassword"
$RegistryPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
Set-ItemProperty $RegistryPath 'AutoAdminLogon' -Value "1" -Type String 
Set-ItemProperty $RegistryPath 'DefaultUsername' -Value "$Username" -type String 
Set-ItemProperty $RegistryPath 'DefaultPassword' -Value "$Pass" -type String


$Validstatus="Pending"  ##Failed or Successful at the last step
$Validmessage="Post Deployment is Pending"

#Set the final deployment status
CloudlabsManualAgent setStatus

Stop-Transcript  

Restart-Computer
