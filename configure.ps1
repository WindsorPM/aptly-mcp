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

# Escape backslashes for JSON (single \ becomes \\)
$pathForJson = $ServerPath.Replace('\', '\\')
$keyForJson = $ApiKey.Replace('\', '\\').Replace('"', '\"')

# Build the aptlyMCP JSON block as a raw string — no ConvertTo-Json
$aptlyBlock = @"
    "aptlyMCP": {
      "command": "node",
      "args": ["$pathForJson"],
      "env": {
        "APTLY_API_KEY": "$keyForJson"
      }
    }
"@

if (Test-Path $configPath) {
    $raw = Get-Content $configPath -Raw

    if ($raw -match '"aptlyMCP"') {
        # Replace existing aptlyMCP block
        $raw = $raw -replace '"aptlyMCP"\s*:\s*\{[^}]*\{[^}]*\}[^}]*\}', $aptlyBlock.Trim()
    } elseif ($raw -match '"mcpServers"\s*:\s*\{') {
        # Add aptlyMCP to existing mcpServers
        $raw = $raw -replace '("mcpServers"\s*:\s*\{)', "`$1`n$aptlyBlock,"
    } else {
        # Add mcpServers section
        $raw = $raw -replace '\{', "{`n  ""mcpServers"": {`n$aptlyBlock`n  },", 1
    }

    Set-Content $configPath -Value $raw -Encoding UTF8
} else {
    # Create fresh config
    $json = @"
{
  "mcpServers": {
$aptlyBlock
  }
}
"@
    Set-Content $configPath -Value $json -Encoding UTF8
}
