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

# Build the aptlyMCP entry with properly escaped path for JSON
$serverPathJson = $ServerPath -replace '\\', '\\'
$aptlyJson = @"
{
  "command": "node",
  "args": ["$serverPathJson"],
  "env": {
    "APTLY_API_KEY": "$ApiKey"
  }
}
"@
$aptlyObj = $aptlyJson | ConvertFrom-Json

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

# Write config — ConvertTo-Json won't double-escape because we built the
# entry from a pre-escaped JSON string via ConvertFrom-Json
$config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
