<#
    .Synopsis
    Script that runs pester tests using Pester 5.

    .Description
    Script that runs Pester tests and writes results in proper format.
    Configuration used:
    - Run/ Path -> By default all files in tests/*.Tests.ps1
    - Verbosity -> Detailed by default (controlled by parameter)
    - CIFormat -> GithubActions by default (controlled by parameter)

    .Example
    Invoke-PesterTest
    Runs tests with a default parameter values.
#>
[CmdletBinding()]
param (
    # Top folder of the repository where build should be run. Defaults to top level of the repo where script is located.
    [String]$Path = $(git -C $PSScriptRoot rev-parse --show-toplevel),

    # Name of the folder with test scripts
    [String]$TestsFolder = 'tests',

    # Name of the output folder
    [String]$OutputFolder = 'output',

    # Verbosity of the output of Pester tests. Default to Detailed view.
    [ValidateSet(
        'None',
        'Normal',
        'Detailed',
        'Diagnostic'
    )]
    [String]$Verbosity = 'Detailed',

    # CI format for errors
    [ValidateSet(
        'None',
        'Auto',
        'AzureDevops',
        'GithubActions'
    )]
    [String]$CIFormat = 'GithubActions'
)

Import-Module -Name Pester -MinimumVersion 5.0
$config = [PesterConfiguration]::Default
$config.Output.Verbosity = $Verbosity
$config.Output.CIFormat = $CIFormat
$config.CodeCoverage.Enabled = $true

Write-Verbose -Message "Root path: $Path"
$testPath = Join-Path -Path $Path -ChildPath $TestsFolder
$outputPath = Join-Path -Path $Path -ChildPath $OutputFolder

$config.Run.Path = @(
    foreach ($testFile in Get-ChildItem -Path $testPath -Filter *.Tests.ps1) {
        $testFile.FullName
    }
)

$config.CodeCoverage.Path = @(
    foreach ($outputFile in Get-ChildItem -Recurse -Path $outputPath -Filter *.ps*) {
        $outputFile.FullName
    }
)

Invoke-Pester -Configuration $config
