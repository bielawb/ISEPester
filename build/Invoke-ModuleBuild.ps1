<#
    .Synopsis
    Script that combines files in the module into psm1/psd1 pair.

    .Description
    Script that runs few steps to generated psm1/ psd1 for a module:
    - read <ModuleName>.psd1 to get module skeleton (description, author, tags and more)
    - collects information about public commands to generate FunctionsToExport
    - uses AST to figure out if we need to export aliases too
    - uses build number to update last number in the version number
    - saves <ModuleName>.psd1 to 'output\<ModuleName>' in the root of the repo.
    - combines prefix(es), private/ public functions and suffix(es) into <ModuleName>.psm1 and saves it to output folder
    - mimics folder structure under source/extras in output\<ModuleName>\

    .Example
    Invoke-ModuleBuild
    Runs script with a default parameter values.
#>
[CmdletBinding()]
param (
    # Top folder of the repository where build should be run. Defaults to top level of the repo where script is located.
    [String]$Path = $(git -C $PSScriptRoot rev-parse --show-toplevel),

    # Name of the source folder
    [String]$SourceFolder = 'source',

    # Name of the output folder
    [String]$OutputFolder = 'output'
)

Write-Verbose -Message "Root path: $Path"

$psm1Content = [System.Text.StringBuilder]::new()
$psd1FunctionList = [Collections.Generic.List[String]]::new()
$sourcePath = Join-Path -Path $Path -ChildPath $SourceFolder

$prefixPath = Join-Path -Path $sourcePath -ChildPath Prefix
if (Test-Path -Path $prefixPath) {
    $null = $psm1Content.AppendLine('#region prefix code')
    $null = foreach ($prefix in Get-ChildItem -Path $prefixPath -Filter *.ps1) {
        $content = Get-Content -Path $prefix.FullName -Raw
        $psm1Content.AppendLine("#region content of file $($prefix.BaseName)")
        $psm1Content.Append($content)
        $psm1Content.AppendLine('#endregion')
    }
    $null = $psm1Content.AppendLine('#endregion')
}

$privatePath = Join-Path -Path $sourcePath -ChildPath Private
if (Test-Path -Path $privatePath) {
    $null = $psm1Content.AppendLine('#region private functions')
    $null = foreach ($private in Get-ChildItem -Path $privatePath -Filter *.ps1) {
        $content = Get-Content -Path $private.FullName -Raw
        $psm1Content.AppendLine("#region content of file $($private.BaseName)")
        $psm1Content.Append($content)
        $psm1Content.AppendLine('#endregion')
    }
    $null = $psm1Content.AppendLine('#endregion')
}

$publicPath = Join-Path -Path $sourcePath -ChildPath Public
if (Test-Path -Path $publicPath) {
    $null = $psm1Content.AppendLine('#region public functions')
    $null = foreach ($public in Get-ChildItem -Path $publicPath -Filter *.ps1) {
        $content = Get-Content -Path $public.FullName -Raw
        $psm1Content.AppendLine("#region content of file $($public.BaseName)")
        $psd1FunctionList.Add($public.BaseName)
        $psm1Content.Append($content)
        $psm1Content.AppendLine('#endregion')
    }
    $null = $psm1Content.AppendLine('#endregion')
}

$suffixPath = Join-Path -Path $sourcePath -ChildPath Suffix
if (Test-Path -Path $suffixPath) {
    $null = $psm1Content.AppendLine('#region sufix')
    $null = foreach ($suffix in Get-ChildItem -Path $suffixPath -Filter *.ps1) {
        $content = Get-Content -Path $suffix.FullName -Raw
        $psm1Content.AppendLine("#region content of file $($suffix.BaseName)")
        $psm1Content.Append($content)
        $psm1Content.AppendLine('#endregion')
    }
    $null = $psm1Content.AppendLine('#endregion')
}


$psd1File = Get-ChildItem -Path $sourcePath -Filter *.psd1
$functionsToExport = @(foreach ($function in $psd1FunctionList) {
    "        '$function'"
})
$psd1Content = Get-Content -Path $psd1File.FullName |
    ForEach-Object {
        if ($_ -match 'FunctionsToExport') {
            @('    FunctionsToExport = @(') + $functionsToExport + '    )'
        } else {
            $_
        }
    }

$outputPath = Join-Path -Path $Path -ChildPath $OutputFolder
$moduleFolder = Join-Path $outputPath -ChildPath $psd1File.BaseName
if (-not (Test-Path -Path $moduleFolder)) {
    $null = New-Item -ItemType Directory -Path $moduleFolder
}
$outputPsd1 = Join-Path -Path $moduleFolder -ChildPath $psd1File.Name
$outputPsm1 = Join-Path -Path $moduleFolder -ChildPath ('{0}.psm1' -f $psd1File.BaseName)
Set-Content -Encoding UTF8 -Path $outputPsd1 -Value $psd1Content
Set-Content -Encoding UTF8 -Path $outputPsm1 -Value $psm1Content.ToString()

$filesPath = Join-Path -Path $sourcePath -ChildPath Files
if (Test-Path -Path $filesPath) {
    foreach ($item in Get-ChildItem -Path $filesPath) {
        Copy-Item -Recurse -Path $item.FullName -Destination $moduleFolder -Force
    }
}
