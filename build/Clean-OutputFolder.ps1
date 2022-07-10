<#
    .Synopsis
    Script that cleans output folder

    .Description
    Script that removes anything it finds in the output folder, getting ready for a clean build.

    .Example
    Clean-OutputFolder
    Runs cleanup with a default parameter values.
#>
[CmdletBinding()]
param (
    # Top folder of the repository where build should be run. Defaults to top level of the repo where script is located.
    [String]$Path = $(git -C $PSScriptRoot rev-parse --show-toplevel),

    # Name of the output folder
    [String]$OutputFolder = 'output'
)

$outputPath = Join-Path -Path $Path -ChildPath $OutputFolder
foreach ($itemToDelete in Get-ChildItem -Path $outputPath) {
    $splat = @{
        Path = $itemToDelete.FullName
        Force = $true
        Confir = $false
    }
    if ($itemToDelete.PSIsContainer) {
        $splat.Recurse = $true
    }
    Remove-Item @splat
}