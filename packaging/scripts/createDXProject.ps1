$configPath = ".\packaging\config\setup.json"
$projectName = "DXproject"


# Check if the file exists
if (Test-Path $configPath) {
    # Get the content from the JSON file
    $config = Get-Content $configPath | ConvertFrom-Json
} else {
    Write-Host "Error: Config file not found."
    exit
}


# Check if the ./config/ directory exists, if not, create it
if (-not (Test-Path ".\packaging\config")) {
    New-Item -ItemType Directory -Path ".\packaging\config"
}

# Execute Salesforce commands
sf project generate --name $projectName --default-package-dir ./

# Construct and add the unmanagedScratchOrg object to the existing $config object
Add-Member -InputObject $config -NotePropertyName 'DXprojectName' -NotePropertyValue @{
    projectName = $projectName
} -Force

# Save updated config
$config | ConvertTo-Json -Depth 2 | Set-Content $configPath

Write-Output "Project created!"


     