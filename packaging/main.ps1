#!/usr/bin/env pwsh

# Display menu
function DisplayMenu {
    Clear-Host
    Write-Host "Please choose one of the following options:"
    Write-Host "1 - Config Partner Business Org"
    Write-Host "2 - Config Source Org"
    Write-Host "3 - Create unmanaged package scratch org"
    Write-Host "4 - Deploy from source org to unmanagedScratch through package"
    Write-Host "5 - Deploy from source org to unmanagedScratch through manifest"
    Write-Host "6 - Create DX Project"
    Write-Host "7 - Create Managed ScratchOrg(Testing of managed package)"
    Write-Host "8 - Create Package"
    Write-Host "9 - Reset setup"
    Write-Host "10 - Ask for help"
    Write-Host "Q - Quit"
}

# Display help from the file
function DisplayHelp {
    $path = "./packaging/config/instructions.txt"
    if (Test-Path $path) {
        Get-Content $path
    } else {
        Write-Host "Error: $path not found."
    }
}

# Main script loop
do {
    # Show menu
    DisplayMenu

    # Get user input
    $choice = Read-Host "Enter your choice"

    # Execute the corresponding function based on user's choice
    switch ($choice) {
        '1' {
            .\packaging\scripts\configPBO.ps1

            Pause
        }
        '2' {
            .\packaging\scripts\configSourceOrg.ps1

            Pause
        }
        '3' {
            .\packaging\scripts\createUnmanagedScratchOrg.ps1

            Pause
        }
        '4' {
            .\packaging\scripts\retrieveUnmanagedPackage.ps1
            Pause
        }
        '5' {
            .\packaging\scripts\retrieveFromManifest.ps1
            Pause
        }
        '6' {
            .\packaging\scripts\createDXProject.ps1
            Pause
        }
        '7' {
            .\packaging\scripts\createManagedScratchOrg.ps1
            Pause
        }
        '8' {
            .\packaging\scripts\createPackage.ps1
            Pause
        }
        '9' {
            .\packaging\scripts\resetSetup.ps1
            Pause
        }
        '10' {
            # Code to display help from the file
            DisplayHelp
            Pause
        }
        'Q' { return }
        default {
            Write-Host "Invalid choice. Please try again."
            Pause
        }
    }
} until ($choice -eq 'Q')
