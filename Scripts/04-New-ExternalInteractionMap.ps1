# Bonus demo - Show how all solutions talk to the outside world.
# The module combines the flows of every solution into one diagram:
# which solution calls which domain, and which flows can be triggered from the internet.

Import-Module PowerPlatformChecker

# Every folder in ./Solutions is an unpacked solution, the module reads them all.
# PAC deployment values override solution defaults for the external-location view.
$diagram = Get-PowerPlatformCheckerExternalInteraction `
	-SolutionPaths ./Solutions `
	-SettingsFile ./Settings/ContosoOrders.settings.json

# The module returns Azure DevOps wiki syntax (:::mermaid), GitHub needs a ```mermaid code block
$markdown = ($diagram | Out-String) -replace '(?m)^:::mermaid', '```mermaid' -replace '(?m)^:::\s*$', '```'

Write-Host $markdown

"## External interactions`n`n$markdown" | Add-Content -Path $env:GITHUB_STEP_SUMMARY
