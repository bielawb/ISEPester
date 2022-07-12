function Invoke-ISECurrentTest {
    <#
        .Synopsis
        Function to run tests based on cursor location in editor file.

        .Description
        PowerShell ISE allows to see current location of the cursor in editor tab.
        Using that information makes it possible to run a test based on that location.
        Logic is:
        - if the cursor is on the line with container name (It, Context, Describe) that block is called.
        - if the cursor is on the line inside any `It` block - that block only would be called.

        .Example
        Invoke-ISECurrentTest
        
        Runs test on the line where cursor in the current file is located.
    #>
    [CmdletBinding()]
    param (
        # Verbosity of output
        [ValidateSet(
            'None',
            'Normal',
            'Detailed',
            'Diagnostic'
        )]
        [String]$Verbosity,

        # Verbosity of stack trace
        [ValidateSet(
            'None',
            'FirstLine',
            'Filtered',
            'Full'
        )]
        [String]$StackTraceVerbosity,

        # The CI format of error output in build logs
        [ValidateSet(
            'None',
            'Auto',
            'AzureDevops',
            'GithubActions'
        )]
        [String]$CIFormat,

        # The scope where scripts should run
        [Scope]$InvokeScope,

        # Behavior for files that were not saved
        [NotSaved]$ActionNotSaved,

        # Behavior for filest that are untitled/ not saved to disk yet
        [Untitled]$ActionUntitled
    )

    $currentIsePesterConfig = $script:isePesterConfiguration.clone()

    foreach (
        $key in @(
            'InvokeScope'
            'ActionNotSaved'
            'ActionUntitled'
        )
    ) {
        if ($PSBoundParameters.ContainsKey($key)) {
            $currentIsePesterConfig.$key = $PSBoundParameters.$key
        }
    }

    try {
        $ise = Get-psISE
    } catch {
        Write-Warning -Message 'Command designed to use in PowerShell ISE'
    }

    if (-not (Get-Module -Name Pester)) {
        try {
            Import-Module -Name Pester -MinimumVersion 5.0 -ErrorAction Stop
        } catch {
            Write-Warning -Message "Failed to import Pester module - $_"
        }
    }

    $tempFile = $null

    if (
        ($file = $ise.CurrentFile) -and
        ($line = $file.Editor.CaretLineText) -and
        ($lineNumber = $file.Editor.CaretLine)
    ) {
        if ($file.IsSaved) {
            $testFilePath = $file.FullPath
        } else {
            if ($file.IsUntitled) {
                if ($currentIsePesterConfig.ActionUntitled -eq [Untitled]::Ignore) {
                    Write-Warning -Message "File not saved and ISEPester configure to ignore Untitled files - can't continue"
                    return
                } else {
                    $tempFile = [IO.Path]::GetTempFileName() |
                        Get-Item |
                        Rename-Item -NewName { '{0}.Tests.ps1' -f $_.Name } -PassThru
                    Set-Content -Path $tempFile.FullName -Value $file.Editor.Text
                    $testFilePath = $tempFile.FullName
                }
            } else {
                if ($currentIsePesterConfig.ActionNotSaved -eq [NotSaved]::RunFromDisk) {
                    Write-Warning -Message "File $($file.FullPath) is not saved - working on current copy on disk!"
                    $testFilePath = $file.FullPath
                } else {
                    $tempFile = [IO.Path]::GetTempFileName() |
                        Get-Item |
                        Rename-Item -NewName { '{0}.Tests.ps1' -f $_.Name } -PassThru
                    Set-Content -Path $tempFile.FullName -Value $file.Editor.Text
                    $testFilePath = $tempFile.FullName
                }
            }
        }

        $config = [PesterConfiguration]@{
            Run = @{
                Path = $testFilePath
            }
        }

        foreach (
            $parameter in @(
                'Verbosity'
                'StackTraceVerbosity'
                'CIFormat'
            )
        ) {
            if ($PSBoundParameters.ContainsKey($parameter)) {
                $config.Output.$parameter = $PSBoundParameters.$parameter
            } else {
                $config.Output.$parameter = $script:outputConfiguration.$parameter
            }
        }
        $parsedTestFile = [System.Management.Automation.Language.Parser]::ParseFile($testFilePath, [ref]$null, [ref]$null)
        $filter = ''
        if ($line -match '\s*(Describe|Context|It)') {
            # lets make sure this is not a comment...
            $myBlock = $parsedTestFile.FindAll(
                {
                    param (
                        $Ast
                    )
                    $Ast.CommandElements -and
                    $Ast.CommandElements[0].Value -in 'It', 'Context', 'Describe' -and
                    $Ast.Extent.StartLineNumber -eq $lineNumber
                },
                $true
            )
            if ($myBlock) {
                $filter = '{0}:{1}' -f $testFilePath, $lineNumber
            }
        }
        if ([String]::IsNullOrEmpty($filter)) {
            $myItBlock = $parsedTestFile.FindAll(
                {
                    param (
                        $Ast
                    )
                    $Ast.CommandElements -and
                    $Ast.CommandElements[0].Value -eq 'It' -and
                    $Ast.Extent.StartLineNumber -le $lineNumber -and
                    $Ast.Extent.EndLineNumber -ge $lineNumber
                },
                $true
            )
            if ($myItBlock) {
                $filter = '{0}:{1}' -f $testFilePath, $myItBlock[0].Extent.StartLineNumber
            } else {
                Write-Warning -Message "Line '$line' at $lineNumber is not inside It block - perhaps $($file.FullPath) is not a test file?"
                return
            }
        }

        $config.Filter.Line = $filter
        if ($currentIsePesterConfig.InvokeScope -eq [Scope]::ParentScope) {
            Invoke-Pester -Configuration $config
        } else {
            & {
                Invoke-Pester -Configuration $config
            }
        }
        if ($tempFile) {
            $tempFile | Remove-Item -Force
        }
    } else {
        Write-Warning -Message 'Not able to figure out cursor position - giving up.'
    }
}
