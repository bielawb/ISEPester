Describe "Testing Invoke-ISECurrentTest" {
    BeforeAll {
        $module = Import-Module -Name $PSScriptRoot\..\output\ISEPester\ISEPester.psd1 -PassThru -Force
        Mock -CommandName Import-Module
    }
    
    Context 'Testing normal actions' {
        BeforeAll {
            Set-Content -Path testdrive:\test.tests.ps1 -Value @'
Describe Foo {
    It One {
        'One' | Should -Be One
    }

    It Two {
        'Two' | Should -Be Two
    }
}

# It is a commend outside of tests - should not work - line 11
'@
            InModuleScope -ModuleName ISEPester {
                Mock -CommandName Test-Path -MockWith { $true }
                Mock -CommandName Invoke-Pester
            }
        }

        It 'Should run Invoke-Pester when line with Describe is selected' {
            InModuleScope -ModuleName ISEPester {
                Mock -CommandName Get-psISE -MockWith {
                    @{
                        CurrentFile = @{
                            FullPath = Convert-Path -Path 'testdrive:\test.tests.ps1'
                            Editor = @{
                                CaretLineText = '	Describe Foo {'
                                CaretLine = 1
                            }
                            IsSaved = $true
                        }
                    }
                }
            }
            Invoke-ISECurrentTest
            InModuleScope -ModuleName ISEPester {
                Should -Invoke -CommandName Invoke-Pester -Times 1 -Exactly -ParameterFilter {
                    $expectedPath = Convert-Path -Path 'testdrive:\test.tests.ps1'
                    $Configuration.Run.Path.Value -eq $expectedPath -and
                    $Configuration.Filter.Line.Value -eq "${expectedPath}:1"
                }
            }
        }

        It 'Should not be fooled by a comment with It in it' {
            InModuleScope -ModuleName ISEPester {
                Mock -CommandName Get-psISE -MockWith {
                    @{
                        CurrentFile = @{
                            FullPath = Convert-Path -Path 'testdrive:\test.tests.ps1'
                            Editor = @{
                                CaretLineText = "# It is a commend outside of tests - should not work - line 11"
                                CaretLine = 11
                            }
                            IsSaved = $true
                        }
                    }
                }
            }
            Invoke-ISECurrentTest -WarningVariable foo -WarningAction SilentlyContinue
            $foo | Should -Not -BeNullOrEmpty
            InModuleScope -ModuleName ISEPester {
                Should -Invoke -CommandName Invoke-Pester -Times 0 -Exactly
            }
        }

        It 'Should run Invoke-Pester when line inside It block is selected' {
            InModuleScope -ModuleName ISEPester {
                Mock -CommandName Get-psISE -MockWith {
                    @{
                        CurrentFile = @{
                            FullPath = Convert-Path -Path 'testdrive:\test.tests.ps1'
                            Editor = @{
                                CaretLineText = "        'One' | Should -Be One"
                                CaretLine = 3
                            }
                            IsSaved = $true
                        }
                    }
                }
            }
            Invoke-ISECurrentTest
            InModuleScope -ModuleName ISEPester {
                Should -Invoke -CommandName Invoke-Pester -Times 1 -Exactly -ParameterFilter {
                    $expectedPath = Convert-Path -Path 'testdrive:\test.tests.ps1'
                    $Configuration.Run.Path.Value -eq $expectedPath -and
                    $Configuration.Filter.Line.Value -eq "${expectedPath}:2"
                }
            }
        }
    }
}
