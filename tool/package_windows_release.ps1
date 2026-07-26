param(
    [string]$Flutter = "flutter",
    [string]$Version = "1.0.0",
    [string]$NuGetUrl = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$buildToolsDirectory = Join-Path $projectRoot "build\tools"
$releaseDirectory = Join-Path $projectRoot "build\windows\x64\runner\Release"
$distributionDirectory = Join-Path $projectRoot "dist"
$packageName = "Literia-$Version-windows-x64"
$stagingDirectory = Join-Path $distributionDirectory $packageName
$archivePath = Join-Path $distributionDirectory "$packageName.zip"

function Initialize-NuGet {
    if (Get-Command "nuget" -ErrorAction SilentlyContinue) {
        return
    }

    New-Item -ItemType Directory -Force -Path $buildToolsDirectory | Out-Null
    $nugetPath = Join-Path $buildToolsDirectory "nuget.exe"
    if (-not (Test-Path -LiteralPath $nugetPath)) {
        Write-Output "Downloading the Microsoft NuGet CLI required by flutter_tts..."
        Invoke-WebRequest -Uri $NuGetUrl -OutFile $nugetPath
    }

    $signature = Get-AuthenticodeSignature -LiteralPath $nugetPath
    if ($signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid) {
        throw "The downloaded NuGet CLI does not have a valid Authenticode signature."
    }
    $env:Path = "$buildToolsDirectory;$env:Path"
}

Push-Location $projectRoot
try {
    Initialize-NuGet
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
