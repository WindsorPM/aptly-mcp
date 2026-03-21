# configure.ps1 — Merges aptlyMCP into Claude Desktop config
# Called by install-aptly.bat. Do not run directly.

param(
    [Parameter(Mandatory)][string]$ServerPath,
    [Parameter(Mandatory)][string]$ApiKey
)

$configPath = Join-Path $env:APPDATA "Claude\claude_desktop_config.json"
$configDir = Split-Path $configPath

# Ensure directory exists
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

# Build the aptlyMCP entry as a plain PowerShell object
# ConvertTo-Json will handle backslash escaping automatically
$aptlyObj = [PSCustomObject]@{
    command = "node"
    args = @($ServerPath)
    env = [PSCustomObject]@{
        APTLY_API_KEY = $ApiKey
    }
}

# Read or create config
if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json

    # Ensure mcpServers exists
    if (-not $config.mcpServers) {
        $config | Add-Member -NotePropertyName "mcpServers" -NotePropertyValue ([PSCustomObject]@{})
    }

    # Add or update aptlyMCP
    if ($config.mcpServers.PSObject.Properties["aptlyMCP"]) {
        $config.mcpServers.aptlyMCP = $aptlyObj
    } else {
        $config.mcpServers | Add-Member -NotePropertyName "aptlyMCP" -NotePropertyValue $aptlyObj
    }
} else {
    $config = [PSCustomObject]@{
        mcpServers = [PSCustomObject]@{
            aptlyMCP = $aptlyObj
        }
    }
}

$config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
