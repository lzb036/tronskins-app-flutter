param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Targets = @('lib')
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Path $PSScriptRoot -Parent

function Resolve-DartExe {
    $flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
    if ($flutterCmd -and $flutterCmd.Source) {
        $flutterBinDir = Split-Path -Path $flutterCmd.Source -Parent
        $flutterRoot = Split-Path -Path $flutterBinDir -Parent
        $flutterDartExe = Join-Path -Path $flutterRoot -ChildPath 'bin\cache\dart-sdk\bin\dart.exe'
        if (Test-Path -Path $flutterDartExe) {
            return $flutterDartExe
        }
    }

    $dartExeCmd = Get-Command dart.exe -ErrorAction SilentlyContinue
    if ($dartExeCmd -and $dartExeCmd.Source) {
        return $dartExeCmd.Source
    }

    throw "Unable to locate dart.exe. Ensure Flutter/Dart is installed and in PATH."
}

$dartExe = Resolve-DartExe
Write-Host "Using Dart: $dartExe"

# Resolve relative targets from project root so execution directory does not matter.
$resolvedTargets = @()
foreach ($target in $Targets) {
    if ([System.IO.Path]::IsPathRooted($target)) {
        $resolvedTargets += $target
    } else {
        $resolvedTargets += (Join-Path -Path $projectRoot -ChildPath $target)
    }
}

# Run analyzer through dart.exe directly to avoid wrapper lock/contention in dart.bat/flutter.bat.
& $dartExe analyze @resolvedTargets
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    exit $exitCode
}

Write-Host "Analyze completed."
