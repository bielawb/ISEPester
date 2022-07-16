BeforeDiscovery {
    $repoRoot = $(git -C $PSScriptRoot rev-parse --show-toplevel)
    $module = Import-Module -Name $repoRoot\output\ISEPester -Force -PassThru
    $publicFunctions = @(
        foreach ($function in $module.ExportedFunctions.Keys) {
            @{
                Name = $function
            }
        }
    )
    $analyzeTests = @(
        foreach ($file in Get-ChildItem -Path $repoRoot\tests\*.ps1) {
            @{
                Name = $file.Name
                Path = $file.FullName
            }
        }
    )
    $analyzeSources = @(
        foreach ($file in Get-ChildItem -Path $repoRoot\source\*\*.ps1) {
            @{
                Name = $file.Name
                Path = $file.FullName
            }
        }
    )
    $analyzeBuild = @(
        foreach ($file in Get-ChildItem -Path $repoRoot\build\*.ps1) {
            @{
                Name = $file.Name
                Path = $file.FullName
            }
        }
    )
    $moduleFile = @(
        @{
            Path = "$repoRoot\output\ISEPester\ISEPester.psm1"
        }
    )
}

Describe 'Testing global configuration' {
    It 'Has tests for public function <Name>' {
        "$PSScriptRoot\$Name.Tests.ps1" | Should -Exist
    } -TestCases $publicFunctions

    It 'Passes all required rules for test file <Name>' {
        $result = @(Invoke-ScriptAnalyzer -ExcludeRule PSUseDeclaredVarsMoreThanAssignments -Path $Path)
        $result.ForEach{
            '{0}({1}) => {2}:{3} ({4})' -f $_.RuleName, $_.Severity, $_.ScriptName, $_.Line, $_.Message
        } | Should -BeNullOrEmpty
    } -TestCases $analyzeTests


    It 'Passes all required rules for source file <Name>' {
        $result = @(Invoke-ScriptAnalyzer -Path $Path)
        $result.ForEach{
            '{0}({1}) => {2}:{3} ({4})' -f $_.RuleName, $_.Severity, $_.ScriptName, $_.Line, $_.Message
        } | Should -BeNullOrEmpty
    } -TestCases $analyzeSources

    It 'Passes all required rules for build script <Name>' {
        $result = @(Invoke-ScriptAnalyzer -Path $Path)
        $result.ForEach{
            '{0}({1}) => {2}:{3} ({4})' -f $_.RuleName, $_.Severity, $_.ScriptName, $_.Line, $_.Message
        } | Should -BeNullOrEmpty
    } -TestCases $analyzeBuild

    It 'Passes all required rules in a resultant module file' {
        $result = @(Invoke-ScriptAnalyzer -Path $Path)
        $result.ForEach{
            '{0}({1}) => {2}:{3} ({4})' -f $_.RuleName, $_.Severity, $_.ScriptName, $_.Line, $_.Message
        } | Should -BeNullOrEmpty
    } -TestCases $moduleFile
}