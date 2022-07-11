try {
    Import-Module -Name Pester -MinimumVersion 5.0 -ErrorAction Stop
} catch {
    Write-Error -Message "Failed to import module Pester - can't continue. Error: $_"
    return
}
