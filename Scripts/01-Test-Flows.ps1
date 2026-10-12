# Demo 1 - Lint the flows.
# One script checks every flow in every solution:
# - Actions must be renamed (error)
# - Premium connectors are not allowed (error)
# - Actions should use secure inputs and outputs (warning)
# - Flows should have a description (warning)

Import-Module PowerPlatformChecker

$errorCount = 0
$summary = "## Flow lint results`n`n"

foreach ($solution in Get-ChildItem -Path ./Solutions -Directory) {

    # One call returns the metadata of all flows in the solution
    $flows = Get-PowerPlatformCheckerFlow -SolutionPath $solution.FullName -Properties Parameters, ConnectorTiers

    foreach ($flow in $flows) {
        Write-Host "::group::$($solution.Name) / $($flow.Name)"
        $summary += "### $($solution.Name) / $($flow.Name)`n`n| Action | Name | Secure inputs | Secure outputs |`n|---|---|---|---|`n"

        # The module works on the flow file, the file name ends with the id of the flow
        $flowFile = Get-ChildItem -Path "$($solution.FullName)/Workflows" -Filter "*$($flow.Id).json"
        $relativePath = [IO.Path]::GetRelativePath((Get-Location), $flowFile.FullName)

        # Check 1: is the action name still the default name? (Equal = $true means it was not renamed)
        $names = Test-PowerPlatformCheckerFlowOperationName -Path $flowFile.FullName

        # Check 2: are secure inputs and outputs enabled?
        $security = Get-PowerPlatformCheckerFlowActionList -Path $flowFile.FullName -Recurse -Properties SecurityProfile

        foreach ($action in $names) {
            $secure = $security | Where-Object Name -eq $action.ActionName

            if ($action.Equal) {
                $errorCount++
                Write-Host "::error file=$relativePath,title=Default action name::'$($action.ActionName)' in flow '$($flow.Name)' still has its default name"
            }
            if (-not ($secure.SecureInputs -and $secure.SecureOutputs)) {
                Write-Host "::warning file=$relativePath,title=Secure data::'$($action.ActionName)' in flow '$($flow.Name)' does not have secure inputs and outputs enabled"
            }

            $nameIcon = if ($action.Equal) { '❌ Default name' } else { '✅ Renamed' }
            $inputIcon = if ($secure.SecureInputs) { '✅' } else { '⚠️' }
            $outputIcon = if ($secure.SecureOutputs) { '✅' } else { '⚠️' }
            $summary += "| ``$($action.ActionName)`` | $nameIcon | $inputIcon | $outputIcon |`n"
            Write-Host "$nameIcon  $($action.ActionName)  (secure inputs: $($secure.SecureInputs), secure outputs: $($secure.SecureOutputs))"
        }

        # Check 3: connectors, for example "Office 365 Outlook (Standard)"
        $connectors = foreach ($connector in $flow.ConnectorTiers) {
            Write-Host "Connector: $($connector.DisplayName) ($($connector.Tier))"
            $icon = if ($connector.Tier -eq 'Premium') { '❌' } else { '✅' }
            "$icon $($connector.DisplayName) ($($connector.Tier))"

            if ($connector.Tier -eq 'Premium') {
                $errorCount++
                Write-Host "::error title=Premium connector::Flow '$($flow.Name)' uses the premium connector '$($connector.DisplayName)'"
            }
        }

        # Check 4: parameters, these are the environment variables the flow uses
        $parameters = foreach ($parameter in $flow.Parameters) {
            Write-Host "Parameter: $($parameter.Name) [$($parameter.Type)]"
            $parameter.SchemaName
        }

        # Check 5: every flow has a description
        if ([string]::IsNullOrWhiteSpace($flow.Description)) {
            Write-Host "::warning title=Missing description::Flow '$($flow.Name)' has no description"
            $description = '⚠️ Missing'
        }
        else {
            $description = '✅ ' + $flow.Description
        }

        $summary += "`n**Connectors:** $($connectors -join ', ')`n`n**Parameters:** $($parameters -join ', ')`n`n**Description:** $description`n`n"
        Write-Host "::endgroup::"
    }
}

# The summary is the markdown page that is shown on top of the workflow run
$summary | Add-Content -Path $env:GITHUB_STEP_SUMMARY

# A non-zero exit code fails the job, which blocks the pull request
if ($errorCount -gt 0) {
    Write-Host "❌ $errorCount error(s) found"
    exit 1
}

Write-Host "✅ No errors found"
