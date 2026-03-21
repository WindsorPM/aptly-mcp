// configure.js — Merges aptlyMCP into Claude Desktop config
// Called by install-aptly.bat. Do not run directly.

const fs = require('fs');
const path = require('path');

const serverPath = process.argv[2];
const apiKey = process.argv[3];

if (!serverPath || !apiKey) {
  console.error('Usage: node configure.js <serverPath> <apiKey>');
  process.exit(1);
}

const configPath = path.join(process.env.APPDATA, 'Claude', 'claude_desktop_config.json');
const configDir = path.dirname(configPath);

// Ensure directory exists
if (!fs.existsSync(configDir)) {
  fs.mkdirSync(configDir, { recursive: true });
}

// Build the aptlyMCP entry
const aptlyEntry = {
  command: 'node',
  args: [serverPath],
  env: {
    APTLY_API_KEY: apiKey
  }
};

// Read or create config
let config = {};
if (fs.existsSync(configPath)) {
  try {
    config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  } catch (e) {
    // If config is corrupted, start fresh but warn
    console.error('Warning: existing config was invalid, preserving as backup');
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
