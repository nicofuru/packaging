
$path = "packaging\config\setup.json"
function InitialSetup {
    $orgAlias = Read-Host "Enter Org Alias"
    

    $obj = @{
        partnerBussinessOrg = @{
            orgAlias = $orgAlias
        }
    }

    $obj | ConvertTo-Json -Depth 2 | Set-Content $path
    LoginToOrg
    Write-Output "Initial setup complete!"
}

function LoginToOrg{
    sf org login web -a $orgAlias
}

function ChangeAlias {
    $config = Get-Content $path | ConvertFrom-Json
    $newAlias = Read-Host "Enter New Alias"
    $config.partnerBussinessOrg.orgAlias = $newAlias

    $config | ConvertTo-Json -Depth 2 | Set-Content $path
    LoginToOrg
    Write-Output "Alias changed!"
}

while ($true) {
    Write-Output "Choose an option:"
    Write-Output "1. Initial Setup"
    Write-Output "2. Change Alias"
    Write-Output "3. Exit"

    $choice = Read-Host "Enter your choice"

    switch ($choice) {
        "1" { InitialSetup }
        "2" { ChangeAlias }
        "3" { exit }
        default { Write-Output "Invalid choice, please try again." }
    }
}