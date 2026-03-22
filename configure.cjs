// configure.cjs — Merges aptlyMCP into Claude Desktop config
// Called by install-aptly.bat. Do not run directly.
// Writes to BOTH standard and Microsoft Store config locations.

const fs = require('fs');
const path = require('path');
const glob = require('path');

const serverPath = process.argv[2];
const apiKey = process.argv[3];

if (!serverPath || !apiKey) {
  console.error('Usage: node configure.cjs <serverPath> <apiKey>');
  process.exit(1);
}

// Build the aptlyMCP entry
const aptlyEntry = {
  command: 'node',
  args: [serverPath],
  env: {
    APTLY_API_KEY: apiKey
  }
};

// Standard install path
const standardPath = path.join(process.env.APPDATA, 'Claude', 'claude_desktop_config.json');

// Microsoft Store (MSIX) path — look for the Claude package folder
const localAppData = process.env.LOCALAPPDATA || path.join(process.env.USERPROFILE, 'AppData', 'Local');
const packagesDir = path.join(localAppData, 'Packages');

let storePath = null;
if (fs.existsSync(packagesDir)) {
  try {
    const entries = fs.readdirSync(packagesDir);
    const claudePackage = entries.find(e => e.startsWith('Claude_'));
    if (claudePackage) {
      storePath = path.join(packagesDir, claudePackage, 'LocalCache', 'Roaming', 'Claude', 'claude_desktop_config.json');
    }
  } catch (e) {
    // Can't read packages dir — skip Store path
  }
}

// Collect all paths to write to
const configPaths = [standardPath];
if (storePath) configPaths.push(storePath);

// Update each config file
let updated = 0;
for (const configPath of configPaths) {
  const configDir = path.dirname(configPath);

  // Ensure directory exists
  if (!fs.existsSync(configDir)) {
    fs.mkdirSync(configDir, { recursive: true });
  }

  // Read or create config
  let config = {};
  if (fs.existsSync(configPath)) {
    try {
      config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    } catch (e) {
      console.error(`Warning: ${configPath} was invalid, preserving as backup`);
      fs.writeFileSync(configPath + '.bak', fs.readFileSync(configPath));
    }
  }

  // Merge
  if (!config.mcpServers) {
    config.mcpServers = {};
  }
  config.mcpServers.aptlyMCP = aptlyEntry;

  // Write
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2), 'utf8');
  console.log(`  Updated: ${configPath}`);
  updated++;
}

console.log(`  ${updated} config file(s) updated.`);
