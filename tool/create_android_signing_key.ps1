param(
    [Parameter(Mandatory = $true)]
    [string]$EncryptionKey,
    [string]$Alias = "literia-upload",
    [string]$Keystore = "android\literia-upload.keystore",
    [string]$Properties = "android\key.properties",
    [string]$Pepk = "pepk.jar",
    [string]$Output = "pepk_out.zip",
    [string]$CertificateOutput = "upload_certificate.pem"
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$keystorePath = Join-Path $projectRoot $Keystore
$propertiesPath = Join-Path $projectRoot $Properties
$pepkPath = Join-Path $projectRoot $Pepk
$outputPath = Join-Path $projectRoot $Output
$certificateOutputPath = Join-Path $projectRoot $CertificateOutput

foreach ($path in @(
    $keystorePath,
    $propertiesPath,
    $outputPath,
    $certificateOutputPath
)) {
    if (Test-Path -LiteralPath $path) {
        throw "Refusing to overwrite an existing signing artifact: $path"
    }
}
if (-not (Test-Path -LiteralPath $pepkPath)) {
    throw "PEPK tool was not found: $pepkPath"
}
if ($EncryptionKey -notmatch '^[0-9a-fA-F]{136}$') {
    throw "The PEPK encryption key must contain exactly 136 hexadecimal characters."
}

$randomBytes = [byte[]]::new(32)
[System.Security.Cryptography.RandomNumberGenerator]::Fill($randomBytes)
$password = [Convert]::ToBase64String($randomBytes).
    TrimEnd("=").
    Replace("+", "A").
    Replace("/", "B")

try {
    $keytoolArguments = @(
        "-genkeypair", "-v",
        "-keystore", $keystorePath,
        "-storetype", "JKS",
        "-storepass", $password,
        "-keypass", $password,
        "-alias", $Alias,
        "-keyalg", "RSA",
        "-keysize", "4096",
        "-validity", "10000",
        "-dname", "CN=Literia, OU=Mobile, O=va97ra, L=Moscow, ST=Moscow, C=RU"
    )
    & keytool @keytoolArguments
    if ($LASTEXITCODE -ne 0) {
        throw "keytool failed to create the signing key."
    }

    $propertiesContent = @(
        "storeFile=literia-upload.keystore",
        "storePassword=$password",
        "keyAlias=$Alias",
        "keyPassword=$password"
    )
    [IO.File]::WriteAllLines(
        $propertiesPath,
        $propertiesContent,
        [Text.UTF8Encoding]::new($false)
    )

    $pepkArguments = @(
        "-jar", $pepkPath,
        "--keystore", $keystorePath,
        "--alias", $Alias,
        "--output=$outputPath",
        "--encryptionkey=$EncryptionKey",
        "--keystore-pass=$password",
        "--key-pass=$password",
        "--include-cert"
    )
    & java @pepkArguments
    if ($LASTEXITCODE -ne 0) {
        throw "PEPK failed to create the encrypted key archive."
    }
    if (-not (Test-Path -LiteralPath $outputPath)) {
        throw "PEPK did not create the expected archive: $outputPath"
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($outputPath)
    try {
        $certificateEntry = $archive.GetEntry("certificate.pem")
        if ($null -eq $certificateEntry) {
            throw "PEPK archive does not contain certificate.pem."
        }
        [IO.Compression.ZipFileExtensions]::ExtractToFile(
            $certificateEntry,
            $certificateOutputPath,
            $false
        )
    }
    finally {
        $archive.Dispose()
    }

    Write-Output "Keystore: $keystorePath"
    Write-Output "Local signing properties: $propertiesPath"
    Write-Output "Encrypted key archive: $outputPath"
    Write-Output "Upload certificate: $certificateOutputPath"
    Write-Output "Back up the keystore and key.properties together before publishing."
}
catch {
    if (Test-Path -LiteralPath $propertiesPath) {
        Remove-Item -Force -LiteralPath $propertiesPath
    }
    if (Test-Path -LiteralPath $keystorePath) {
        Remove-Item -Force -LiteralPath $keystorePath
    }
    if (Test-Path -LiteralPath $outputPath) {
        Remove-Item -Force -LiteralPath $outputPath
    }
    if (Test-Path -LiteralPath $certificateOutputPath) {
        Remove-Item -Force -LiteralPath $certificateOutputPath
    }
    throw
}
finally {
    [Array]::Clear($randomBytes, 0, $randomBytes.Length)
    $password = $null
}
