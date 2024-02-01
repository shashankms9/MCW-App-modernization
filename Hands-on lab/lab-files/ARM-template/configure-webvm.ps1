param (
    [Parameter(Mandatory = $true)]
    [string]
    $AzureUserName,
 
    [string]
    $AzurePassword,
 
    [string]
    $AzureTenantID,
 
    [string]
    $AzureSubscriptionID,
 
    [string]
    $ODLID,
 
    [string]
    $DeploymentID,
 
    [string]
    $vmAdminUsername,
 
    [string]
    $adminPassword,
 
    [string]
    $trainerUserName,
 
    [string]
    $trainerUserPassword
)

Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append

$vmAdminUsername="demouser"
$trainerUserName="trainer"
$trainerUserPassword="$adminPassword"


[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
 
#Import Common Functions
$path = pwd
$path=$path.Path
$commonscriptpath = "$path" + "\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath
#Installing Modern VM Validator
InstallModernVmValidator
 
CreateCredFile $AzureUserName $AzurePassword $AzureTenantID $AzureSubscriptionID $DeploymentID

Enable-CloudLabsEmbeddedShadow $vmAdminUsername $trainerUserName $trainerUserPassword

az provider register --namespace "Microsoft.LoadTestService"

#Reset VM password to update it to random password, it is a custom image based VM
net user $adminUsername $adminPassword

#Stop Transcript
Stop-Transcript
