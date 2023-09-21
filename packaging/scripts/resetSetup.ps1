#!/usr/bin/env pwsh

Import-Module .\packaging\modules\packagingUtils.psm1

$config = Get-Config

# Create a new object with all properties set to null
$config = [PSCustomObject]@{
    partnerBussinessOrg   = [PSCustomObject]@{
        orgAlias = $null
    }
    unmanagedScratchOrg   = [PSCustomObject]@{
        orgAlias  = $null
        username  = $null
        duration  = $null
        loginUrl  = $null
        password  = $null
    }
    sourceOrg             = [PSCustomObject]@{
        orgAlias  = $null
    }
    managedScratchOrg     = [PSCustomObject]@{
        password  = $null
        duration  = $null
        username  = $null
        orgAlias  = $null
        loginUrl  = $null
    }
    packageConfig         = [PSCustomObject]@{
        packageId       = $null
        packageName     = $null
        installationKey = $null
    }
}

Write-Config -config $config

