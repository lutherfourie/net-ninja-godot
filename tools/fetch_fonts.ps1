<#
    Net Ninja — font fetcher (Windows / PowerShell)

    Pulls the two OFL families the type system depends on into assets/fonts/.
    They are deliberately not committed: fonts are third-party binaries with
    their own licence, and the project runs (off-brand) without them.

        Nunito Sans  — variable, weights 600 + 800 derived at runtime
        Space Mono   — Regular 400, tech data only

    Source is the google/fonts repo rather than the CSS API, because the CSS API
    now serves WOFF2 and Godot cannot load WOFF2. src/ui/fonts.gd builds
    SemiBold/ExtraBold from the variable file via FontVariation.

    Usage:  pwsh -File tools/fetch_fonts.ps1
#>

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$dest = Join-Path $root 'assets/fonts'
New-Item -ItemType Directory -Force -Path $dest | Out-Null

$base = 'https://raw.githubusercontent.com/google/fonts/main/ofl'
$targets = @(
    @{ Url = "$base/nunitosans/NunitoSans%5BYTLC%2Copsz%2Cwdth%2Cwght%5D.ttf"; Name = 'NunitoSans-Variable.ttf' },
    @{ Url = "$base/spacemono/SpaceMono-Regular.ttf";                          Name = 'SpaceMono-Regular.ttf' }
)

foreach ($t in $targets) {
    $out = Join-Path $dest $t.Name
    if (Test-Path $out) {
        Write-Host "skip  $($t.Name) (already present)"
        continue
    }
    try {
        Invoke-WebRequest -Uri $t.Url -OutFile $out -UseBasicParsing
        Write-Host "ok    $($t.Name)"
    }
    catch {
        Write-Warning "failed $($t.Name): $($_.Exception.Message)"
    }
}

Write-Host ''
Write-Host 'Done. Open the project in Godot once so the fonts are imported.'
