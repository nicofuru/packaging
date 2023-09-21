#!/usr/bin/env pwsh
$configPath = "packaging\config\setup.json"
$config = Get-Content $configPath | ConvertFrom-Json

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
    if ($config.PSObject.Properties.Name.Contains('sourcePackageName')) {
        $packageName = $config.sourcePackageName
    }else {
        $packageName = Read-Host -Prompt 'Enter the package name'
        $config | Add-Member -Name 'sourcePackageName' -Value $packageName -MemberType NoteProperty
        $config | ConvertTo-Json -Depth 2 | Set-Content $configPath
    }  
}else{
    Write-Host 'Please configure orgs'
    exit
}

$directoryToUnpack = "./unmanagedScratchOrg"

Push-Location $directoryToUnpack

if (Test-Path "./mdapipkg") {
    Remove-Item "./mdapipkg" -Force -Recurse
}

#This part of the code is to deploy everything to have it ready for package version creation 
sfdx force:mdapi:retrieve -s -r "./mdapipkg"  -u $sourceOrgAlias -p $packageName
Expand-Archive -LiteralPath ./mdapipkg/unpackaged.zip -DestinationPath ./mdapipkg
#Get the file on ./mdapipkg/package.xml and replace the package.xml on .manifest/package.xml
Copy-Item -Path ./mdapipkg/package.xml -Destination ./manifest/package.xml -Force


sf project convert mdapi -r "./mdapipkg" -d "./" 
Remove-Item -Path "./mdapipkg" -Recurse -Force

sf project deploy start --manifest manifest\package.xml  -o $unmanagedScratchOrgAlias

sf org open --target-org $unmanagedScratchOrgAlias

# now back to previous directory 
Pop-Location




