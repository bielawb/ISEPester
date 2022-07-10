Describe "Testing Set-ISEPesterConfiguration" {
    BeforeAll {
        $module = Import-Module -Name $PSScriptRoot\..\output\ISEPester\ISEPester.psd1 -PassThru -Force
    }
    BeforeEach {
        InModuleScope -ModuleName ISEPester {
            $script:outputConfiguration = @{
                Verbosity = 'Normal'
                StackTraceVerbosity = 'Filtered'
                CIFormat = 'Auto'
            }
            $script:invokeScope = 'ParentScope'
        }
    }

    It 'Changes Verbosity as expected' {
        Set-ISEPesterConfiguration -Verbosity Detailed
        & $module {
            $script:outputConfiguration.Verbosity
        } | Should -BeExactly Detailed
    }

    It 'Changes StackTraceVerbosity as expected' {
        Set-ISEPesterConfiguration -StackTraceVerbosity FirstLine
        & $module {
            $script:outputConfiguration.StackTraceVerbosity
        } | Should -BeExactly FirstLine
    }

    It 'Changes CIFormat as expected' {
        Set-ISEPesterConfiguration -CIFormat GithubActions
        & $module {
            $script:outputConfiguration.CIFormat
        } | Should -BeExactly GithubActions
    }

    It 'Changes invoke scope as expected' {
        Set-ISEPesterConfiguration -InvokeScope ChildScope
        & $module {
            $script:invokeScope
        } | Should -BeExactly ChildScope
    }
}
