﻿# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Pester testing file')]
[CmdletBinding()]
param()

Mock Get-WmiObjectHandler {
    param (
        [string]$ComputerName,
        [string]$Class,
        [string]$Filter,
        [string]$Namespace
    )

    switch ($Class) {
        "Win32_ComputerSystem" { return Import-Clixml "$Script:MockDataCollectionRoot\Hardware\HyperV_Win32_ComputerSystem.xml" }
        "Win32_PhysicalMemory" { return Import-Clixml "$Script:MockDataCollectionRoot\Hardware\HyperV_Win32_PhysicalMemory.xml" }
        "Win32_Processor" { return Import-Clixml "$Script:MockDataCollectionRoot\Hardware\HyperV_Win32_Processor.xml" }
        "Win32_OperatingSystem" { return Import-Clixml "$Script:MockDataCollectionRoot\OS\Win32_OperatingSystem.xml" }
        "Win32_PowerPlan" { return Import-Clixml "$Script:MockDataCollectionRoot\OS\Win32_PowerPlan.xml" }
        "Win32_PageFileSetting" { return Import-Clixml "$Script:MockDataCollectionRoot\OS\Win32_PageFileSetting.xml" }
        "Win32_NetworkAdapterConfiguration" { return Import-Clixml "$Script:MockDataCollectionRoot\OS\Win32_NetworkAdapterConfiguration.xml" }
        "Win32_NetworkAdapter" { return Import-Clixml "$Script:MockDataCollectionRoot\OS\Win32_NetworkAdapter.xml" }
        default { throw "Failed to find class" }
    }
}

Mock Invoke-ScriptBlockHandler -ParameterFilter { $ScriptBlockDescription -eq "Trying to get the System.Environment ProcessorCount" } -MockWith { return 4 }
Mock Invoke-ScriptBlockHandler -ParameterFilter { $ScriptBlockDescription -eq "Getting Current Time Zone" } -MockWith { return "Pacific Standard Time" }
Mock Invoke-ScriptBlockHandler -ParameterFilter { $ScriptBlockDescription -eq "Test EEMS pattern service connectivity" } -MockWith { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\WebRequest_GetExchangeMitigations.xml" }
Mock Invoke-ScriptBlockHandler -ParameterFilter { $ScriptBlockDescription -eq "Get TokenCacheModule version information" } -MockWith { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\IIS\GetVersionInformationCachTokn.xml" }

Mock Get-WinEvent -ParameterFilter { $LogName -eq "Application" -and $Oldest -eq $true -and $MaxEvents -eq 1 } -MockWith {
    $r = Import-Clixml "$Script:MockDataCollectionRoot\OS\GetWinEventOldestApplication.xml"
    $r.TimeCreated = ((Get-Date).AddDays(-8))
    return $r
}
Mock Get-WinEvent -ParameterFilter { $LogName -eq "System" -and $Oldest -eq $true -and $MaxEvents -eq 1 } -MockWith {
    $r = Import-Clixml "$Script:MockDataCollectionRoot\OS\GetWinEventOldestSystem.xml"
    $r.TimeCreated = ((Get-Date).AddDays(-8))
    return $r
}
Mock Get-WinEvent -ParameterFilter { $ListLog -eq "Application" } -MockWith { return Import-Clixml "$Script:MockDataCollectionRoot\OS\GetWinEventApplication.xml" }
Mock Get-WinEvent -ParameterFilter { $ListLog -eq "System" } -MockWith { return Import-Clixml "$Script:MockDataCollectionRoot\OS\GetWinEventSystem.xml" }

# Handle IIS collection of files
Mock Invoke-ScriptBlockHandler -ParameterFilter { $ScriptBlockDescription -eq "Getting applicationHost.config" } -MockWith { return Get-Content "$Script:MockDataCollectionRoot\Exchange\IIS\applicationHost.config" -Raw -Encoding UTF8 }

Mock Get-CimInstance -ParameterFilter { $ClassName -eq "Win32_DeviceGuard" } -MockWith { return [PSCustomObject]@{ SecurityServicesRunning = @(0 , 0) } }

# WebAdministration
function Get-WebSite { param($Name) }
Mock Get-WebSite -ParameterFilter { $null -eq $Name } -MockWith { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\IIS\GetWebSite.xml" }
Mock Get-WebSite -ParameterFilter { $Name -eq "Default Web Site" } -MockWith { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\IIS\GetWebSite_DefaultWebSite.xml" }
Mock Get-WebSite -ParameterFilter { $Name -eq "Exchange Back End" } -MockWith { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\IIS\GetWebSite_ExchangeBackEnd.xml" }

Mock Test-Path -ParameterFilter { $Path -eq "C:\Program Files\Microsoft\Exchange Server\V15\FrontEnd\HttpProxy\SharedWebConfig.config" } -MockWith { return $true }
Mock Test-Path -ParameterFilter { $Path -eq "C:\Program Files\Microsoft\Exchange Server\V15\ClientAccess\SharedWebConfig.config" } -MockWith { return $true }
Mock Test-Path -ParameterFilter { $Path -eq "C:\Program Files\Microsoft\Exchange Server\V15\Bin\EdgeTransport.exe.config" } -MockWith { return $true }
Mock Test-Path -ParameterFilter { $Path -eq "C:\Program Files\Microsoft\Exchange Server\V15\Bin\Search\Ceres\Runtime\1.0\noderunner.exe.config" } -MockWith { return $true }
Mock Test-Path -ParameterFilter { $Path -eq "C:\Program Files\Microsoft\Exchange Server\V15\Bin\Monitoring\Config\AntiMalware.xml" } -MockWith { return $true }

Mock Get-Content -ParameterFilter { $Path -eq "C:\Program Files\Microsoft\Exchange Server\V15\FrontEnd\HttpProxy\SharedWebConfig.config" } -MockWith { Get-Content "$Script:MockDataCollectionRoot\Exchange\IIS\DefaultWebSite_SharedWebConfig.config" -Raw -Encoding UTF8 }
Mock Get-Content -ParameterFilter { $Path -eq "C:\Program Files\Microsoft\Exchange Server\V15\ClientAccess\SharedWebConfig.config" } -MockWith { Get-Content "$Script:MockDataCollectionRoot\Exchange\IIS\ExchangeBackEnd_SharedWebConfig.config" -Raw -Encoding UTF8 }
Mock Get-Content -ParameterFilter { $Path -eq "C:\Program Files\Microsoft\Exchange Server\V15\Bin\EdgeTransport.exe.config" } -MockWith { Get-Content "$Script:MockDataCollectionRoot\Exchange\EdgeTransport.exe.config" -Raw -Encoding UTF8 }
Mock Get-Content -ParameterFilter { $Path -eq "C:\Program Files\Microsoft\Exchange Server\V15\Bin\Search\Ceres\Runtime\1.0\noderunner.exe.config" } -MockWith { Get-Content "$Script:MockDataCollectionRoot\Exchange\noderunner.exe.config" -Raw -Encoding UTF8 }
Mock Get-Content -ParameterFilter { $Path -eq "C:\Program Files\Microsoft\Exchange Server\V15\Bin\Monitoring\Config\AntiMalware.xml" } -MockWith { Get-Content "$Script:MockDataCollectionRoot\Exchange\AntiMalware.xml" -Raw -Encoding UTF8 }

function Get-WebApplication { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\IIS\GetWebApplication.xml" }

function Get-WebBinding { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\IIS\GetWebBinding.xml" }
function Get-WebConfigFile {
    param (
        [string[]]$PSPath
    )

    # return the object with FullName as that is all it is used for pointing to the file we want to test against
    switch ($PSPath) {
        "IIS:\Sites\Default Web Site" { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\DefaultWebSite_web.config" } }
        "IIS:\Sites\Exchange Back End" { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\applicationHost.config" } }
        "IIS:\Sites\Default Web Site/API" { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\DefaultWebSite-Rest_web.config" } }
        { $_ -like "IIS:\Sites\Default Web Site/owa*" } { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\DefaultWebSite-OWA_web.config" } }
        "IIS:\Sites\Default Web Site/ecp" { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\DefaultWebSite-ECP_web.config" } }
        "IIS:\Sites\Default Web Site/EWS" { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\DefaultWebSite-EWS_web.config" } }
        "IIS:\Sites\Default Web Site/Autodiscover" { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\DefaultWebSite-AutoD_web.config" } }
        "IIS:\Sites\Default Web Site/Microsoft-Server-ActiveSync" { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\DefaultWebSite-EAS_web.config" } }
        "IIS:\Sites\Default Web Site/OAB" { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\DefaultWebSite-OAB_web.config" } }
        "IIS:\Sites\Default Web Site/PowerShell" { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\DefaultWebSite-PowerShell_web.config" } }
        "IIS:\Sites\Default Web Site/mapi" { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\DefaultWebSite-MAPI_web.config" } }
        "IIS:\Sites\Default Web Site/rpc" { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\DefaultWebSite-rpc_web.config" } }
        "IIS:\Sites\Exchange Back End/API" { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\ExchangeBackEnd-Rest_web.config" } }
        "IIS:\Sites\Exchange Back End/PowerShell" { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\ExchangeBackEnd-PowerShell_web.config" } }
        "IIS:\Sites\Exchange Back End/mapi/emsmdb" { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\ExchangeBackEnd-MapiEmsmdb_web.config" } }
        "IIS:\Sites\Exchange Back End/mapi/nspi" { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\ExchangeBackEnd-MapiNspi_web.config" } }
        "IIS:\Sites\Exchange Back End/PushNotifications" { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\ExchangeBackEnd-Push_web.config" } }
        { $_ -like "IIS:\Sites\Exchange Back End/owa*" } { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\ExchangeBackEnd-OWA_web.config" } }
        "IIS:\Sites\Exchange Back End/OAB" { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\ExchangeBackEnd-OAB_web.config" } }
        "IIS:\Sites\Exchange Back End/ecp" { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\ExchangeBackEnd-Ecp_web.config" } }
        { $_ -like "IIS:\Sites\Exchange Back End/Autodiscover*" } { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\ExchangeBackEnd-AutoD_web.config" } }
        "IIS:\Sites\Exchange Back End/Microsoft-Server-ActiveSync" { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\ExchangeBackEnd-EAS_web.config" } }
        { $_ -like "IIS:\Sites\Exchange Back End/EWS*" } { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\ExchangeBackEnd-EWS_web.config" } }
        { $_ -like "IIS:\Sites\Exchange Back End/Rpc*" } { return [PSCustomObject]@{ FullName = "$Script:MockDataCollectionRoot\Exchange\IIS\ExchangeBackEnd-Rpc_web.config" } }
        default { throw "Failed to find $PSPath" }
    }
}
# End Handle IIS collection of files

Mock Get-RemoteRegistryValue {
    param(
        [string]$SubKey,
        [string]$GetValue
    )

    switch ($GetValue) {
        "DisabledComponents" { return $null }
        "KeepAliveTime" { return 90000 }
        "MinimumConnectionTimeout" { return 0 }
        "LmCompatibilityLevel" { return $null }
        "UBR" { return 720 }
        "ProductName" { return Import-Clixml "$Script:MockDataCollectionRoot\OS\RemoteRegistryValueProductName.xml" }
        "InstallationType" { return Import-Clixml "$Script:MockDataCollectionRoot\OS\RemoteRegistryValueInstallationType.xml" }
        "DisableCompression" { return 0 }
        "CtsProcessorAffinityPercentage" { return 0 }
        "Enabled" { return 0 }
        "DisableGranularReplication" { return 0 }
        "DisableAsyncNotification" { return 0 }
        "MsiInstallPath" { return "C:\Program Files\Microsoft\Exchange Server\V15" }
        "AllowInsecureRenegoClients" { return 0 }
        "AllowInsecureRenegoServers" { return 0 }
        "EnableSerializationDataSigning" { return 0 }
        "LsaCfgFlags" { return 0 }
        "DynamicDaylightTimeDisabled" { return 0 }
        "TimeZoneKeyName" { return "Pacific Standard Time" }
        "StandardStart" { return @(0, 0, 11, 0, 1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0) }
        "DaylightStart" { return @(0, 0, 3, 0, 2, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0) }
        "DisableBaseTypeCheckForDeserialization" { return $null }
        "DisablePreservation" { return 0 }
        "DatabasePath" { return "$Script:MockDataCollectionRoot\Exchange" }
        "SuppressExtendedProtection" { return 0 }
        "EnableEccCertificateSupport" { return $null }
        default { throw "Failed to find GetValue: $GetValue" }
    }
}

Mock Get-RemoteRegistrySubKey {
    param(
        [string]$MachineName,
        [string]$SubKey
    )

    switch ($SubKey) {
        "SOFTWARE\Microsoft\Updates\Exchange 2013" { return $null }
        "SOFTWARE\Microsoft\Updates\Exchange 2016" { return $null }
        "SOFTWARE\Microsoft\Updates\Exchange 2019" { return $null }
        default { throw "Failed to find SubKey: $SubKey" }
    }
}

Mock Get-NETFrameworkVersion {
    return [PSCustomObject]@{
        FriendlyName  = "4.8"
        RegistryValue = 528040
        MinimumValue  = 528040
    }
}

Mock Get-DotNetDllFileVersions {
    return Import-Clixml "$Script:MockDataCollectionRoot\OS\GetDotNetDllFileVersions.xml"
}

Mock Get-NicPnpCapabilitiesSetting {
    return [PSCustomObject]@{
        PnPCapabilities   = 24
        SleepyNicDisabled = $true
    }
}

Mock Get-NetIPConfiguration {
    return Import-Clixml "$Script:MockDataCollectionRoot\OS\GetNetIPConfiguration.xml"
}

Mock Get-DnsClient {
    return Import-Clixml "$Script:MockDataCollectionRoot\OS\GetDnsClient.xml"
}

Mock Get-NetAdapterRss {
    return Import-Clixml "$Script:MockDataCollectionRoot\OS\GetNetAdapterRss.xml"
}

Mock Get-HotFix {
    return Import-Clixml "$Script:MockDataCollectionRoot\OS\GetHotFix.xml"
}

Mock Get-ServerRebootPending {
    return Import-Clixml "$Script:MockDataCollectionRoot\OS\GetServerRebootPending.xml"
}

Mock Get-AllTlsSettings {
    return Import-Clixml "$Script:MockDataCollectionRoot\OS\GetAllTlsSettings.xml"
}

Mock Get-VisualCRedistributableInstalledVersion {
    return Import-Clixml "$Script:MockDataCollectionRoot\OS\GetVisualCRedistributableInstalledVersion.xml"
}

Mock Get-SmbServerConfiguration {
    return Import-Clixml "$Script:MockDataCollectionRoot\OS\GetSmbServerConfiguration.xml"
}

Mock Get-ExchangeAppPoolsInformation {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetExchangeAppPoolsInformation.xml"
}

Mock Get-ExchangeAdSchemaClass -ParameterFilter { $SchemaClassName -eq "ms-Exch-Storage-Group" } {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetExchangeAdSchemaClass_ms-Exch-Storage-Group.xml"
}

Mock Get-ExchangeAdSchemaClass -ParameterFilter { $SchemaClassName -eq "ms-Exch-Schema-Version-Pt" } {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetExchangeAdSchemaClass_ms-Exch-Schema-Version-Pt.xml"
}

Mock Get-ExchangeDomainsAclPermissions {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetExchangeDomainsAclPermissions.xml"
}

Mock Get-ExchangeWellKnownSecurityGroups {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetExchangeWellKnownSecurityGroups.xml"
}

Mock Get-HttpProxySetting {
    return Import-Clixml "$Script:MockDataCollectionRoot\OS\GetHttpProxySetting.xml"
}

Mock Get-FIPFSScanEngineVersionState {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetFIPFSScanEngineVersionState.xml"
}

Mock Get-IISModules {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetIISModules.xml"
}

Mock Get-ExchangeADSplitPermissionsEnabled {
    return $false
}

Mock Get-ExSetupFileVersionInfo {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\ExSetup.xml"
}

Mock Get-LocalGroupMember {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetLocalGroupMember.xml"
}

# Do nothing
Mock Invoke-CatchActions { }

function Get-ExchangeDiagnosticInfo { param($Argument, $Component, $Process, $Server) }

Mock Get-ExchangeDiagnosticInfo -ParameterFilter { $Process -eq "Microsoft.Exchange.Directory.TopologyService" -and $Component -eq "VariantConfiguration" -and $Argument -eq "Overrides" } `
    -MockWith { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetExchangeDiagnosticInfo_ADTopVariantConfiguration.xml" }
Mock Get-ExchangeDiagnosticInfo -ParameterFilter { $Process -eq "EdgeTransport" -and $Component -eq "ResourceThrottling" } `
    -MockWith { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetExchangeDiagnosticInfo_EdgeTransportResourceThrottling.xml" }

Mock Get-LocalizedCounterSamples -ParameterFilter { $Counter -eq "\Network Interface(*)\Packets Received Discarded" } `
    -MockWith { return Import-Clixml "$Script:MockDataCollectionRoot\OS\GetCounterSamples.xml" }
Mock Get-LocalizedCounterSamples {
    $objList = New-Object System.Collections.Generic.List[object]
    $objList.Add(([PSCustomObject]@{
                OriginalCounterLookup = "\Processor(_Total)\% Processor Time"
                CookedValue           = 55.55555
            }))
    $objList.Add(([PSCustomObject]@{
                OriginalCounterLookup = "\Hyper-V Dynamic Memory Integration Service\Maximum Memory, MBytes"
                CookedValue           = 6144
            }))
    return $objList
}

# Need to use function instead of Mock for Exchange cmdlets
function Get-ExchangeServer {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetExchangeServer.xml"
}

function Get-ExchangeCertificate {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetExchangeCertificate.xml"
}

function Get-AuthConfig {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetAuthConfig.xml"
}

function Get-MailboxServer {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetMailboxServer.xml"
}

function Get-OwaVirtualDirectory {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetOwaVirtualDirectory.xml"
}

function Get-WebServicesVirtualDirectory {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetWebServicesVirtualDirectory.xml"
}

function Get-OrganizationConfig {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetOrganizationConfig.xml"
}

function Get-DynamicDistributionGroup {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetDynamicDistributionGroupPfMailboxes.xml"
}

function Get-IRMConfiguration {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetIrmConfiguration.xml"
}

function Get-ADPrincipalGroupMembership {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetADPrincipalGroupMembership.xml"
}

function Get-ADComputer { return $null }

# virtual directory cmdlets to return null till we do actual checks against the vDirs.
function Get-ActiveSyncVirtualDirectory { return $null }

function Get-AutodiscoverVirtualDirectory { return $null }

function Get-EcpVirtualDirectory { return $null }

function Get-MapiVirtualDirectory { return $null }

function Get-OutlookAnywhere { return $null }

function Get-PowerShellVirtualDirectory { return $null }

function Get-HybridConfiguration { return $null }

# Needs to be a function as PS core doesn't have -ComputerName parameter
function Get-Service {
    [CmdletBinding()]
    param(
        [string]$ComputerName,
        [string]$Name
    )
    if ($Name -eq "MSExchangeMitigation") { return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetServiceMitigation.xml" }
    return Import-Clixml "$Script:MockDataCollectionRoot\OS\GetService.xml"
}

function Get-ServerComponentState {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetServerComponentState.xml"
}

function Test-ServiceHealth {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\TestServiceHealth.xml"
}

function Get-SettingOverride {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetSettingOverride.xml"
}

function Get-AcceptedDomain {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetAcceptedDomain.xml"
}

function Get-ReceiveConnector {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetReceiveConnector.xml"
}

function Get-SendConnector {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetSendConnector.xml"
}

function Get-ExchangeProtocolContainer {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetExchangeProtocolContainer.xml"
}
function Get-ExchangeWebSitesFromAd {
    return Import-Clixml "$Script:MockDataCollectionRoot\Exchange\GetExchangeWebSitesFromAd.xml"
}

function Get-WindowsFeature {
    return Import-Clixml "$Script:MockDataCollectionRoot\OS\GetWindowsFeature.xml"
}

function Get-GlobalMonitoringOverride {
    return $null
}

function Get-ServerMonitoringOverride {
    return $null
}

function Get-AuthServer {
    param(
        [ValidateSet("ACS", "EvoSTS", "All")]
        [string]$Type = "All"
    )

    $returnListObject =  New-Object System.Collections.Generic.List[object]

    $orgId = $((New-Guid).Guid)
    $tenantId = $((New-Guid).Guid)
    $applicationId = $((New-Guid).Guid)

    $acs = [PSCustomObject]@{
        Name                           = "ACS - $orgId"
        Id                             = "ACS - $orgId"
        IssuerIdentifier               = "00000001-0000-0000-c000-000000000000"
        Realm                          = $tenantId
        TokenIssuingEndpoint           = "https://accounts.accesscontrol.windows.net/$tenantId/tokens/OAuth/2"
        AuthorizationEndpoint          = $null
        ApplicationIdentifier          = $null
        AuthMetadataUrl                = "https://accounts.accesscontrol.windows.net/$tenantId/metadata/json/1"
        DomainName                     = @("contoso.mail.onmicrosoft.com", "contoso.com")
        Type                           = "MicrosoftACS"
        Enabled                        = $true
        IsDefaultAuthorizationEndpoint = $false
    }

    $evoSts = [PSCustomObject]@{
        Name                           = "EvoSts - $orgId"
        Id                             = "EvoSts - $orgId"
        IssuerIdentifier               = "https://sts.windows.net/$tenantId/"
        Realm                          = $tenantId
        TokenIssuingEndpoint           = "https://login.windows.net/common/oauth2/token"
        AuthorizationEndpoint          = "https://login.windows.net/common/oauth2/authorize"
        ApplicationIdentifier          = $applicationId
        AuthMetadataUrl                = "https://login.windows.net/$tenantId/federationmetadata/2007-06/federationmetadata.xml"
        DomainName                     = @("contoso.mail.onmicrosoft.com")
        Type                           = "AzureAD"
        Enabled                        = $true
        IsDefaultAuthorizationEndpoint = $true
    }

    switch ($Type) {
        "ACS" { $returnListObject.Add($acs) }
        "EvoSTS" { $returnListObject.Add($evoSts) }
        "All" { $returnListObject.AddRange(@($acs, $evoSts)) }
    }

    return $returnListObject
}
