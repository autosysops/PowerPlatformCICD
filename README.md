# PowerPlatformCICD

Demo repository for the session *Power in the Pipeline*.
It shows how to treat Power Automate flows like code: every change is checked, documented and described by a GitHub Actions workflow that uses the [PowerPlatformChecker](https://www.powershellgallery.com/packages/PowerPlatformChecker) module.

The module reads unpacked solutions (`pac solution unpack`), so no connection to Dataverse is needed.
All solutions in this repository are made up for the demo.

## Demos

| Workflow | Script | What it shows |
|---|---|---|
| [Demo 1 - Lint the flows](.github/workflows/01-lint-flows.yml) | [01-Test-Flows.ps1](Scripts/01-Test-Flows.ps1) | Fails on default action names and premium connectors, warns on missing secure inputs/outputs and descriptions |
| [Demo 2 - Documentation](.github/workflows/02-documentation.yml) | [02-New-Documentation.ps1](Scripts/02-New-Documentation.ps1) | Generates architecture diagrams and flow charts, and warns about Apply to each loops without an explicit concurrency setting |
| [Demo 3 - AI changelog](.github/workflows/03-ai-changelog.yml) | [03-New-Changelog.ps1](Scripts/03-New-Changelog.ps1) | Turns the solution changes of a pull request into release notes with GitHub Copilot |
| [Bonus demo - External interactions](.github/workflows/04-external-interactions.yml) | [04-New-ExternalInteractionMap.ps1](Scripts/04-New-ExternalInteractionMap.ps1) | Shows which domains the solutions call and which flows are open to the internet |

## Repository layout

```
.github/workflows/   One workflow per demo
Scripts/             The PowerShell used by the workflows
Solutions/           Unpacked demo solutions
  ContosoOrders/     Three flows: one clean, one half renamed, one with several issues
  ContosoShipping/   A webhook flow that calls an external API
```

## Setup for demo 3

Demo 3 uses GitHub Copilot CLI. Create a [fine-grained personal access token](https://github.com/settings/personal-access-tokens/new) with the **Copilot Requests** permission and save it as the repository secret `COPILOT_GITHUB_TOKEN`.

## Running the demos

Each workflow can be started from the **Actions** tab with *Run workflow*. Demos 1 and 3 also run on every pull request that changes a solution.
The results are shown as annotations and as a summary on the run page.
