function Set-ISEPesterConfiguration {
    <#
        .Synopsis
        Function to configure the way Pester tests run in the ISE.

        .Description
        Functions allows to configure how tests in context of ISE will behave. It includes:
        - output options
        - scoping (to prevent polluting current scope)

        .Example
        Set-ISEPesterConfiguration -Verbosity Detailed -StackTraceVerbosity Filtered
        Changes outpuf of pester calls to:
        - display detailed results
        - show filter view for stack trace

        .Example
        Set-ISEPesterConfiguration -Invoke ChildScope
        Configures command to run in the child scope to prevent polluting parent scope.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessage(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'Changing configuration of the module, not the system state'
    )]
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

    foreach (
        $key in @(
            'Verbosity'
            'StackTraceVerbosity'
            'CIFormat'
        )
    ) {
        if ($PSBoundParameters.ContainsKey($key)) {
            $script:outputConfiguration.$key = $PSBoundParameters.$key
        }
    }

    foreach (
        $key in @(
            'InvokeScope'
            'ActionNotSaved'
            'ActionUntitled'
        )
    ) {
        if ($PSBoundParameters.ContainsKey($key)) {
            $script:isePesterConfiguration.$key = $PSBoundParameters.$key
        }
    }
}
