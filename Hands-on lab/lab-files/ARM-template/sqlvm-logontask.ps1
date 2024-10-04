
Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension21.txt -Append



function Add-SqlFirewallRule {
    $fwPolicy = $null
    $fwPolicy = New-Object -ComObject HNetCfg.FWPolicy2

    $NewRule = $null
    $NewRule = New-Object -ComObject HNetCfg.FWRule

    $NewRule.Name = "SqlServer"
    # TCP
    $NewRule.Protocol = 6
    $NewRule.LocalPorts = 1433
    $NewRule.Enabled = $True
    $NewRule.Grouping = "SQL Server"
    # ALL
    $NewRule.Profiles = 7
    # ALLOW
    $NewRule.Action = 1
    # Add the new rule
    $fwPolicy.Rules.Add($NewRule)
}

Add-SqlFirewallRule

# Attach the downloaded backup files to the local SQL Server instance
function Setup-Sql {
    #Add snap-in
    Add-PSSnapin SqlServerCmdletSnapin* -ErrorAction SilentlyContinue

    $ServerName = 'SQLSERVER2008'
    $DatabaseName = 'PartsUnlimited'
    $SqlPass = "demo!pass123"
    $Cmd = "USE [master] CREATE DATABASE [$DatabaseName]"
    Invoke-Sqlcmd $Cmd -QueryTimeout 3600 -ServerInstance $ServerName

    Invoke-Sqlcmd "ALTER DATABASE [$DatabaseName] SET DISABLE_BROKER;" -QueryTimeout 3600 -ServerInstance $ServerName
    
    Invoke-Sqlcmd "CREATE LOGIN PUWebSite WITH PASSWORD = '$SqlPass';" -QueryTimeout 3600 -ServerInstance $ServerName
    Invoke-Sqlcmd "USE [$DatabaseName];CREATE USER PUWebSite FOR LOGIN [PUWebSite];EXEC sp_addrolemember 'db_owner', 'PUWebSite'; " -QueryTimeout 3600 -ServerInstance $ServerName

    Invoke-Sqlcmd "EXEC sp_addsrvrolemember @loginame = N'PUWebSite', @rolename = N'sysadmin';" -QueryTimeout 3600 -ServerInstance $ServerName

    Invoke-Sqlcmd "EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2" -QueryTimeout 3600 -ServerInstance $ServerName

    Restart-Service -Force MSSQLSERVER
    #In case restart failed but service was shut down.
    Start-Service -Name 'MSSQLSERVER' 
}

Setup-Sql




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
$branchName = "Migrate-Secure"
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
# Download and install Data Mirgation Assistant
(New-Object System.Net.WebClient).DownloadFile('https://download.microsoft.com/download/C/6/3/C63D8695-CEF2-43C3-AF0A-4989507E429B/DataMigrationAssistant.msi', 'C:\DataMigrationAssistant.msi')
Start-Process -file 'C:\DataMigrationAssistant.msi' -arg '/qn /l*v C:\dma_install.txt' -passthru | wait-process

# Download 3.1.4 SDK
(New-Object System.Net.WebClient).DownloadFile('https://download.visualstudio.microsoft.com/download/pr/70062b11-491c-403c-91db-9d84462ee292/5db435e39128cbb608e76bf5111ab3dc/dotnet-sdk-3.1.413-win-x64.exe', 'C:\dotnet-sdk-3.1.413-win-x64.exe')

# Download Windows Hosting
Wait-Install
(New-Object System.Net.WebClient).DownloadFile('https://download.visualstudio.microsoft.com/download/pr/a0da9621-68f0-439a-b617-4697ee0669e3/38eb4aa6e879b9f06b73599ea2e1535f/dotnet-hosting-5.0.10-win.exe', 'C:\dotnet-hosting-5.0.10-win.exe')
$pathArgs = {C:\dotnet-hosting-5.0.10-win.exe /Install /Quiet /Norestart /Logs logHostingPackage.txt}
Invoke-Command -ScriptBlock $pathArgs

$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://github.com/Azure/azure-powershell/releases/download/v5.0.0-October2020/Az-Cmdlets-5.0.0.33612-x64.msi","C:\Packages\Az-Cmdlets-5.0.0.33612-x64.msi")

sleep 5

Start-Process msiexec.exe -Wait '/I C:\Packages\Az-Cmdlets-5.0.0.33612-x64.msi /qn' -Verbose 

# Install .NET Core 3.1 SDK
Wait-Install
Write-Host "Installing .NET Core 3.1 SDK..."
$pathArgs = {C:\dotnet-sdk-3.1.413-win-x64.exe /Install /Quiet /Norestart /Logs logCore31SDK.txt}
Invoke-Command -ScriptBlock $pathArgs


# Copy Web Site Files
Wait-Install
Write-Host "Copying default website files..."

$sourceFile = "C:\MCW\MCW-App-modernization-$branchName\Hands-on lab\lab-files\PartsUnlimitedWebsite.zip"
$destinationFolder =  'C:\inetpub\wwwroot'

# Load the System.IO.Compression.FileSystem assembly
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Use .NET classes to extract the contents of the file
[System.IO.Compression.ZipFile]::ExtractToDirectory($sourceFile, $destinationFolder) 

# Enable SQL Server ports on the Windows firewall
function Add-SqlFirewallRule {
    $fwPolicy = $null
    $fwPolicy = New-Object -ComObject HNetCfg.FWPolicy2

    $NewRule = $null
    $NewRule = New-Object -ComObject HNetCfg.FWRule

    $NewRule.Name = "SqlServer"
    # TCP
    $NewRule.Protocol = 6
    $NewRule.LocalPorts = 1433
    $NewRule.Enabled = $True
    $NewRule.Grouping = "SQL Server"
    # ALL
    $NewRule.Profiles = 7
    # ALLOW
    $NewRule.Action = 1
    # Add the new rule
    $fwPolicy.Rules.Add($NewRule)
}

Add-SqlFirewallRule

# Attach the downloaded backup files to the local SQL Server instance
function Setup-Sql {
    #Add snap-in
    Add-PSSnapin SqlServerCmdletSnapin* -ErrorAction SilentlyContinue

    $ServerName = 'SQLSERVER2008'
    $DatabaseName = 'PartsUnlimited'
    
    $Cmd = "USE [master] CREATE DATABASE [$DatabaseName]"
    Invoke-Sqlcmd $Cmd -QueryTimeout 3600 -ServerInstance $ServerName

    Invoke-Sqlcmd "ALTER DATABASE [$DatabaseName] SET DISABLE_BROKER;" -QueryTimeout 3600 -ServerInstance $ServerName
    
    Invoke-Sqlcmd "CREATE LOGIN PUWebSite WITH PASSWORD = '$SqlPass';" -QueryTimeout 3600 -ServerInstance $ServerName
    Invoke-Sqlcmd "USE [$DatabaseName];CREATE USER PUWebSite FOR LOGIN [PUWebSite];EXEC sp_addrolemember 'db_owner', 'PUWebSite'; " -QueryTimeout 3600 -ServerInstance $ServerName

    Invoke-Sqlcmd "EXEC sp_addsrvrolemember @loginame = N'PUWebSite', @rolename = N'sysadmin';" -QueryTimeout 3600 -ServerInstance $ServerName

    Invoke-Sqlcmd "EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2" -QueryTimeout 3600 -ServerInstance $ServerName

    Restart-Service -Force MSSQLSERVER
    #In case restart failed but service was shut down.
    Start-Service -Name 'MSSQLSERVER' 
}

Setup-Sql


Unregister-ScheduledTask -TaskName "Install Lab Requirements" -Confirm:$false

# Restart the app for the startup to pick up the database connection string.
Write-Host "Restarting IIS"
iisreset.exe /restart

$branchName = "Migrate-Secure"

Copy-Item "C:\MCW\MCW-App-modernization-$branchName\Hands-on lab\lab-files\src\src\PartsUnlimitedWebsite\config.json" -Destination 'C:\inetpub\wwwroot' -Force


Restart-Service -Force MSSQLSERVER
#In case restart failed but service was shut down.
Start-Service -Name 'MSSQLSERVER'
