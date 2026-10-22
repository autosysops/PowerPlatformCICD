# Demo 2 - Generate documentation for every solution.
# The result is one markdown file per solution with an architecture diagram and a flowchart per flow.

Import-Module PowerPlatformChecker -MinimumVersion 1.3.0

# The module returns Azure DevOps wiki syntax (:::mermaid), GitHub needs a ```mermaid code block
function Convert-ToGitHubMermaid ($Diagram) {
    return ($Diagram | Out-String) -replace '(?m)^:::mermaid', '```mermaid' -replace '(?m)^:::\s*$', '```'
}

# Returns every Apply to each loop in the flowchart graph, including nested ones
function Get-ApplyToEachLoop ($Graph) {
    foreach ($subgraph in $Graph.Subgraphs) {
        if ($subgraph.Loop.Type -eq 'Foreach') { $subgraph }
        Get-ApplyToEachLoop $subgraph
    }
}

# Finds an action by name in the flow definition, also inside scopes, conditions, switches and loops
function Find-FlowAction ($Actions, $Name) {
    if ($null -eq $Actions) { return }
    if ($Actions.PSObject.Properties.Name -contains $Name) { return $Actions.$Name }

    foreach ($action in $Actions.PSObject.Properties.Value) {
        $nested = @($action.actions, $action.else.actions, $action.default.actions)
        $nested += @($action.cases.PSObject.Properties.Value | ForEach-Object { $_.actions })
        foreach ($childActions in $nested) {
            $found = Find-FlowAction $childActions $Name
            if ($found) { return $found }
        }
    }
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

        # Build the graph once: analyze it for loops and render the same graph to Mermaid
        $flowGraph = Get-PowerPlatformCheckerFlowChart -Actions $actions -OutputFormat Graph
        $markdown += "$(Convert-ToGitHubMermaid (Convert-PowerPlatformCheckerFlowChartGraphToMermaid -Graph $flowGraph))`n"

        # The graph shows the concurrency in use, the flow definition tells if it was set on purpose
        $definitionActions = (Get-Content -Path $flowFile.FullName -Raw | ConvertFrom-Json).properties.definition.actions
        $defaultLoops = @(Get-ApplyToEachLoop $flowGraph | Where-Object {
            $loopAction = Find-FlowAction $definitionActions $_.ActionName
            $null -eq $loopAction.runtimeConfiguration.concurrency.repetitions -and $loopAction.operationOptions -notmatch 'Sequential'
        })

        if ($defaultLoops.Count -gt 0) {
            $loopNames = ($defaultLoops | ForEach-Object { "``$($_.ActionName)``" }) -join ', '
            Write-Host "::warning title=Concurrency not set::$($flow.Name): $($defaultLoops.ActionName -join ', ') uses the default concurrency"
            $markdown += "> [!WARNING]`n"
            $markdown += "> Concurrency is not set explicitly for $loopNames. Apply to each runs one item at a time (concurrency 1) by default.`n"
            $markdown += "> Turn on concurrency control in the loop settings and choose the value on purpose.`n`n"
        }
    }

    # Save the file (published as artifact) and show the same markdown on the workflow run page
    $markdown | Set-Content -Path "./Docs/$($solution.Name).md"
    $markdown | Add-Content -Path $env:GITHUB_STEP_SUMMARY

    Write-Host "✅ Created Docs/$($solution.Name).md"
    Write-Host "::endgroup::"
}
