
function Get-Config {
    param (
        [string]$configPath = "packaging\config\setup.json"
    )

    if (Test-Path $configPath) {
        return Get-Content $configPath | ConvertFrom-Json
    } else {
        Write-Host "Config file not found at $configPath"
        return $null
    }
}

function Write-Config {
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$config,

        [string]$configPath = "packaging\config\setup.json"
    )

    $config | ConvertTo-Json -Depth 10 | Set-Content $configPath
}

Export-ModuleMember -Function Get-Config, Write-Config