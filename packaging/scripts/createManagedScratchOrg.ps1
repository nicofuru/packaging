#!/usr/bin/env pwsh

$configPath = ".\packaging\config\setup.json"
$orgAlias = "managedScratchOrg"

function InstallHealthCloud {
    param (
        [Parameter(Mandatory=$true)]
        [string]$orgAlias    
    )

    sf package install --package 04t4W000002V2H1QAK --target-org $orgAlias --wait 15
}

# Check if the file exists
if (Test-Path $configPath) {
    # Get the content from the JSON file
    $config = Get-Content $configPath | ConvertFrom-Json
    
    # Check if unmanagedScratchOrg property doesn't exist and add it
    if (-not $config.PSObject.Properties.Name.Contains('managedScratchOrg')) {
        $config | Add-Member -Name 'managedScratchOrg' -Value @{
            orgAlias  = $null
            password  = $null
            duration  = $null
            loginUrl  = $null
            username  = $null
        } -MemberType NoteProperty
    }

    $targetDevHub = $config.partnerBussinessOrg.orgAlias

} else {    
    Write-Host "Config file not found. Please select PBO First"
    exit
}

# Get input from user
$duration = Read-Host "Enter duration"

# Execute Salesforce commands

$scratchOrgConf = sfdx force:org:create -f packaging\config\managed-scratch-def.json --durationdays $duration -a $orgAlias --targetdevhubusername $targetDevHub --setdefaultusername --json
$scratchOrgConfObj = $scratchOrgConf | ConvertFrom-Json
$username = $scratchOrgConfObj.result.username
$loginUrl = $scratchOrgConfObj.result.scratchOrgInfo.LoginUrl

Write-Host $scratchOrgConf

$userConfig = sf org generate password --target-org $orgAlias --json
$userConfigObj = $userConfig | ConvertFrom-Json
$password = $userConfigObj.result.password


Write-Host $userConfig


# Construct and add the unmanagedScratchOrg object to the existing $config object

$config.managedScratchOrg.orgAlias = $orgAlias

$config.managedScratchOrg.password = $password
$config.managedScratchOrg.duration = $duration
if($loginUrl){
    $config.managedScratchOrg.loginUrl = $loginUrl
}
if($username){
    $config.managedScratchOrg.username = $username
}

# Save updated config
$config | ConvertTo-Json -Depth 2 | Set-Content $configPath

InstallHealthCloud -orgAlias $orgAlias



