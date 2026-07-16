param(
    [string]$Flutter = "flutter",
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$releaseDirectory = Join-Path $projectRoot "build\windows\x64\runner\Release"
$distributionDirectory = Join-Path $projectRoot "dist"
$packageName = "Dnevnik-$Version-windows-x64"
$stagingDirectory = Join-Path $distributionDirectory $packageName
$archivePath = Join-Path $distributionDirectory "$packageName.zip"

Push-Location $projectRoot
try {
    & $Flutter build windows --release
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter failed to build the Windows release."
    }
    if (-not (Test-Path -LiteralPath $releaseDirectory)) {
        throw "The expected Windows release directory was not created: $releaseDirectory"
    }

    New-Item -ItemType Directory -Force -Path $distributionDirectory | Out-Null
    $resolvedDistribution = (Resolve-Path -LiteralPath $distributionDirectory).Path
    $fullStaging = [System.IO.Path]::GetFullPath($stagingDirectory)
    if (-not $fullStaging.StartsWith($resolvedDistribution, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to prepare a package outside the distribution directory."
    }

    if (Test-Path -LiteralPath $stagingDirectory) {
        Remove-Item -Recurse -Force -LiteralPath $stagingDirectory
    }
    if (Test-Path -LiteralPath $archivePath) {
        Remove-Item -Force -LiteralPath $archivePath
    }

    Copy-Item -Recurse -LiteralPath $releaseDirectory -Destination $stagingDirectory
    Compress-Archive -Path (Join-Path $stagingDirectory "*") -DestinationPath $archivePath

    $hash = Get-FileHash -Algorithm SHA256 -LiteralPath $archivePath
    Write-Output "Windows release package: $archivePath"
    Write-Output "SHA256: $($hash.Hash)"
}
finally {
    Pop-Location
}
