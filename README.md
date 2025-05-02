# Erenshor Mod Auto-Updater

This PowerShell script automatically downloads and updates mods for the [Erenshor](https://store.steampowered.com/app/2710660/Erenshor/) game using GitHub Releases, direct URLs, or raw file links.

No dependencies. No bloat. Just run it, and your BepInEx plugins stay updated.

---

## ✨ Features

- ✅ Automatically fetches the latest mod releases from GitHub
- ✅ Supports `.zip` and `.dll` formats
- ✅ Direct file support for URLs to GitHub or elsewhere
- ✅ Version tracking with `mod_versions.json`
- ✅ Safe to re-run as often as you like
- ✅ Designed to be minimal, transparent, and configurable

---

## 🚀 How to Use

1. **Download the script**  
   Clone this repo or download the `.ps1` file.

2. **Edit the script settings**  
   Open the script in a text editor and configure these variables near the top:

   ```powershell
   $PluginDir = "D:\Games\Steam\steamapps\common\Erenshor\BepInEx\plugins"
   $ModUrls = @(
       @{ type = "release"; url = "https://github.com/username/repo/releases" },
       @{ type = "raw";     url = "https://raw.githubusercontent.com/user/repo/main/mod.dll" },
       @{ type = "direct";  url = "https://github.com/user/repo/releases/download/version/file.zip" }
   )
3. Run the script

    Right-click the file and choose Run with PowerShell

    Or run it from PowerShell manually:

        .\ErenshorModUpdater.ps1

🧠 Supported Mod Types

Type	Description
release	GitHub repository with Releases. Automatically fetches the latest release.
raw	Direct .dll link from GitHub or elsewhere. Used as-is.
direct	Direct .zip or .dll link. Treated as a static versioned file.
Each downloaded mod is stored in a subfolder named after the repo or file (e.g., username-repo).

📁 Version Tracking

A mod_versions.json file is stored in your plugins folder to track installed versions by mod source. This prevents unnecessary re-downloads and lets the script skip mods that are already up-to-date.

🔐 GitHub API Key (Optional)

To avoid rate limits when using release type mods, you may add your GitHub API token inside the script:

$GitHubApiKey = "ghp_YourGitHubTokenHere"

Leave it blank ("") if you don’t need or want it.
❓ Example Mod List

$ModUrls = @(
    @{ type = "release"; url = "https://github.com/drizzlx/erenshor-leveldisplay/releases" },
    @{ type = "raw";     url = "https://raw.githubusercontent.com/Brumdail/ErenshorQoL/main/ErenshorQoL/ErenshorQoL.dll" },
    @{ type = "direct";  url = "https://github.com/sinai-dev/UnityExplorer/releases/download/4.9.0/UnityExplorer.BepInEx5.Mono.zip" }
)

🧼 Cleanup

    Temporary download files are deleted after use
    .zip files are extracted and cleaned up automatically
    No leftovers, no mess

📜 License

This script is licensed under the GNU General Public License v3.0 (GPL-3.0).
You are free to use, modify, and redistribute this script, but derivative works must also be licensed under GPLv3.

❤️ Credits

Maintained by the community. Script improvements and mod suggestions welcome via pull request or issue.
