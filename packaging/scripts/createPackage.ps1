#!/usr/bin/env pwsh

Import-Module .\packaging\modules\packagingUtils.psm1

function RetrieveDataToDXProject {
    param (
        [string]$directoryToUnpack = "./DXproject"
    )
    Write-Host -ForegroundColor DarkGreen "Start retrieving from unamangedScratchOrg manifest to DX Project..."
    #Get configuration file, variables must have already been created
    $config = Get-Config
    if ($null -eq $config) {
        Write-Host "Configuration File Missing"
        exit
    }

    if ($config.PSObject.Properties.Name.Contains('unmanagedScratchOrg')) {
        $unmanagedScratchOrgAlias = $config.unmanagedScratchOrg.orgAlias
    } else {
        Write-Host 'Please configure unmanagedScratchOrg'
        exit
    }

    $manifestLocation = (Get-ChildItem "unmanagedScratchOrg/manifest/package.xml").FullName

    Push-Location $directoryToUnpack

    if (Test-Path "./mdapipkg") {
        Remove-Item "./mdapipkg" -Force -Recurse
    }

    # This part of the code is to deploy everything from unmanagedScratchOrg to DXProject to have it ready for package version creation 
    sf project retrieve start -o $unmanagedScratchOrgAlias -x $manifestLocation --target-metadata-dir "./" --unzip
    sf project convert mdapi --root-dir "./unpackaged/unpackaged" --output-dir "./"

    Remove-Item -Path "./unpackaged" -Recurse -Force

    # now back to previous directory 
    Pop-Location

    Write-Host -ForegroundColor DarkGreen "End retrieving from unamangedScratchOrg manifest to DX Project."
}

function PreProcessing {
    #Run Preprocessing Script
    Write-Host -ForegroundColor DarkGreen "Start prepackage configuration."
    .\packaging\filesForPreprocessing\preProcessingScript.ps1
    Write-Host -ForegroundColor DarkGreen "End prepackage configuration."
}

function RunScans {
    Write-Host -ForegroundColor DarkGreen "Running Scans..."
    sfdx scanner:run -f csv  -o "packaging\scanResults\scannerResultsRun.csv" -t "./DXproject"  --category="Security"
    sfdx scanner:run:dfa -f csv -o "packaging\scanResults\scannerResultsDFA.csv" -t "./DXproject" --category="Security" --projectdir "./DXproject/main"
    Write-Host -ForegroundColor DarkGreen "End Scans."
}

function ChangePackageConfig {

    $config = Get-Config
    if ($null -eq $config) {
        Write-Host "Configuration File Missing"
        exit
    }

    # Ask the user for the installation key and package Name
    $installationKey = Read-Host -Prompt "Please enter the installation key"
    $packageName = Read-Host -Prompt "Please enter the packageName"

    # Add a new node for packageConfig with the input installation key
    $config | Add-Member -Type NoteProperty -Name 'packageConfig' -Value @{
        installationKey = $installationKey
        packageId       = $null
        packageName     = $packageName
    } -Force

    return $config
}

function CreatePackageVersion {
    
    Write-Host -ForegroundColor DarkGreen "Starting package version creation..."
    $config = Get-Config
    if ($null -eq $config) {
        Write-Host 'Configuration file missing'
        return
    }

    if ($config.PSObject.Properties.Name.Contains('partnerBussinessOrg')) {
        $partnerBussinessOrgAlias = $config.partnerBussinessOrg.orgAlias
    } else {
        Write-Host 'Please configure PBO'
        return
    }

    if ($config.PSObject.Properties.Name.Contains('packageConfig')) {
        Write-Host "Current config is: $($config.packageConfig)"
        $changeConfig = Read-Host -Prompt "Do you want to change config(y/n)"
        if ($changeConfig -eq 'y') {
            $config = ChangePackageConfig
        }
    } else {
        $config = ChangePackageConfig
    }

    #Once we have all info we get the parameters
    $installationKey = $config.packageConfig.installationKey
    $packageName = $config.packageConfig.packageName
    
    #Run sf command in DX directory (mandatory)
    $dxProjectDirectory = "./DXproject"

    # Run Prepackaging Processes
    PreProcessing

    Push-Location $dxProjectDirectory

    do {
        # Prompt the user for input
        $skipAncestor = Read-Host "Enter 'y' to skip ancestor check, 'n' otherwise"
    
        if ($skipAncestor -eq 'y') {
            $packages = sf package version create --package $packageName --installation-key $installationKey --target-dev-hub $partnerBussinessOrgAlias --code-coverage --wait 30 --skip-ancestor-check --json | ConvertFrom-Json 
            break  # Exit the loop if a valid option is selected
        }
        elseif ($skipAncestor -eq 'n') {
            $packages = sf package version create --package $packageName --installation-key $installationKey --target-dev-hub $partnerBussinessOrgAlias --code-coverage --wait 30 --json | ConvertFrom-Json
            break  # Exit the loop if a valid option is selected
        }
        else {
            Write-Host 'Invalid Option. Please enter either ''y'' or ''n''.'
        }
    } while ($true)

    Pop-Location

    $packageResult = $packages | ConvertTo-Json
    Set-Content -Path "packaging/packageResult.json" -Value $packageResult -Force

    if ($packages.result.SubscriberPackageVersionId) {
        $config.packageConfig.packageId = $packages.result.SubscriberPackageVersionId
        Write-Host -ForegroundColor DarkGreen "Package Version Creation was sucessfull..."
    } else {
        Write-Host -ForegroundColor DarkRed "Package Version Creation was unsucessfull, review packaging/packageResult.json"
        $config.packageConfig.packageId = $null
    }

    Write-Config -config $config
}


function PromotePackage {
    
    Write-Host -ForegroundColor DarkGreen "Starting package version promotion..."
    $config = Get-Config
    if ($null -eq $config) {
        Write-Host 'Configuration file missing'
        return
    }

    if ($config.PSObject.Properties.Name.Contains('partnerBussinessOrg')) {
        $partnerBussinessOrgAlias = $config.partnerBussinessOrg.orgAlias
    }else {
        Write-Host 'Please configure partnerBussinessOrg'
        return
    }

    $packageVersionId = $config.packageConfig.packageId

    if($packageVersionId){

        $dxProjectDirectory = "./DXproject"

        Push-Location $dxProjectDirectory
        
        $versionResult = sf package version promote --package $packageVersionId --target-dev-hub $partnerBussinessOrgAlias --json

        Pop-Location

        Write-Host -ForegroundColor DarkGreen "Promotion ended with result: $versionResult"

    }else{
        Write-Host "Missing package Id or installation key in config/setup.json file"
        return
    }
        

}

function InstallPackage {
    
    Write-Host -ForegroundColor DarkGreen "Starting package installation..."
    $config = Get-Config
    if ($null -eq $config) {
        Write-Host 'Configuration file missing'
        return
    }

    $packageVersionId = $config.packageConfig.packageId
    $installationKey = $config.packageConfig.installationKey
    
    if($packageVersionId && $installationKey){

        $dxProjectDirectory = "./DXproject"

        Push-Location $dxProjectDirectory
        
        $installationResult = sf package install --package $packageVersionId --target-org 'managedScratchOrg' --installation-key $installationKey --json

        Pop-Location


        Pop-Location
        $installationResultObject = $installationResult | ConvertFrom-Json
        
        if($installationResultObject.result.Status -eq 'SUCCESS'){
            $config.managedScratchOrg.installedPackage = $packageVersionId
            Write-Host -ForegroundColor DarkGreen "Installation succeded!"
        }else{
            Write-Host -ForegroundColor DarkRed "Installation failed, check packaging\installationResults.json"
        }

        $installationResult | Set-Content -Path 'packaging\installationResults.json' -Force

    }else{
        Write-Host "Missing package Id or installation key in config/setup.json file"
        return
    }
}


do {
    Clear-Host
    Write-Host "Please select an option:"
    Write-Host "1. Retrieve Data To DX Project"
    Write-Host "2. Pre-Processing"
    Write-Host "3. Run Scans"
    Write-Host "4. Create Package Version"
    Write-Host "5. Promote Package"
    Write-Host "6. Install Package"
    Write-Host "7. Exit"

    $choice = Read-Host "Enter choice [1-8]"

    switch ($choice) {
        '1' { RetrieveDataToDXProject }
        '2' { PreProcessing }
        '3' { RunScans }
        '4' { CreatePackageVersion }
        '5' { PromotePackage }
        '6' { InstallPackage }
        '7' { exit }
        default { Write-Host "Invalid choice, please select a number between 1-8." }
    }
    
    Write-Host "Press any key to return to menu ..."
    $null = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

} until ($choice -eq '8')

