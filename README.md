# ISEPester

Module with ISE tools for Pester v5+

## Usage

Module helps with running a single test (or group of tests in a single Context/Describe).
By default on import it will try to assign Invoke-ISECurrentTest to shortcut CTRL+F8.

You  can also run the same command (with parameters) from script pane when correct file/ line are selected.

## Configuration

By default tests are run with following configuration:
- Formats as in [Pester.OutputConfiguration]::Default
- Ignoring not saved, "Untitled" files
- For files on disk and not saved - using copy from disk (ignoring unsaved changes)

Configuration per session can be adjusted using Set-ISEPesterConfiguration function.
Configuration per run can be adjusted using parameters on Invoke-ISECurrentTest function.