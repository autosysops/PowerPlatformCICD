# Demo 4 - Generate a changelog for a pull request with AI.
# Git gives us the exact changes in the solution files, an Azure OpenAI model turns them into readable release notes.

param (
    # The commit to compare with, in a pull request this is the target branch
    [Parameter(Mandatory = $true)]
    [string] $BaseRef
)

# Get the changes made to the solutions since the base commit
$diff = git diff $BaseRef HEAD -- Solutions | Out-String

if ([string]::IsNullOrWhiteSpace($diff)) {
    Write-Host "No changes in the Solutions folder"
    exit 0
}

Write-Host "::group::Changes sent to the model"
Write-Host $diff
Write-Host "::endgroup::"

# The prompt tells the model what kind of text we expect back
$systemPrompt = @'
You write release notes for Power Platform solutions.
You get a git diff of unpacked solution files, mostly Power Automate flow JSON.
Write a short changelog in markdown with the headings Added, Changed and Removed.
Use the flow and action names a business user would recognize. Skip empty headings and do not mention file paths.
'@

$body = @{
    messages = @(
        @{ role = 'system'; content = $systemPrompt }
        @{ role = 'user'; content = $diff }
    )
} | ConvertTo-Json -Depth 5

# Azure OpenAI chat completions endpoint, the settings come from the repository secrets
$uri = "$env:AZURE_OPENAI_ENDPOINT/openai/deployments/$env:AZURE_OPENAI_DEPLOYMENT/chat/completions?api-version=2024-06-01"
$response = Invoke-RestMethod -Uri $uri -Method Post -Headers @{ 'api-key' = $env:AZURE_OPENAI_KEY } -ContentType 'application/json' -Body $body

$changelog = $response.choices[0].message.content

Write-Host $changelog

# Show the changelog on top of the workflow run
"## Changelog`n`n$changelog" | Add-Content -Path $env:GITHUB_STEP_SUMMARY

# Save it so the workflow can publish it with the release
New-Item -Path ./Docs -ItemType Directory -Force | Out-Null
$changelog | Set-Content -Path ./Docs/CHANGELOG.md
