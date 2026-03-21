# Teams Setup Guide (for Admins)

## One-time admin steps

### 1. Encode your API key

Open PowerShell and run:
```powershell
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("your-actual-api-key-here"))
```

Copy the output.

### 2. Bake it into the installer

Open `install-aptly.bat` in a text editor. Find this line near the top:
```
set "B64KEY=REPLACE_WITH_BASE64_ENCODED_KEY"
```

Replace `REPLACE_WITH_BASE64_ENCODED_KEY` with your base64 string. Save the file.

**Do NOT commit this file to GitHub.** The .bat with the key baked in lives only in Teams.

### 3. Share in Teams

Upload `install-aptly.bat` to the Windsor Team channel's Files tab (or attach it to a pinned message). The message should say something like:

> **Set up Aptly for Claude Desktop**
> 1. Make sure you have Node.js installed ([download here](https://nodejs.org/) — pick LTS)
> 2. Download and double-click the file below
> 3. Wait for it to finish, then restart Claude Desktop
> 4. Ask Claude: "Show me the open work orders"

That's it. The file is behind Teams/M365 auth, so only your team can access it.

## To rotate the API key

1. Generate a new key in Aptly (Work Orders > Card Sources > API > + Create New Key)
2. Deactivate the old key
3. Base64-encode the new key (step 1 above)
4. Update the .bat file in Teams (step 2-3 above)
5. Team members re-download and re-run the .bat to update their local install
