# Demo 2 - Check the connectors, parameters and description of every flow.
# - Premium connectors fail the build, because they need extra licenses.
# - A missing description only gives a warning.

Import-Module PowerPlatformChecker

$errorCount = 0
$summary = "## Flow checks`n`n| Solution | Flow | Connectors | Parameters | Description |`n|---|---|---|---|---|`n"

foreach ($solution in Get-ChildItem -Path ./Solutions -Directory) {

    # One call returns the metadata of all flows in the solution
    $flows = Get-PowerPlatformCheckerFlow -SolutionPath $solution.FullName -Properties Parameters, ConnectorTiers

    foreach ($flow in $flows) {
        Write-Host "::group::$($solution.Name) / $($flow.Name)"

        # Connectors, for example "Office 365 Outlook (Standard)"
        $connectors = foreach ($connector in $flow.ConnectorTiers) {
            Write-Host "  Connector: $($connector.DisplayName) ($($connector.Tier))"
            "$($connector.DisplayName) ($($connector.Tier))"
        }

        # Parameters, these are the environment variables the flow uses
        $parameters = foreach ($parameter in $flow.Parameters) {
            Write-Host "  Parameter: $($parameter.Name) [$($parameter.Type)]"
            $parameter.SchemaName
        }

        # Rule 1: no premium connectors
        foreach ($connector in $flow.ConnectorTiers | Where-Object Tier -eq 'Premium') {
            $errorCount++
            Write-Host "::error title=Premium connector::Flow '$($flow.Name)' uses the premium connector '$($connector.DisplayName)'"
        }

        # Rule 2: every flow has a description
        if ([string]::IsNullOrWhiteSpace($flow.Description)) {
            Write-Host "::warning title=Missing description::Flow '$($flow.Name)' has no description"
            $description = '⚠️ Missing'
        }
        else {
            $description = '✅'
        }

        $tierIcon = if ($flow.ConnectorTiers.Tier -contains 'Premium') { '❌' } else { '✅' }
        $summary += "| $($solution.Name) | $($flow.Name) | $tierIcon $($connectors -join ', ') | $($parameters -join ', ') | $description |`n"

        Write-Host "::endgroup::"
    }
}

$summary | Add-Content -Path $env:GITHUB_STEP_SUMMARY

if ($errorCount -gt 0) {
    Write-Host "❌ $errorCount premium connector(s) found"
    exit 1
}

Write-Host "✅ No premium connectors found"
