# Demo 1 - Fail the build when a flow still uses the default action names.
# Power Automate names actions like "Apply_to_each", "Condition" or "HTTP" by default.
# Those names say nothing about what the flow does, so we want them renamed.

Import-Module PowerPlatformChecker

$errorCount = 0
$summary = "## Default action name check`n`n| Flow | Action | Result |`n|---|---|---|`n"

# An unpacked solution has a Workflows folder with one .json file per flow
$flowFiles = Get-ChildItem -Path ./Solutions -Recurse -Filter *.json |
    Where-Object { $_.Directory.Name -eq 'Workflows' }

foreach ($flowFile in $flowFiles) {
    # The file name looks like "SyncOrdersToErp-<guid>", we only want the readable part
    $flowName = $flowFile.BaseName -replace '-[0-9a-f-]{36}$', ''
    $relativePath = [IO.Path]::GetRelativePath((Get-Location), $flowFile.FullName)

    # Everything between group and endgroup is collapsed into one block in the log
    Write-Host "::group::$flowName"

    # The module returns every action, with the default name and whether the action still uses it
    $actions = Test-PowerPlatformCheckerFlowOperationName -Path $flowFile.FullName

    foreach ($action in $actions) {
        if ($action.Equal) {
            $errorCount++
            Write-Host "❌ $($action.ActionName)  (default name, rename it)"
            # An error annotation shows up as a red message on the workflow run
            Write-Host "::error file=$relativePath,title=Default action name::'$($action.ActionName)' in flow '$flowName' still has its default name"
            $summary += "| $flowName | ``$($action.ActionName)`` | ❌ Default name |`n"
        }
        else {
            Write-Host "✅ $($action.ActionName)"
            $summary += "| $flowName | ``$($action.ActionName)`` | ✅ Renamed |`n"
        }
    }

    Write-Host "::endgroup::"
}

# The summary is the markdown page that is shown on top of the workflow run
$summary | Add-Content -Path $env:GITHUB_STEP_SUMMARY

# A non-zero exit code fails the job, which blocks the pull request
if ($errorCount -gt 0) {
    Write-Host "❌ $errorCount action(s) still have a default name"
    exit 1
}

Write-Host "✅ All actions are renamed"
