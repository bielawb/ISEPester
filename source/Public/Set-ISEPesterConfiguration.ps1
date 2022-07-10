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

        # The way of running tests
        [ValidateSet(
            'ParentScope',
            'ChildScope'
        )]
        [String]$InvokeScope
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

    if ($PSBoundParameters.ContainsKey('InvokeScope')) {
        $script:invokeScope = $InvokeScope
    }
}
