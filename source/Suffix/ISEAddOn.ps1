try {
    $null = $psise.CurrentPowerShellTab.AddOnsMenu.Submenus.Add(
        'Run in Pester',
        { Invoke-ISECurrentTest },
        'CTRL+F8'
    )
} catch {
    Write-Warning -Message "Failed to add shortcut - $_"
}
