function Get-psISE {
    <#
        .Synopsis
        Helper function that returns psISE object (needed for testing /mocking)

        .Description
        $psISE automatic variable is read-only and can't be replaced inside ISE.
        To prevent not being able to test module inside that host - adding simple function that returns this object.

        .Example
        $test = Get-psISE
        
        Saves value of psISE object into variable test.
    #>
    [CmdletBinding()]
    param ()

    $psISE
}
