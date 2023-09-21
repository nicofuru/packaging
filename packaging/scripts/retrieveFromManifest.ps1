#!/usr/bin/env pwsh
$configPath = "packaging\config\setup.json"

if (Test-Path $configPath) {
    $config = Get-Content $configPath | ConvertFrom-Json
    if ($config.PSObject.Properties.Name.Contains('sourceOrg')) {
        $sourceOrgAlias = $config.sourceOrg.orgAlias
    }else {
        Write-Host 'Please configure sourceOrg'
        exit
    }
    if ($config.PSObject.Properties.Name.Contains('unmanagedScratchOrg')) {
        $unmanagedScratchOrgAlias = $config.unmanagedScratchOrg.orgAlias
    }else {
        Write-Host 'Please configure sourceOrg'
        exit
    }
}else{
    Write-Host 'Please configure orgs'
    exit
}

$directoryToUnpack = "./unmanagedScratchOrg"

Push-Location $directoryToUnpack



#This part of the code is to deploy everything to have it ready for package version creation 
sf project retrieve start --manifest manifest\package.xml  -o $sourceOrgAlias 
#Get the file on ./mdapipkg/package.xml and replace the package.xml on .manifest/package.xml
sf project deploy start --manifest manifest\package.xml  -o $unmanagedScratchOrgAlias

sf org open --target-org $unmanagedScratchOrgAlias


# now back to previous directory 
Pop-Location