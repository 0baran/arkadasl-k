param([string]$type = "patch")

$pubspec = Resolve-Path "$PSScriptRoot\..\pubspec.yaml"
$versionFile = Resolve-Path "$PSScriptRoot\..\version.json"

$yaml = Get-Content $pubspec -Raw
$m = [regex]::Match($yaml, 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)')
$major, $minor, $patch, $build = [int]$m.Groups[1].Value, [int]$m.Groups[2].Value, [int]$m.Groups[3].Value, [int]$m.Groups[4].Value

switch ($type) {
  "major" { $major++; $minor = 0; $patch = 0 }
  "minor" { $minor++; $patch = 0 }
  default { $patch++ }
}
$build++
$newVer = "$major.$minor.$patch"

$yaml = $yaml -replace 'version:\s*\d+\.\d+\.\d+\+\d+', "version: $newVer+$build"
Set-Content $pubspec -Value $yaml -NoNewline

$json = Get-Content $versionFile -Raw | ConvertFrom-Json
$json.version = $newVer
$json.build = $build
$json | ConvertTo-Json | Set-Content $versionFile

Write-Host "v$newVer (build $build)"
