param(
    [string]$Flutter = "flutter"
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$propertiesFile = Join-Path $projectRoot "android\key.properties"

if (-not (Test-Path -LiteralPath $propertiesFile)) {
    throw "Missing android\key.properties. Copy android\key.properties.example and configure the upload keystore first."
}

Push-Location $projectRoot
try {
    & $Flutter build appbundle --release
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter failed to build the Android App Bundle."
    }

    $bundle = Join-Path $projectRoot "build\app\outputs\bundle\release\app-release.aab"
    if (-not (Test-Path -LiteralPath $bundle)) {
        throw "The expected App Bundle was not created: $bundle"
    }

    $hash = Get-FileHash -Algorithm SHA256 -LiteralPath $bundle
    Write-Output "Android release bundle: $bundle"
    Write-Output "SHA256: $($hash.Hash)"
}
finally {
    Pop-Location
}
