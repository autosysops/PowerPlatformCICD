# Demo 3 - Generate documentation for every solution.
# The result is one markdown file per solution with an architecture diagram and a flowchart per flow.

Import-Module PowerPlatformChecker

# The module returns Azure DevOps wiki syntax (:::mermaid), GitHub needs a ```mermaid code block
function Convert-ToGitHubMermaid ($Diagram) {
    return ($Diagram | Out-String) -replace '(?m)^:::mermaid', '```mermaid' -replace '(?m)^:::\s*$', '```'
}

New-Item -Path ./Docs -ItemType Directory -Force | Out-Null

foreach ($solution in Get-ChildItem -Path ./Solutions -Directory) {
    Write-Host "::group::Documenting $($solution.Name)"

    $markdown = "# $($solution.Name)`n`n"

    # Architecture diagram: flows, connections, environment variables and external domains
    $architecture = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $solution.FullName
    $markdown += "## Architecture`n`n$(Convert-ToGitHubMermaid $architecture)`n"

    # One section per flow
    $markdown += "## Flows`n`n"
    foreach ($flow in Get-PowerPlatformCheckerFlow -SolutionPath $solution.FullName -Properties ConnectorTiers) {
        Write-Host "Flow: $($flow.Name)"

        $markdown += "### $($flow.Name)`n`n"
        $markdown += "$($flow.Description)`n`n"

        # The flow chart is built from the list of actions, including the order they run in
        $flowFile = Get-ChildItem -Path "$($solution.FullName)/Workflows" -Filter "*$($flow.Id).json"
        $actions = Get-PowerPlatformCheckerFlowActionList -Path $flowFile.FullName -Recurse -IncludeTrigger -Properties RunAfter, ParentAction
        $flowChart = Get-PowerPlatformCheckerFlowChart -Actions $actions
        $markdown += "$(Convert-ToGitHubMermaid $flowChart)`n"
    }

    # Save the file (published as artifact) and show the same markdown on the workflow run page
    $markdown | Set-Content -Path "./Docs/$($solution.Name).md"
    $markdown | Add-Content -Path $env:GITHUB_STEP_SUMMARY

    Write-Host "✅ Created Docs/$($solution.Name).md"
    Write-Host "::endgroup::"
}
