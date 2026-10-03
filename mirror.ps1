$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$root       = (Get-Location).Path
$site       = 'https://servicoldperu.com/'
$ua         = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0 Safari/537.36'
$map        = @{}   # absolute URL (normalized) -> local relative path (forward slashes)
$downloaded = @{}   # absolute URL -> local full path (or $null on failure)
$htmlRepl   = [System.Collections.Generic.List[object]]::new()
$cssQueue   = [System.Collections.Generic.Queue[object]]::new()
$cssSeen    = @{}

function Write-Log($msg) { Write-Host $msg }

function Get-AbsoluteUrl([string]$url, [string]$base) {
    if ([string]::IsNullOrWhiteSpace($url)) { return $null }
    $u = $url.Trim()
    if ($u -match '^(data:|mailto:|tel:|javascript:|#)') { return $null }
    $u = $u -replace '&#0?38;', '&' -replace '&amp;', '&'
    if ($u.StartsWith('//')) { $u = 'https:' + $u }
    try {
        if ($u -match '^https?://') { $abs = New-Object System.Uri($u) }
        else { $abs = New-Object System.Uri((New-Object System.Uri($base)), $u) }
    } catch { return $null }
    return $abs.AbsoluteUri
}

function Get-LocalRel([string]$absUrl) {
    if ($map.ContainsKey($absUrl)) { return $map[$absUrl] }
    $uri  = New-Object System.Uri($absUrl)
    $hostName = $uri.Host
    $path = $uri.AbsolutePath.TrimStart('/')
    if ([string]::IsNullOrEmpty($path)) { $path = 'index.html' }
    if ($uri.Query -ne '') {
        $ext = [System.IO.Path]::GetExtension($path)
        if ([string]::IsNullOrEmpty($ext)) {
            $suffix = ($uri.Query.TrimStart('?') -replace '[^A-Za-z0-9]', '_')
            if ($suffix.Length -gt 80) { $suffix = $suffix.Substring(0, 80) }
            $path = $path + '_' + $suffix
        }
    }
    $path = $path -replace '[<>:"|?*]', '_'
    $rel = 'assets/' + $hostName + '/' + $path
    $map[$absUrl] = $rel
    return $rel
}

function Test-IsAsset([string]$absUrl) {
    try { $uri = New-Object System.Uri($absUrl) } catch { return $false }
    $p = $uri.AbsolutePath.ToLower()
    $h = $uri.Host.ToLower()
    if ($h -match 'fonts\.(googleapis|gstatic)\.com') { return $true }
    if ($p -match '\.(css|js|mjs|jpe?g|png|gif|webp|svg|ico|woff2?|ttf|eot|otf|mp4|webm)$') { return $true }
    if ($h -eq 'servicoldperu.com' -and ($p -match '^/wp-content/' -or $p -match '^/wp-includes/' -or $p -match '^/wp-admin/')) { return $true }
    return $false
}

function Save-Remote([string]$absUrl) {
    if ($downloaded.ContainsKey($absUrl)) { return $downloaded[$absUrl] }
    $rel  = Get-LocalRel $absUrl
    $full = Join-Path $root ($rel -replace '/', '\')
    $dir  = Split-Path $full -Parent
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    try {
        Invoke-WebRequest -Uri $absUrl -OutFile $full -UseBasicParsing -Headers @{ 'User-Agent' = $ua } -TimeoutSec 90
        $downloaded[$absUrl] = $full
        Write-Log ("  OK   " + $rel)
        return $full
    } catch {
        $downloaded[$absUrl] = $null
        Write-Log ("  FAIL " + $absUrl + "  -> " + $_.Exception.Message)
        return $null
    }
}

function Add-Queue([string]$absUrl) {
    if ($absUrl -and -not $cssSeen.ContainsKey($absUrl)) {
        $cssSeen[$absUrl] = $true
        $cssQueue.Enqueue([pscustomobject]@{ Url = $absUrl; Full = $null })
    }
}

# ---------------- 1. Download page + collect HTML assets ----------------
Write-Log "Descargando HTML..."
$resp = Invoke-WebRequest -Uri $site -UseBasicParsing -Headers @{ 'User-Agent' = $ua } -TimeoutSec 90
$html = $resp.Content
$decoded = $html
[System.IO.File]::WriteAllText((Join-Path $root 'source-original.html'), $html, [System.Text.UTF8Encoding]::new($false))

$htmlTokens = [System.Collections.Generic.List[string]]::new()
# href="..."
foreach ($m in [regex]::Matches($html, 'href\s*=\s*["'']([^"'']+)["'']'))        { $htmlTokens.Add($m.Groups[1].Value) }
# src="..."
foreach ($m in [regex]::Matches($html, 'src\s*=\s*["'']([^"'']+)["'']'))         { $htmlTokens.Add($m.Groups[1].Value) }
# srcset="..."
foreach ($m in [regex]::Matches($html, 'srcset\s*=\s*["'']([^"'']+)["'']'))      {
    foreach ($part in $m.Groups[1].Value.Split(',')) {
        $u = ($part.Trim() -split '\s+')[0]
        if ($u) { $htmlTokens.Add($u) }
    }
}
# inline url(...) inside style attributes / blocks
foreach ($m in [regex]::Matches($html, 'url\(\s*[''"]?([^''")]+)[''"]?\s*\)'))     { $htmlTokens.Add($m.Groups[1].Value.Trim()) }

Write-Log ("Tokens encontrados en HTML: " + $htmlTokens.Count)
foreach ($raw in ($htmlTokens | Select-Object -Unique)) {
    $abs = Get-AbsoluteUrl $raw $site
    if (-not $abs) { continue }
    if (-not (Test-IsAsset $abs)) { continue }
    $full = Save-Remote $abs
    if ($full) {
        $rel = $map[$abs]
        if ($raw -ne $rel) { $htmlRepl.Add([pscustomobject]@{ Raw = $raw; Rel = $rel }) }
        if ($abs -match '\.css' -or $abs -match 'fonts\.googleapis\.com') { Add-Queue $abs }
    }
}

# ---------------- 2. Process CSS recursively ----------------
Write-Log "Procesando CSS..."
while ($cssQueue.Count -gt 0) {
    $item = $cssQueue.Dequeue()
    $absCss = $item.Url
    $full = $downloaded[$absCss]
    if (-not $full -or -not (Test-Path -LiteralPath $full)) { $full = Save-Remote $absCss }
    if (-not $full) { continue }
    $css = [System.IO.File]::ReadAllText($full)
    $refs = [System.Collections.Generic.List[string]]::new()
    foreach ($m in [regex]::Matches($css, 'url\(\s*[''"]?([^''")]+)[''"]?\s*\)')) { $refs.Add($m.Groups[1].Value.Trim()) }
    foreach ($m in [regex]::Matches($css, '@import\s+(?:url\()?\s*[''"]?([^''")]+)[''"]?\s*\)?')) { $refs.Add($m.Groups[1].Value.Trim()) }
    foreach ($raw in $refs) {
        $u = $raw -replace '&#0?38;', '&' -replace '&amp;', '&'
        if ($u -match '^(data:|#)') { continue }
        $abs = Get-AbsoluteUrl $u $absCss
        if (-not $abs) { continue }
        if (-not (Test-IsAsset $abs)) { continue }
        $child = Save-Remote $abs
        if ($abs -match 'fonts\.googleapis\.com' -or $abs -match '\.css($|\?)') { Add-Queue $abs }
    }
}

# ---------------- 3. Rewrite CSS contents (relative paths) ----------------
function Get-RelPath([string]$fromFull, [string]$toFull) {
    $fromDir = Split-Path $fromFull -Parent
    if (-not $fromDir.EndsWith('\')) { $fromDir += '\' }
    $fromUri = New-Object System.Uri($fromDir)
    $toUri   = New-Object System.Uri($toFull)
    $rel = $fromUri.MakeRelativeUri($toUri).ToString()
    $rel = [System.Uri]::UnescapeDataString($rel)
    return ($rel -replace '\\', '/')
}

Write-Log "Reescribiendo CSS..."
foreach ($absCss in $cssSeen.Keys) {
    $full = $downloaded[$absCss]
    if (-not $full -or -not (Test-Path -LiteralPath $full)) { continue }
    $css = [System.IO.File]::ReadAllText($full)
    $changed = $false
    foreach ($abs in $map.Keys) {
        if ($css -notmatch [regex]::Escape($abs)) { continue }
        $targetFull = Join-Path $root ($map[$abs] -replace '/', '\')
        $rel = Get-RelPath $full $targetFull
        $css = $css.Replace($abs, $rel)
        $changed = $true
    }
    if ($changed) { [System.IO.File]::WriteAllText($full, $css, [System.Text.UTF8Encoding]::new($false)) }
}

# ---------------- 4. Rewrite HTML ----------------
Write-Log "Reescribiendo HTML..."
# Replace longest raw strings first to avoid partial collisions
foreach ($rep in ($htmlRepl | Sort-Object { $_.Raw.Length } -Descending)) {
    $decoded = $decoded.Replace($rep.Raw, $rep.Rel)
}
# Also replace any remaining absolute asset URLs found in the map
foreach ($abs in $map.Keys) {
    if ($decoded -notmatch [regex]::Escape($abs)) { continue }
    $decoded = $decoded.Replace($abs, $map[$abs])
}
[System.IO.File]::WriteAllText((Join-Path $root 'index.html'), $decoded, [System.Text.UTF8Encoding]::new($false))

Write-Log ("LISTO. Assets: " + $downloaded.Count + " | Fallos: " + (($downloaded.Values | Where-Object { $_ -eq $null }).Count))
