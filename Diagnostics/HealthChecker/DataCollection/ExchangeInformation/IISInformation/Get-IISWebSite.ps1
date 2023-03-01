﻿# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

function Get-IISWebSite {
    param(
        [array]$WebSitesToProcess
    )

    $returnList = New-Object 'System.Collections.Generic.List[object]'
    $webSites = New-Object 'System.Collections.Generic.List[object]'

    if ($null -eq $WebSitesToProcess) {
        $webSites.AddRange((Get-WebSite))
    } else {
        foreach ($iisWebSite in $WebSitesToProcess) {
            $webSites.Add((Get-WebSite -Name $($iisWebSite)))
        }
    }

    $bindings = Get-WebBinding

    foreach ($site in $webSites) {
        $siteBindings = $bindings |
            Where-Object { $_.ItemXPath -like "*@name='$($site.name)' and @id='$($site.id)'*" }
        $configurationFilePath = (Get-WebConfigFile "IIS:\Sites\$($site.Name)").FullName
        $webConfigExists = Test-Path $configurationFilePath
        $webConfigContent = $null
        $validWebConfig = $false

        if ($webConfigExists) {
            $webConfigContent = Get-Content $configurationFilePath -Raw

            try {
                [xml]$webConfigContent | Out-Null
                $validWebConfig = $true
            } catch {
                # Inside of Invoke-Command, can't use Invoke-CatchActions
                Write-Verbose "Failed to convert IIS web config '$configurationFilePath' to xml. Exception: $($_.Exception)"
            }
        }

        $returnList.Add([PSCustomObject]@{
                Name                       = $site.Name
                Id                         = $site.Id
                State                      = $site.State
                Bindings                   = $siteBindings
                Limits                     = $site.Limits
                LogFile                    = $site.logFile
                TraceFailedRequestsLogging = $site.traceFailedRequestsLogging
                Hsts                       = $site.hsts
                ApplicationDefaults        = $site.applicationDefaults
                VirtualDirectoryDefaults   = $site.virtualDirectoryDefaults
                Collection                 = $site.collection
                ApplicationPool            = $site.applicationPool
                EnabledProtocols           = $site.enabledProtocols
                PhysicalPath               = $site.physicalPath.Replace("%windir%", $env:windir).Replace("%SystemDrive%", $env:SystemDrive)
                ConfigurationFileInfo      = [PSCustomObject]@{
                    Location = $configurationFilePath
                    Content  = $webConfigContent
                    Exist    = $webConfigExists
                    Valid    = $validWebConfig
                }
            }
        )
    }
    return $returnList
}
