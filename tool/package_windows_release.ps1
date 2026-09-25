param(
    [string]$Flutter = "flutter",
    [string]$Version,
    [string]$NuGetUrl = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe",
    [string]$InnoSetupCompiler
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$pubspecPath = Join-Path $projectRoot "pubspec.yaml"
if ([string]::IsNullOrWhiteSpace($Version)) {
    $versionMatch = Select-String -LiteralPath $pubspecPath `
        -Pattern '^\s*version:\s*([0-9]+\.[0-9]+\.[0-9]+)(?:\+\S+)?\s*$' |
        Select-Object -First 1
    if (-not $versionMatch) {
        throw "Could not read the application version from pubspec.yaml."
    }
    $Version = $versionMatch.Matches[0].Groups[1].Value
}
$buildToolsDirectory = Join-Path $projectRoot "build\tools"
$releaseDirectory = Join-Path $projectRoot "build\windows\x64\runner\Release"
$distributionDirectory = Join-Path $projectRoot "dist"
$packageName = "Literia-$Version-windows-x64"
$stagingDirectory = Join-Path $distributionDirectory $packageName
$archivePath = Join-Path $distributionDirectory "$packageName.zip"
$installerScript = Join-Path $projectRoot "windows\installer\literia.iss"
$installerName = "$packageName-setup"
$installerPath = Join-Path $distributionDirectory "$installerName.exe"

function Find-InnoSetupCompiler {
    if (-not [string]::IsNullOrWhiteSpace($InnoSetupCompiler)) {
        return $InnoSetupCompiler
    }
    $command = Get-Command "ISCC.exe" -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA "Programs\Inno Setup 6\ISCC.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6\ISCC.exe"),
        (Join-Path $env:ProgramFiles "Inno Setup 6\ISCC.exe")
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }
    throw "Inno Setup 6 is required for the installer: https://jrsoftware.org/isdl.php"
}

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
    if (Test-Path -LiteralPath $installerPath) {
        Remove-Item -Force -LiteralPath $installerPath
    }

    Copy-Item -Recurse -LiteralPath $releaseDirectory -Destination $stagingDirectory
    Compress-Archive -Path (Join-Path $stagingDirectory "*") -DestinationPath $archivePath

    $compiler = Find-InnoSetupCompiler
    & $compiler /Q "/DAppVersion=$Version" "/DBuildDir=$releaseDirectory" `
        "/DOutputDir=$resolvedDistribution" "/DOutputBaseFilename=$installerName" `
        $installerScript
    if ($LASTEXITCODE -ne 0) {
        throw "Inno Setup failed to compile the Windows installer."
    }

    foreach ($artifact in @($archivePath, $installerPath)) {
        $hash = Get-FileHash -Algorithm SHA256 -LiteralPath $artifact
        Write-Output "Windows release file: $artifact"
        Write-Output "SHA256: $($hash.Hash)"
    }
}
finally {
    Pop-Location
}
