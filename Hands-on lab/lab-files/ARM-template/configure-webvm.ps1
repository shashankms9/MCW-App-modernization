param (
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

function Disable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force
    Stop-Process -Name Explorer -Force
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}

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

#Import Common Functions
$path = pwd
$path=$path.Path
$commonscriptpath = "$path" + "\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath

# Enable Embedded shadow
Enable-CloudLabsEmbeddedShadow $vmAdminUsername $trainerUserName $trainerUserPassword

CloudLabsManualAgent Install
WindowsServerCommon
#WindowsServerCommon

[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 
Disable-InternetExplorerESC
Enable-IEFileDownload
Enable-CopyPageContent-In-InternetExplorer
DisableServerMgrNetworkPopup
CreateLabFilesDirectory
DisableWindowsFirewall
InstallEdgeChromium

InstallAzPowerShellModule
CreateCredFile $AzureUserName $AzurePassword $AzureTenantID $AzureSubscriptionID $DeploymentID
az provider register --namespace "Microsoft.LoadTestService"

# To resolve the error of https://github.com/microsoft/MCW-App-modernization/issues/68. The cause of the error is Powershell by default uses TLS 1.0 to connect to website, but website security requires TLS 1.2. You can change this behavior with running any of the below command to use all protocols. You can also specify single protocol.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Ssl3
[Net.ServicePointManager]::SecurityProtocol = "Tls, Tls11, Tls12, Ssl3"

# Disable IE ESC
Disable-InternetExplorerESC

Install-WindowsFeature -name Web-Server -IncludeManagementTools

$branchName = "Migrate-Secure"

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
$branchName = "Migrate-Secure"

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

. C:\LabFiles\AzureCreds.ps1

$userName = $AzureUserName
$password = $AzurePassword
$subscriptionId = $AzureSubscriptionID
$TenantID = $AzureTenantID
$DeploymentID = $DeploymentID

$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword

Connect-AzAccount -Credential $cred | Out-Null

$SqlIP = Get-AzPublicIpAddress -ResourceGroupName MigrateSevers -Name SqlServer2008-ip

# Replace SQL Connection String
$item = "C:\MCW\MCW-App-modernization-$branchName"
Write-Host "Server=$SqlIP;Database=PartsUnlimited;User Id=PUWebSite;Password=$adminPassword;"
# The config.release.json file is populated with configuration data during compile and release from VS.  config.json is used by the solution on the WebM.
((Get-Content -path "$item\Hands-on lab\lab-files\src\src\PartsUnlimitedWebsite\config.release.json" -Raw) -replace 'SETCONNECTIONSTRING',"Server=$SqlIP;Database=PartsUnlimited;User Id=PUWebSite;Password=$adminPassword;") | Set-Content -Path "$item\Hands-on lab\lab-files\src\src\PartsUnlimitedWebsite\config.json"

# Downloading Deferred Installs
# Download App Service Migration Assistant 
(New-Object System.Net.WebClient).DownloadFile('https://appmigration.microsoft.com/api/download/windows/AppServiceMigrationAssistant.msi', 'C:\AppServiceMigrationAssistant.msi')
# Download Edge 
(New-Object System.Net.WebClient).DownloadFile('https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/e2d06b69-9e44-45e1-bdf5-b3b827fe06b2/MicrosoftEdgeEnterpriseX64.msi', 'C:\MicrosoftEdgeEnterpriseX64.msi')
# Download 3.1.4 SDK
(New-Object System.Net.WebClient).DownloadFile('https://download.visualstudio.microsoft.com/download/pr/70062b11-491c-403c-91db-9d84462ee292/5db435e39128cbb608e76bf5111ab3dc/dotnet-sdk-3.1.413-win-x64.exe', 'C:\dotnet-sdk-3.1.413-win-x64.exe')

# Download Windows Hosting
Wait-Install
(New-Object System.Net.WebClient).DownloadFile('https://download.visualstudio.microsoft.com/download/pr/a0da9621-68f0-439a-b617-4697ee0669e3/38eb4aa6e879b9f06b73599ea2e1535f/dotnet-hosting-5.0.10-win.exe', 'C:\dotnet-hosting-5.0.10-win.exe')
$pathArgs = {C:\dotnet-hosting-5.0.10-win.exe /Install /Quiet /Norestart /Logs logHostingPackage.txt}
Invoke-Command -ScriptBlock $pathArgs

# Download and install SQL Server Management Studio
Wait-Install
(New-Object System.Net.WebClient).DownloadFile('https://aka.ms/ssmsfullsetup', 'C:\SSMS-Setup.exe')
$pathArgs = {C:\SSMS-Setup.exe /Install /Quiet /Norestart /Logs logSSMS.txt}
Invoke-Command -ScriptBlock $pathArgs

# Install Git
Wait-Install
(New-Object System.Net.WebClient).DownloadFile('https://github.com/git-for-windows/git/releases/download/v2.30.0.windows.2/Git-2.30.0.2-64-bit.exe', 'C:\Git-2.30.0.2-64-bit.exe')
Start-Process -file 'C:\Git-2.30.0.2-64-bit.exe' -arg '/VERYSILENT /SUPPRESSMSGBOXES /LOG="C:\git_install.txt" /NORESTART /CLOSEAPPLICATIONS' -passthru | wait-process

# Install VS Code
Wait-Install
(New-Object System.Net.WebClient).DownloadFile('https://go.microsoft.com/fwlink/?LinkID=623230', 'C:\vscode.exe')
Start-Process -file 'C:\vscode.exe' -arg '/VERYSILENT /SUPPRESSMSGBOXES /LOG="C:\vscode_install.txt" /NORESTART /FORCECLOSEAPPLICATIONS /mergetasks="!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"' -passthru | wait-process

#Replace Path

(Get-Content C:\MCW\MCW-App-modernization-microsoft-app-modernization-v2\'Hands-on lab'\lab-files\ARM-template\webvm-logon-install.ps1) -replace "replacepath","$Path" | Set-Content C:\MCW\MCW-App-modernization-microsoft-app-modernization-v2\'Hands-on lab'\lab-files\ARM-template\webvm-logon-install.ps1 -Verbos

Invoke-WebRequest 'https://download.microsoft.com/download/C/6/3/C63D8695-CEF2-43C3-AF0A-4989507E429B/DataMigrationAssistant.msi' -OutFile 'C:\DataMigrationAssistant.msi'
Start-Process -file 'C:\DataMigrationAssistant.msi' -arg '/qn /l*v C:\dma_install.txt' -passthru | wait-process

#Upgrade notepadplusplus
choco upgrade notepadplusplus

choco uninstall microsoft-edge
sleep 5

Choco install microsoft-edge

sleep 5

#Reset VM password to update it to random password, it is a custom image based VM
net user $adminUsername $adminPassword

$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://github.com/Azure/azure-powershell/releases/download/v5.0.0-October2020/Az-Cmdlets-5.0.0.33612-x64.msi","C:\Packages\Az-Cmdlets-5.0.0.33612-x64.msi")

sleep 5

Start-Process msiexec.exe -Wait '/I C:\Packages\Az-Cmdlets-5.0.0.33612-x64.msi /qn' -Verbose 

sleep 5

# Remove Azure portal shortcut
$shortcutPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('Desktop'), 'C:\Users\Public\Desktop\Azure Portal.lnk')
Remove-Item -Path $shortcutPath -Force

# Remove data migration service shortcut
$shortcutPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('Desktop'), 'C:\Users\Public\Desktop\Microsoft Data Migration Assistant.lnk')
Remove-Item -Path $shortcutPath -Force


Function Set-VMNetworkConfiguration {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,
                   Position=1,
                   ParameterSetName='DHCP',
                   ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true,
                   Position=0,
                   ParameterSetName='Static',
                   ValueFromPipeline=$true)]
        [Microsoft.HyperV.PowerShell.VMNetworkAdapter]$NetworkAdapter,

        [Parameter(Mandatory=$true,
                   Position=1,
                   ParameterSetName='Static')]
        [String[]]$IPAddress=@(),

        [Parameter(Mandatory=$false,
                   Position=2,
                   ParameterSetName='Static')]
        [String[]]$Subnet=@(),

        [Parameter(Mandatory=$false,
                   Position=3,
                   ParameterSetName='Static')]
        [String[]]$DefaultGateway = @(),

        [Parameter(Mandatory=$false,
                   Position=4,
                   ParameterSetName='Static')]
        [String[]]$DNSServer = @(),

        [Parameter(Mandatory=$false,
                   Position=0,
                   ParameterSetName='DHCP')]
        [Switch]$Dhcp
    )

    $VM = Get-WmiObject -Namespace 'root\virtualization\v2' -Class 'Msvm_ComputerSystem' | Where-Object { $_.ElementName -eq $NetworkAdapter.VMName } 
    $VMSettings = $vm.GetRelated('Msvm_VirtualSystemSettingData') | Where-Object { $_.VirtualSystemType -eq 'Microsoft:Hyper-V:System:Realized' }    
    $VMNetAdapters = $VMSettings.GetRelated('Msvm_SyntheticEthernetPortSettingData') 

    $NetworkSettings = @()
    foreach ($NetAdapter in $VMNetAdapters) {
        if ($NetAdapter.Address -eq $NetworkAdapter.MacAddress) {
            $NetworkSettings = $NetworkSettings + $NetAdapter.GetRelated("Msvm_GuestNetworkAdapterConfiguration")
        }
    }

    $NetworkSettings[0].IPAddresses = $IPAddress
    $NetworkSettings[0].Subnets = $Subnet
    $NetworkSettings[0].DefaultGateways = $DefaultGateway
    $NetworkSettings[0].DNSServers = $DNSServer
    $NetworkSettings[0].ProtocolIFType = 4096

    if ($dhcp) {
        $NetworkSettings[0].DHCPEnabled = $true
    } else {
        $NetworkSettings[0].DHCPEnabled = $false
    }

    $Service = Get-WmiObject -Class "Msvm_VirtualSystemManagementService" -Namespace "root\virtualization\v2"
    $setIP = $Service.SetGuestNetworkAdapterConfiguration($VM, $NetworkSettings[0].GetText(1))

    if ($setip.ReturnValue -eq 4096) {
        $job=[WMI]$setip.job 

        while ($job.JobState -eq 3 -or $job.JobState -eq 4) {
            start-sleep 1
            $job=[WMI]$setip.job
        }

        if ($job.JobState -eq 7) {
            write-host "Success"
        }
        else {
            $job.GetError()
        }
    } elseif($setip.ReturnValue -eq 0) {
        Write-Host "Success"
    }
}


Function Wait-For-Website {
    Param (
        [string]$Url
    )

    $i = 1
    while ($true) {

        try {
            Write-Output "Checking ($i)...please wait"
            $i++

            $response = Invoke-WebRequest -Uri $Url -TimeoutSec 10 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                return;
            }
        } catch {}

        Start-Sleep 2
    }
}

Function Rearm-VM {
    Param (
        [string]$ComputerName,
        [string]$Username,
        [string]$Password
    )

    Write-Output "Getting IP for $ComputerName"

    $vm = Get-VM -Name $ComputerName
    # Wait for VM to become available and on the network before proceeding to re-arm licenses
    do {
        if ($vm.state -eq "Off")  {
            Write-Output "Attempting to start $ComputerName..."
            $vm | Start-VM
        }
        sleep -Seconds 5
        $ip = $vm.NetworkAdapters[0].IpAddresses[0]
    } until ($ip)

    Write-Output "Creating credentials object"
    $localusername = "$computerName\$Username"
    $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $localcredential = New-Object System.Management.Automation.PSCredential ($localusername, $securePassword)

    Write-Output "Re-arm (extend eval license) for VM $ComputerName at $ip"
    #set-item wsman:\localhost\Client\TrustedHosts -value $ip -Force

    Invoke-Command -ComputerName $ip -ScriptBlock { 
        slmgr.vbs /rearm
        net accounts /maxpwage:unlimited
        Restart-Computer -Force 
    } -Credential $localcredential

    Write-Output "Re-arm complete"
}

Start-Transcript -Path "C:\PostRebootConfigure_log.txt"
#$cmdLogPath = "C:\PostRebootConfigure_log_cmd.txt"

Start-Sleep 60
$ErrorActionPreference = 'continue'
Import-Module BitsTransfer

# Create paths
Write-Output "Create paths"
$opsDir = "C:\OpsgilityTraining"
$vmDir = "C:\VirtualMachines"

# Unregister scheduled task so this script doesn't run again on next reboot
#Write-Output "Remove PostRebootConfigure scheduled task"
#Unregister-ScheduledTask -TaskName "SetUpVMs" -Confirm:$false

# Create the NAT network
Write-Output "Create internal NAT"
$natName = "InternalNat"
New-NetNat -Name $natName -InternalIPInterfaceAddressPrefix 192.168.0.0/16

# Create an internal switch with NAT
Write-Output "Create internal switch"
$switchName = 'InternalNATSwitch'
New-VMSwitch -Name $switchName -SwitchType Internal
$adapter = Get-NetAdapter | Where-Object { $_.Name -like "*"+$switchName+"*" }

# Create an internal network (gateway first)
Write-Output "Create gateway"
New-NetIPAddress -IPAddress 192.168.0.1 -PrefixLength 24 -InterfaceIndex $adapter.ifIndex

# Enable Enhanced Session Mode on Host
Write-Output "Enable Enhanced Session Mode"
Set-VMHost -EnableEnhancedSessionMode $true

# Create the nested Windows VMs - from VHDs
Write-Output "Create Hyper-V VMs"
#New-VM -Name WindowsServer -MemoryStartupBytes 4GB -BootDevice VHD -VHDPath "$vmdir\SmartHotelWeb1\SmartHotelWeb1.vhdx" -Path "$vmdir\SmartHotelWeb1" -Generation 2 -Switch $switchName 
New-VM -Name WindowsServer -MemoryStartupBytes 4GB -BootDevice VHD -VHDPath "$vmdir\SmartHotelWeb2\SmartHotelWeb2.vhdx" -Path "$vmdir\SmartHotelWeb2" -Generation 2 -Switch $switchName
#New-VM -Name smarthotelSQL1 -MemoryStartupBytes 4GB -BootDevice VHD -VHDPath "$vmdir\SmartHotelSQL1\SmartHotelSQL1.vhdx" -Path "$vmdir\SmartHotelSQL1" -Generation 2 -Switch $switchName
New-VM -Name UbuntuServer -MemoryStartupBytes 4GB -BootDevice VHD -VHDPath "$vmdir\UbuntuWAF\UbuntuWAF.vhdx"           -Path "$vmdir\UbuntuWAF"      -Generation 1 -Switch $switchName

# Configure IP addresses (don't change the IPs! VM config depends on them)
Write-Output "Configure VM networking"
Get-VMNetworkAdapter -VMName "WindowsServer" | Set-VMNetworkConfiguration -IPAddress "192.168.0.4" -Subnet "255.255.255.0" -DefaultGateway "192.168.0.1" -DNSServer "8.8.8.8"
#Get-VMNetworkAdapter -VMName "smarthotelweb2" | Set-VMNetworkConfiguration -IPAddress "192.168.0.5" -Subnet "255.255.255.0" -DefaultGateway "192.168.0.1" -DNSServer "8.8.8.8"
#Get-VMNetworkAdapter -VMName "smarthotelsql1" | Set-VMNetworkConfiguration -IPAddress "192.168.0.6" -Subnet "255.255.255.0" -DefaultGateway "192.168.0.1" -DNSServer "8.8.8.8"
Get-VMNetworkAdapter -VMName "UbuntuServer" | Set-VMNetworkConfiguration -IPAddress "192.168.0.8" -Subnet "255.255.255.0" -DefaultGateway "192.168.0.1" -DNSServer "8.8.8.8"

# We always want the VMs to start with the host and shut down cleanly with the host
# (If they just save state, which is the default, they can break if the host re-starts on a different CPU architecture)
Write-Output "Set VM auto start/stop"
Get-VM | Set-VM -AutomaticStartAction Start -AutomaticStopAction ShutDown

# Start all the VMs
Write-Output "Start VMs"
Get-VM | Start-VM

# Ping website to warm it up
Write-Output "Wait for smarthotel site"
#Wait-For-Website('http://192.168.0.8')

# Rearm (extend evaluation license) and reboot each Windows VM
Write-Output "Re-arming Windows VMs (extend eval licenses)"
Rearm-VM -ComputerName "WindowsServer" -Username "Administrator" -Password "demo!pass123"
#Rearm-VM -ComputerName "smarthotelweb2" -Username "Administrator" -Password "demo!pass123"
#Rearm-VM -ComputerName "smarthotelSQL1" -Username "Administrator" -Password "demo!pass123"

# Warm up the app after the re-arm reboots
#Write-Output "Waiting for SmartHotel reboot"
#Wait-For-Website('http://192.168.0.8')

$newname = "hostvms" + "$DeploymentID"

# Schedule Installs for first Logon
$argument = "-File `"C:\MCW\MCW-App-modernization-$branchName\Hands-on lab\lab-files\ARM-template\webvm-logon-install.ps1`""
$triggerAt = New-ScheduledTaskTrigger -AtLogOn -User demouser
$action = New-ScheduledTaskAction -Execute "powershell" -Argument $argument 
Register-ScheduledTask -TaskName "Install Lab Requirements" -Trigger $triggerAt -Action $action -User demouser

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
