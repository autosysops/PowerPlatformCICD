# Demo 4 - Generate a changelog for a pull request with AI.
# Git gives us the exact changes in the solution files, GitHub Copilot turns them into readable release notes.

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

Write-Host "::group::Changes sent to Copilot"
Write-Host $diff
Write-Host "::endgroup::"

# The prompt tells Copilot what kind of text we expect back, followed by the changes
$prompt = @"
You write release notes for Power Platform solutions.
Below is a git diff of unpacked solution files, mostly Power Automate flow JSON.
Write a short changelog in markdown with the headings Added, Changed and Removed.
Use the flow and action names a business user would recognize. Skip empty headings and do not mention file paths.

$diff
"@

# -p runs Copilot CLI once without a chat session, --silent returns only the answer
$changelog = copilot -p $prompt --silent --no-ask-user | Out-String

Write-Host $changelog

# Show the changelog on top of the workflow run
"## Changelog`n`n$changelog" | Add-Content -Path $env:GITHUB_STEP_SUMMARY

# Save it so the workflow can publish it with the release
New-Item -Path ./Docs -ItemType Directory -Force | Out-Null
$changelog | Set-Content -Path ./Docs/CHANGELOG.md
