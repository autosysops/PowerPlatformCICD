# PowerPlatformCICD

Demo repository for the session *Power in the Pipeline*.
It shows how to treat Power Automate flows like code: every change is checked, documented and described by a GitHub Actions workflow that uses the [PowerPlatformChecker](https://www.powershellgallery.com/packages/PowerPlatformChecker) module.

The module reads unpacked solutions (`pac solution unpack`), so no connection to Dataverse is needed.
All solutions in this repository are made up for the demo.

## Demos

| Workflow | Script | What it shows |
|---|---|---|
| [Demo 1 - Default action names](.github/workflows/01-default-action-names.yml) | [01-Test-ActionNames.ps1](Scripts/01-Test-ActionNames.ps1) | Fails when actions are not renamed (`Apply_to_each`, `HTTP`, ...) |
| [Demo 2 - Connectors and parameters](.github/workflows/02-connectors-and-parameters.yml) | [02-Test-ConnectorsAndParameters.ps1](Scripts/02-Test-ConnectorsAndParameters.ps1) | Fails on premium connectors, warns on missing descriptions |
| [Demo 3 - Documentation](.github/workflows/03-documentation.yml) | [03-New-Documentation.ps1](Scripts/03-New-Documentation.ps1) | Generates architecture diagrams and flow charts |
| [Demo 4 - AI changelog](.github/workflows/04-ai-changelog.yml) | [04-New-Changelog.ps1](Scripts/04-New-Changelog.ps1) | Turns the solution changes of a pull request into release notes |
| [Bonus demo - External interactions](.github/workflows/05-external-interactions.yml) | [05-New-ExternalInteractionMap.ps1](Scripts/05-New-ExternalInteractionMap.ps1) | Shows which domains the solutions call and which flows are open to the internet |

## Repository layout

```
.github/workflows/   One workflow per demo
Scripts/             The PowerShell used by the workflows
Solutions/           Unpacked demo solutions
  ContosoOrders/     Three flows: one clean, one half renamed, one with several issues
  ContosoShipping/   A webhook flow that calls an external API
```

## Setup for demo 4

Demo 4 calls an Azure OpenAI deployment. Add these repository secrets:

- `AZURE_OPENAI_ENDPOINT` (for example `https://my-resource.openai.azure.com`)
- `AZURE_OPENAI_KEY`
- `AZURE_OPENAI_DEPLOYMENT` (the name of your chat model deployment)

## Running the demos

Each workflow can be started from the **Actions** tab with *Run workflow*. Demos 1, 2 and 4 also run on every pull request that changes a solution.
The results are shown as annotations and as a summary on the run page.
