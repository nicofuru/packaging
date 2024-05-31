#!/usr/bin/env pwsh

$configPath = ".\packaging\config\setup.json"
$orgAlias = "unmanagedScratchOrg"
$projectName = "unmanagedScratchOrg"

function InitialSetup {
    param (
        [Parameter(Mandatory=$true)]
        [string]$configPath,
        [string]$orgAlias,
        [string]$projectName      
    )
    
    CreateProject -configPath $configPath -projectName $projectName
    CreateScratchOrg -configPath $configPath -orgAlias $orgAlias

}

function CreateProject {
    param (
        [Parameter(Mandatory=$true)]
        [string]$configPath,
        [string]$projectName      
    )
    # Check if the file exists
    if (Test-Path $configPath) {
        # Get the content from the JSON file
        $config = Get-Content $configPath | ConvertFrom-Json
        $targetDevHub = $config.partnerBussinessOrg.orgAlias
    } else {
        Write-Host "Error: Config file not found."
        exit
    }


    # Check if the ./config/ directory exists, if not, create it
    if (-not (Test-Path ".\packaging\config")) {
        New-Item -ItemType Directory -Path ".\packaging\config"
    }

    # Execute Salesforce commands
    sf project generate --name $projectName --default-package-dir ./ --manifest

    # Construct and add the unmanagedScratchOrg object to the existing $config object
    Add-Member -InputObject $config -NotePropertyName 'unmanagedProjectName' -NotePropertyValue @{
        projectName = $projectName
    } -Force

    # Save updated config
    $config | ConvertTo-Json -Depth 2 | Set-Content $configPath

    Write-Output "Project created!"
}

function InstallHealthCloud {
    param (
        [Parameter(Mandatory=$true)]
        [string]$orgAlias    
    )

    sf package install --package 04t4W000002V2H1QAK --target-org $orgAlias --wait 15
}

function CreateScratchOrg {
    param (
        [Parameter(Mandatory=$true)]
        [string]$configPath,
        [string]$orgAlias     
    )
    # Check if the file exists
    if (Test-Path $configPath) {
        # Get the content from the JSON file
        $config = Get-Content $configPath | ConvertFrom-Json
        
        # Check if unmanagedScratchOrg property doesn't exist and add it
        if (-not $config.PSObject.Properties.Name.Contains('unmanagedScratchOrg')) {
            $config | Add-Member -Name 'unmanagedScratchOrg' -Value @{
                orgAlias  = $null
                password  = $null
                duration  = $null
                loginUrl  = $null
                username  = $null
            } -MemberType NoteProperty
        }
    
        $targetDevHub = $config.partnerBussinessOrg.orgAlias
    
    } else {    
        Write-Host "Config file not found. Creating a new one..."
    
        # Initial structure
        $config = @{
            unmanagedScratchOrg = @{
                orgAlias  = $null
                password  = $null
                duration  = $null
                loginUrl  = $null
                username  = $null
            }
        }
    
        # Save the new config structure
        $config | ConvertTo-Json -Depth 2 | Set-Content $configPath
    }

    # Get input from user
    $duration = Read-Host "Enter duration"

    # Execute Salesforce commands
    <# $scratchOrgConf = sf org create scratch --target-dev-hub $targetDevHub --definition-file packaging\config\unmanaged-scratch-def.json -a $orgAlias --duration-days $duration --json #>
    $scratchOrgConf = sfdx force:org:create -f packaging\config\unmanaged-scratch-def.json --durationdays $duration -a $orgAlias --targetdevhubusername $targetDevHub --setdefaultusername --json
    $scratchOrgConfObj = $scratchOrgConf | ConvertFrom-Json
    $username = $scratchOrgConfObj.result.username
    $loginUrl = $scratchOrgConfObj.result.scratchOrgInfo.LoginUrl

    Write-Host $scratchOrgConf

    $userConfig = sf org generate password --target-org $orgAlias --json
    $userConfigObj = $userConfig | ConvertFrom-Json
    $password = $userConfigObj.result.password


    Write-Host $userConfig
    

    # Construct and add the unmanagedScratchOrg object to the existing $config object
    
    $config.unmanagedScratchOrg.orgAlias = $orgAlias
    
    $config.unmanagedScratchOrg.password = $password
    $config.unmanagedScratchOrg.duration = $duration
    if($loginUrl){
        $config.unmanagedScratchOrg.loginUrl = $loginUrl
    }
    if($username){
        $config.unmanagedScratchOrg.username = $username
    }

    # Save updated config
    $config | ConvertTo-Json -Depth 2 | Set-Content $configPath

    do {
        Write-Host "Do you want to install HealthCloud?"
        Write-Host "y - Yes"
        Write-Host "n - No"
    
        $choice = Read-Host "Enter your choice"
    
        switch ($choice) {
            "y" {
                InstallHealthCloud -orgAlias $orgAlias
            }
            "n" {
                
            }
            default {
                Write-Host "Invalid choice, please try again."
            }
        }
    } while ($choice -ne "y" -and $choice -ne "n")

}

# Add this at the end of your script

do {
    Write-Host "Choose an option:"
    Write-Host "1. Initial Setup (Project Creation + Scratch Org Creation)"
    Write-Host "2. Create Scratch Org Only"
    Write-Host "3. Exit"

    $choice = Read-Host "Enter your choice"

    switch ($choice) {
        "1" {
            InitialSetup -configPath $configPath -orgAlias $orgAlias -projectName $projectName
        }
        "2" {
            CreateScratchOrg -configPath $configPath -orgAlias $orgAlias
        }
        "3" {
            Write-Host "Exiting..."
            break
        }
        default {
            Write-Host "Invalid choice, please try again."
        }
    }
} while ($choice -ne "3")





    
