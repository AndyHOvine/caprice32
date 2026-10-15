<#
.SYNOPSIS
    Builds Caprice32 on Windows from PowerShell, using the MSYS2 MINGW64 toolchain.

.DESCRIPTION
    Runs make inside MSYS2 in the directory this script lives in. Any arguments are
    passed straight to make as targets or variables.

.EXAMPLE
    .\build.ps1                  # release build: cap32.exe + release\cap32-win64.zip
.EXAMPLE
    .\build.ps1 debug            # debug build
.EXAMPLE
    .\build.ps1 unit_test        # build and run the unit tests
.EXAMPLE
    .\build.ps1 clean
.EXAMPLE
    .\build.ps1 -Jobs 4 e2e_test
#>
[CmdletBinding(PositionalBinding = $false)]
param(
    [int]$Jobs = [Environment]::ProcessorCount,
    [string]$Msys2Root = 'C:\msys64',
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$MakeArgs
)

$bash = Join-Path $Msys2Root 'usr\bin\bash.exe'
if (-not (Test-Path $bash)) {
    throw "MSYS2 not found at $Msys2Root. Install it with: winget install MSYS2.MSYS2"
}

$make = "make ARCH=win64 CXX=g++ WINE='' CFLAGS='-I/mingw64/include' -j$Jobs"
if ($MakeArgs) { $make += ' ' + ($MakeArgs -join ' ') }

# Remember the caller's environment so running the script doesn't change their session.
$oldMsystem = $env:MSYSTEM
$oldChere = $env:CHERE_INVOKING
Push-Location $PSScriptRoot
try {
    $env:MSYSTEM = 'MINGW64'
    $env:CHERE_INVOKING = '1'
    Write-Host "> $make" -ForegroundColor Cyan
    & $bash -lc $make
    $code = $LASTEXITCODE
}
finally {
    Pop-Location
    $env:MSYSTEM = $oldMsystem
    $env:CHERE_INVOKING = $oldChere
}

if ($code -ne 0) {
    Write-Host "Build failed (make exit code $code)" -ForegroundColor Red
} else {
    Write-Host 'Build succeeded' -ForegroundColor Green
}
exit $code
