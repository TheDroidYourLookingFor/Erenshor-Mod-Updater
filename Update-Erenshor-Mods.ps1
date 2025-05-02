<#
    Erenshor Mod Auto-Updater
    --------------------------
    This script automatically downloads or updates Erenshor BepInEx mods from GitHub and other sources.

    HOW TO USE:
    1. Edit the "$PluginDir" variable below to point to your Erenshor BepInEx plugins directory.
       Example:
           $PluginDir = "D:\Games\Steam\steamapps\common\Erenshor\BepInEx\plugins"

    2. Modify the "$ModUrls" array to include the mods you want.
       Each mod entry is a hashtable with:
         - type:
             "release" = GitHub repo with Releases (gets latest automatically)
             "raw"     = Direct link to a .dll file (hosted on raw.githubusercontent.com)
             "direct"  = Direct link to a .zip or .dll file (downloads exactly what's linked)

       Examples:
         @{ type = "release"; url = "https://github.com/username/repo/releases" }
         @{ type = "raw";     url = "https://raw.githubusercontent.com/user/repo/main/folder/mod.dll" }
         @{ type = "direct";  url = "https://github.com/user/repo/releases/download/version/file.zip" }

    3. Run the script by right-clicking and selecting "Run with PowerShell"
       or execute from a PowerShell terminal.

    NOTES:
    - Script remembers versions using 'mod_versions.json' stored in the plugins folder.
    - If a mod is already up-to-date (by version or filename), it is skipped.
    - .zip files are extracted into a folder named after the GitHub repo (e.g. User-RepoName)

    Safe to rerun as often as you like!
#>

$PluginDir = "D:\Games\Steam\steamapps\common\Erenshor\BepInEx\plugins"
$VersionFile = "$PluginDir\mod_versions.json"

# Add optional GitHub API key if available
$GitHubApiKey = ""  # Example: "ghp_YourGitHubTokenHere"
$Headers = @{ "User-Agent" = "PowerShellScript" }
if ($GitHubApiKey) {
    $Headers["Authorization"] = "token $GitHubApiKey"
}

$ModUrls = @(
    @{ type = "release"; url = "https://github.com/drizzlx/erenshor-leveldisplay/releases" },
    @{ type = "release"; url = "https://github.com/iExpulsion/Expulsion.Erenshor.SpellSkillCleanupFix/releases" },
    @{ type = "release"; url = "https://github.com/iExpulsion/Expulsion.Erenshor.Wellstone/releases" },
    @{ type = "release"; url = "https://github.com/drizzlx/erenshor-minimap/releases" },
    @{ type = "release"; url = "https://github.com/drizzlx/Erenshor-QuestHelper/releases" },
    @{ type = "release"; url = "https://github.com/iExpulsion/Expulsion.Erenshor.ZoneInfo/releases" },
    @{ type = "release"; url = "https://github.com/BepInEx/BepInEx.ConfigurationManager/releases" },
    @{ type = "release"; url = "https://github.com/Brad522/Erenshor-CompareEquipment/releases" },
    @{ type = "release"; url = "https://github.com/Brad522/Erenshor-EverquestLevelup/releases" },
    
    # Optional raw plugin example
    @{ type = "raw"; url = "https://raw.githubusercontent.com/Brumdail/ErenshorQoL/main/ErenshorQoL/ErenshorQoL.dll" },
    @{ type = "raw"; url = "https://github.com/Brumdail/ErenshorREL/blob/main/ErenshorREL/ErenshorREL.dll" },

    # Optional direct plugin example
    @{ type = "direct"; url = "https://github.com/sinai-dev/UnityExplorer/releases/download/4.9.0/UnityExplorer.BepInEx5.Mono.zip" }
)


# Load version tracking
if (Test-Path $VersionFile) {
    $versionData = Get-Content $VersionFile | ConvertFrom-Json
}
else {
    $versionData = @{}
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($entry in $ModUrls) {
    $url = $entry.url
    $type = $entry.type

    if ($type -eq "release" -and $url -match "github\.com/([^/]+)/([^/]+)/releases") {
        $user = $matches[1]
        $repo = $matches[2]

        $folderName = ($user + "-" + $repo).Replace(".", "-")

        $apiUrl = "https://api.github.com/repos/$user/$repo/releases/latest"
        
        try {
            $release = Invoke-RestMethod -Uri $apiUrl -Headers $Headers
        }
        catch {
            Write-Warning "Failed to fetch release info for $repo"
            continue
        }

        $latestTag = $release.tag_name
        $currentTag = $versionData.$folderName

        if ($currentTag -eq $latestTag) {
            Write-Host "$folderName is already up to date ($latestTag). Skipping.`n"
            continue
        }

        $asset = $release.assets | Where-Object { $_.name -match "\.(zip|dll)$" } | Select-Object -First 1
        if (-not $asset) {
            Write-Warning "No downloadable asset found for $folderName"
            continue
        }

        $downloadUrl = $asset.browser_download_url
        $downloadName = $asset.name
        $tempFile = "$env:TEMP\$downloadName"

        Write-Host "Downloading $folderName update ($latestTag)..."
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -Headers $Headers

        $targetDir = Join-Path $PluginDir $folderName

        if ($downloadName -like "*.zip") {
            # Create a folder for the mod
            $targetDir = Join-Path $PluginDir $folderName
            if (Test-Path $targetDir) { Remove-Item $targetDir -Recurse -Force }
            New-Item -ItemType Directory -Path $targetDir | Out-Null
    
            # Extract to a temporary folder first
            $tempDir = Join-Path $PluginDir "temp"
            if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
            New-Item -ItemType Directory -Path $tempDir | Out-Null
    
            # Extract to the temporary directory
            [System.IO.Compression.ZipFile]::ExtractToDirectory($tempFile, $tempDir)
    
            # Get all files from the extracted folder, including nested files
            $allFiles = Get-ChildItem -Path $tempDir -Recurse

            # Move all the files (DLLs and any other necessary files) directly to the target directory
            foreach ($item in $allFiles) {
                # Check if it's a file (not a directory)
                if (-not $item.PSIsContainer) {
                    # Move the file to the target directory
                    Move-Item -Path $item.FullName -Destination $targetDir
                }
            }

            # Clean up the temporary directory
            Remove-Item -Path $tempDir -Recurse -Force
        }
        elseif ($downloadName -like "*.dll") {
            Copy-Item $tempFile -Destination (Join-Path $PluginDir $downloadName) -Force
        }

        Remove-Item $tempFile -Force

        $versionData.$folderName = $latestTag
        Write-Host "$folderName updated to $latestTag.`n"
    }
    elseif ($type -eq "raw" -and $url -match "githubusercontent\.com/([^/]+)/([^/]+)/main/.*/([^/]+\.dll)") {
        $user = $matches[1]
        $repo = $matches[2]
        $dllName = $matches[3]

        $folderName = ($user + "-" + $repo).Replace(".", "-")
        $targetPath = Join-Path $PluginDir $dllName

        Write-Host "Downloading raw DLL for $folderName..."

        try {
            Invoke-WebRequest -Uri $url -OutFile $targetPath -Headers $Headers -ErrorAction Stop
            Write-Host "Downloaded $dllName to plugins folder.`n"

            $versionData.$folderName = "manual"
        }
        catch {
            Write-Warning "Failed to download raw DLL from $url"
        }
    }
    elseif ($type -eq "direct") {
        $uri = [System.Uri]$url
        $fileName = [System.IO.Path]::GetFileName($uri.AbsolutePath)
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
        $folderName = $baseName.Replace(".", "-")
        $tempFile = "$env:TEMP\$fileName"
        $targetDir = Join-Path $PluginDir $folderName

        if ($versionData.$folderName -eq $fileName) {
            Write-Host "$folderName is already up to date (filename match). Skipping.`n"
            continue
        }

        Write-Host "Downloading direct file: $fileName..."
        try {
            Invoke-WebRequest -Uri $url -OutFile $tempFile -Headers $Headers -ErrorAction Stop

            if ($fileName -like "*.zip") {
                # Clean destination
                if (Test-Path $targetDir) { Remove-Item $targetDir -Recurse -Force }
                New-Item -ItemType Directory -Path $targetDir | Out-Null

                # Extract to temporary directory
                $tempDir = Join-Path $PluginDir "temp"
                if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
                New-Item -ItemType Directory -Path $tempDir | Out-Null

                [System.IO.Compression.ZipFile]::ExtractToDirectory($tempFile, $tempDir)

                # Move all extracted files to final plugin folder
                $allFiles = Get-ChildItem -Path $tempDir -Recurse
                foreach ($item in $allFiles) {
                    if (-not $item.PSIsContainer) {
                        Move-Item -Path $item.FullName -Destination $targetDir
                    }
                }

                Remove-Item -Path $tempDir -Recurse -Force
            }
            elseif ($fileName -like "*.dll") {
                Copy-Item $tempFile -Destination (Join-Path $PluginDir $fileName) -Force
            }

            Remove-Item $tempFile -Force
            $versionData.$folderName = $fileName
            Write-Host "$folderName updated via direct download.`n"
        }
        catch {
            Write-Warning "Failed to download direct file: $url"
        }
    }
}

# Save version tracking
$versionData | ConvertTo-Json | Set-Content $VersionFile
