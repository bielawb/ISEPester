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
    param ()
    try {
        $ise = Get-psISE
    } catch {
        Write-Warning -Message 'Command designed to use in PowerShell ISE'
    }

    if (
        ($file = $ise.CurrentFile) -and
        (Test-Path -LiteralPath $file.FullPath) -and
        ($line = $file.Editor.CaretLineText) -and
        ($lineNumber = $file.Editor.CaretLine)
    ) {
        if (-not $file.IsSaved) {
            Write-Warning -Message "File $($file.FullPath) is not saved - working on current copy on disk!"
        }
        $config = [PesterConfiguration]@{
            Output = @{
                Verbosity = 'Detailed'
            }
            Run = @{
                Path = $file.FullPath
            }
        }
        if ($line -match '\s*(Describe|Context|It)') {
            $config.Filter.Line = '{0}:{1}' -f $file.FullPath, $lineNumber
        } else {
            $parsedTestFile = [System.Management.Automation.Language.Parser]::ParseFile($file.FullPath, [ref]$null, [ref]$null)
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
            $config.Filter.Line = '{0}:{1}' -f $file.FullPath, $myItBlock[0].Extent.StartLineNumber
        }
        Invoke-Pester -Configuration $config
    } else {
        Write-Warning -Message 'Command can work only with test files saved on disk - save it first!'
    }
}
