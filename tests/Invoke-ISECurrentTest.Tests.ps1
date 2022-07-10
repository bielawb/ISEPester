Describe "Testing Invoke-ISECurrentTest" {
    BeforeAll {
        $module = Import-Module -Name $PSScriptRoot\..\output\ISEPester\ISEPester.psd1 -PassThru -Force
        Mock -CommandName Import-Module
    }
    
    Context 'Testing when AST is not needed' {
        BeforeAll {
            InModuleScope -ModuleName ISEPester {
                Mock -CommandName Test-Path -MockWith { $true }
                Mock -CommandName Invoke-Pester
                Mock -CommandName Get-psISE -MockWith {
                    @{
                        CurrentFile = @{
                            FullPath = 'testdrive:\test.tests.ps1'
                            Editor = @{
                                CaretLineText = '	Describe Foo {'
                                CaretLine = 1
                            }
                            IsSaved = $true
                        }
                    }
                }
            }
        }

        It 'Should run Invoke-Pester with a correct file name/ filter' {
            Invoke-ISECurrentTest
            InModuleScope -ModuleName ISEPester {
                Should -Invoke -CommandName Invoke-Pester -Times 1 -Exactly -ParameterFilter {
                    $Configuration.Run.Path.Value -eq 'testdrive:\test.tests.ps1' -and
                    $Configuration.Filter.Line.Value -eq 'testdrive:\test.tests.ps1:1'
                }
            }
        }
    }
}
