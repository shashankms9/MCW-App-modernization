Set-ExecutionPolicy -ExecutionPolicy bypass -Force


$SqlPass = "demo!pass123"

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
