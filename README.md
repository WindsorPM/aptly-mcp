# Aptly MCP Server for Claude Desktop

Connects Claude Desktop to the Windsor Work Orders board in Aptly. Claude can read cards, create/update work orders, add comments, and pull the field schema — all through natural conversation.

## Setup

**Prerequisites:** [Node.js](https://nodejs.org/) v18+ (pick LTS). To check, open Command Prompt and type `node -v`.

**Install:** Download the installer from the pinned message in the Windsor Team channel and double-click it. It handles everything automatically. When it's done, restart Claude Desktop.

## What Claude Can Do

| Tool | What it does |
|------|-------------|
| **get_schema** | Pulls field definitions (keys, labels, types) — Claude calls this first automatically |
| **list_cards** | Lists work orders with pagination and date filters |
| **get_card** | Gets a single card by ID |
| **create_or_update_card** | Creates new work orders or updates existing ones |
| **add_comment** | Adds a comment to a card |

## Troubleshooting

**Claude doesn't show Aptly tools:**
- Make sure you restarted Claude Desktop after setup
- Open Command Prompt and run: `node "%USERPROFILE%\.aptly-mcp\server.mjs"` — if it says "APTLY_API_KEY environment variable is required", the server code is working; the env var just isn't set outside Claude Desktop

**API errors (401, 403):**
- Your API key may be expired or incorrect. Re-download and re-run the installer from the Teams channel.

**"Cannot find module" errors:**
- Open Command Prompt, run `cd %USERPROFILE%\.aptly-mcp` then `npm install`

## For Admins

See [TEAMS-MESSAGE.md](TEAMS-MESSAGE.md) for instructions on encoding the API key and sharing the installer with the team.
