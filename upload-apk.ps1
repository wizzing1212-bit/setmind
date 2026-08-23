param([string]$Apk)
$ErrorActionPreference = 'Stop'
$site = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $site

function Say($m){ Write-Host "  $m" }

# --- find the apk ---
if (-not $Apk -or -not (Test-Path $Apk)) {
  $searchIn = @(
    'C:\CURRENT FOCUS PROJECTS\didiwin-dev\releases',
    'C:\CURRENT FOCUS PROJECTS\didiwin-dev',
    "$env:USERPROFILE\Downloads"
  )
  $found = @()
  foreach ($d in $searchIn) {
    if (Test-Path $d) { $found += Get-ChildItem -Path $d -Filter *.apk -File -ErrorAction SilentlyContinue }
  }
  if (-not $found) { Say "No .apk found. Drag one onto UPLOAD-APK.bat instead."; exit 1 }
  $pick = $found | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  $Apk = $pick.FullName
  Say "Using newest APK: $($pick.Name)"
}

$file    = Get-Item $Apk
$base    = [IO.Path]::GetFileNameWithoutExtension($file.Name)
$short   = ($base -split '-')[0]
$display = ($short -creplace '(?<!^)([A-Z])', ' $1')
$version = ''
if ($base -match '(v[\d][\w\.\-]*)$') { $version = $Matches[1] }

Say "App:     $display"
Say "Version: $(if($version){$version}else{'(none in filename)'})"
Say "Size:    $([math]::Round($file.Length/1MB,1)) MB"
Say ""

# --- staged copy with a stable name so the link never changes ---
$stable = Join-Path $env:TEMP "$short.apk"
Copy-Item $file.FullName $stable -Force

$repo = (gh repo view --json nameWithOwner --jq .nameWithOwner) 2>$null
if (-not $repo) { Say "Run PUBLISH-WEBSITE.bat first."; exit 1 }

# --- one permanent release that holds every download ---
gh release view downloads --repo $repo *> $null
if ($LASTEXITCODE -ne 0) {
  Say "Creating the downloads shelf..."
  gh release create downloads --repo $repo --title "Downloads" --notes "Direct downloads for setmind.net" *> $null
}

$label = if ($version) { "$display - $version" } else { $display }
Say "Uploading... (a big file takes a few minutes)"
gh release upload downloads "$stable#$label" --repo $repo --clobber
if ($LASTEXITCODE -ne 0) { Say "Upload failed."; exit 1 }
Remove-Item $stable -Force -ErrorAction SilentlyContinue

# --- rebuild downloads.json from what is actually up there ---
Say "Refreshing the download list..."
$assets = gh api "repos/$repo/releases/tags/downloads" --jq '.assets' | ConvertFrom-Json
$list = @()
foreach ($a in $assets) {
  if ($a.name -notlike '*.apk') { continue }
  $lbl = if ($a.label) { $a.label } else { [IO.Path]::GetFileNameWithoutExtension($a.name) }
  $nm  = $lbl; $ver = ''
  if ($lbl -match '^(.*?) - (.*)$') { $nm = $Matches[1]; $ver = $Matches[2] }
  $list += [pscustomobject]@{
    name     = $nm
    version  = $ver
    platform = 'Android'
    size     = "$([math]::Round($a.size/1MB,1)) MB"
    date     = ([datetime]$a.updated_at).ToString('yyyy-MM-dd')
    url      = $a.browser_download_url
  }
}
$json = if ($list.Count -eq 1) { "[" + ($list | ConvertTo-Json -Depth 4) + "]" } else { $list | ConvertTo-Json -Depth 4 }
Set-Content -Path (Join-Path $site 'downloads.json') -Value $json -Encoding UTF8

# --- push ---
git add downloads.json  *> $null
git -c user.email="wizzing1212@gmail.com" -c user.name="SET MIND" commit -m "download: $label" *> $null
git push *> $null

Say ""
Say "=================================================="
Say "  Live on the site in about a minute."
Say "  Direct link:"
Say "  https://github.com/$repo/releases/download/downloads/$short.apk"
Say "=================================================="
