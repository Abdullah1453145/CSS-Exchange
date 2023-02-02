﻿# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

. $PSScriptRoot\..\..\..\Shared\Invoke-CatchActionError.ps1

function Copy-ScriptToExchangeDirectory {
    [CmdletBinding()]
    [OutputType([System.Object])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$FullPathToScript = $MyInvocation.ScriptName,
        [Parameter(Mandatory = $false)]
        [ScriptBlock]$CatchActionFunction
    )

    Write-Verbose "Calling: $($MyInvocation.MyCommand)"

    $whatIfPathSimulation = $false
    $exchangeInstallPath = $env:ExchangeInstallPath
    $scriptName = $FullPathToScript.Split("\")[-1]

    if ($null -ne $exchangeInstallPath) {
        Write-Verbose ("ExchangeInstallPath is: $($exchangeInstallPath)")
        $localScriptsPath = [System.IO.Path]::Combine($exchangeInstallPath, "Scripts")

        try {
            if (-not(Test-Path -Path $localScriptsPath)) {
                Write-Verbose ("Folder: $($localScriptsPath) doesn't exist - it will be created now")
                if ($WhatIfPreference) {
                    Write-Host ("What if: Path '$($localScriptsPath)' doesn't exist and will now be created")
                    $whatIfPathSimulation = $true
                }
                New-Item -Path $exchangeInstallPath -ItemType Directory -Name "Scripts" -ErrorAction Stop | Out-Null
            }

            if (($whatIfPathSimulation) -or
                (Test-Path -Path $localScriptsPath -ErrorAction Stop)) {
                Write-Verbose ("Path: $($localScriptsPath) was successfully created")
                Copy-Item -Path $FullPathToScript -Destination $localScriptsPath -Force -ErrorAction Stop

                if (($whatIfPathSimulation) -or
                    (Test-Path -Path $FullPathToScript)) {
                    Write-Verbose ("Script: $($scriptName) successfully copied over to: $($localScriptsPath)")
                    return [PSCustomObject]@{
                        WorkingDirectory = $localScriptsPath
                        ScriptName       = $scriptName
                    }
                }
            }
        } catch {
            Write-Verbose ("Something went wrong - Exception: $($Error[0].Exception.Message)")
            Invoke-CatchActionError $CatchActionFunction
        }
    }

    return
}
