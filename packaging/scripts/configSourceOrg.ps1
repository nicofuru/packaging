$path = "packaging\config\setup.json"
function InitialSetup {
    param (
        [Parameter(Mandatory=$true)]
        [string]$configPath    
    )
    $orgAlias = Read-Host "Enter Org Alias"
    $test = Read-Host "Enter y if you are logging to a sandbox or n otherwise"

    if (Test-Path $configPath) {
        # Get the content from the JSON file
        $config = Get-Content $configPath | ConvertFrom-Json
        
        # Check if unmanagedScratchOrg property doesn't exist and add it
        if (-not $config.PSObject.Properties.Name.Contains('sourceOrg')) {
            $sourceOrg = @{
                orgAlias = $orgAlias
            }
            $config | Add-Member -Name 'sourceOrg' -Value $sourceOrg -MemberType NoteProperty
        }else{
            $config.sourceOrg = @{
                orgAlias = $orgAlias
            }
        }

        # Save the updated config structure
        $config | ConvertTo-Json -Depth 2 | Set-Content $configPath
    
    } else {    
        Write-Host "Config file not found. Creating a new one..."
    
        # Initial structure
        $config = @{
            sourceOrg = @{
                orgAlias = $orgAlias
            }
        }
    
        # Save the new config structure
        $config | ConvertTo-Json -Depth 2 | Set-Content $configPath
    }
    
    LoginToOrg -orgAlias $orgAlias  -test $test
    Write-Output "Initial setup complete!"
}

function LoginToOrg{
    param (
        [string]$orgAlias,
        [string]$test
    )
    $url = ''
    if($test -eq 'y'){
        $url = 'https://test.salesforce.com'
    }elseif($test -eq 'n'){
        $url = 'https://login.salesforce.com'
    }else{
        Write-Host 'Invalid Option'
    }
    sf org login web -a $orgAlias --instance-url $url
}

function ChangeAlias {
    $config = Get-Content $path | ConvertFrom-Json
    $newAlias = Read-Host "Enter New Alias"
    $config.sourceOrg.orgAlias = $newAlias

    $config | ConvertTo-Json -Depth 2 | Set-Content $path
    Write-Output "Alias changed!"
}

while ($true) {
    Write-Output "Choose an option:"
    Write-Output "1. Initial Setup"
    Write-Output "2. Change Alias"
    Write-Output "3. Exit"

    $choice = Read-Host "Enter your choice"

    switch ($choice) {
        "1" { InitialSetup -configPath $path }
        "2" { ChangeAlias }
        "3" { exit }
        default { Write-Output "Invalid choice, please try again." }
    }
}