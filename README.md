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

## Importing ContosoOrders

The repository demos only analyze files; they do not require importing either solution or provisioning external services.
To import ContosoOrders, use a Power Platform environment with Dataverse and an account permitted to import solutions and configure connection references (for example, a System Administrator in a dedicated demo environment).
The flows are packaged as drafts so they do not start scheduled jobs, delete items or send emails immediately after import.

1. Install Power Platform CLI and package the unpacked solution from the repository root:

  ```powershell
  pac solution pack --folder ./Solutions/ContosoOrders --zipfile ./ContosoOrders.zip --packagetype Unmanaged
  ```

2. In the target environment, create authenticated connections for SharePoint, Office 365 Outlook and SQL Server. A working SQL connection requires a reachable server and valid credentials; an on-premises or private server may require an on-premises data gateway.
3. In Power Apps, open **Solutions > Import solution**, select the ZIP and map the following connection references. The ZIP contains the references, not credentials or authenticated connections.

  | Connection Reference | Connector | Access Needed When Running |
  |---|---|---|
  | `contoso_sharedsharepointonline` | SharePoint | Read and delete items in the demo list |
  | `contoso_sharedoffice365` | Office 365 Outlook | A mailbox permitted to send email |
  | `contoso_sharedsql` | SQL Server | Read access to the demo table |

4. Set the string environment variable **Erp Base Url** (`contoso_ErpBaseUrl`) to your test API base URL, without a trailing slash. Its default, `https://erp.contoso.example/api`, is a non-working placeholder. Leave the flows off until their resource settings are updated.

The target environment's data policies must permit the connector combination. Running the SQL Server and HTTP actions requires appropriate Power Automate premium licensing.
Importing drafts does not provision SharePoint lists, SQL tables or an ERP API. Connector checks during setup or activation may require those resources to be reachable.

### Resources Needed to Run the Flows

| Resource | Required Configuration |
|---|---|
| SharePoint site | Replace `https://contoso.sharepoint.com/sites/Sales` in the notification trigger and every SharePoint action with your test site. |
| SharePoint list | Create an `Orders` list, then reselect it in every trigger/action so the stored list identifier matches your environment. Keep the built-in `ID` and `Title` fields. Add a text or single-choice column with internal name `Status`, allowing `Expired`. |
| SQL Server | Replace `sql.contoso.example` with a reachable SQL Server. Use a database named `Orders` and a table `[dbo].[Orders]`, or reselect your own database/table in **Get rows (V2)**. |
| SQL columns | The flow does not reference individual columns: it sends each complete row to the API. A primary key such as `OrderId` plus `Title` and `Status` is sufficient for a simple demo table; match the columns to your API's expected payload. |
| ERP API | Provide an endpoint accepting `POST {Erp Base Url}/orders` with one SQL row as its JSON body. The HTTP action currently has no authentication configured; add it if your test API requires it. |
| Email recipients | Replace `sales@contoso.example` and `it@contoso.example` with test recipients. |

The notification flow checks for new SharePoint items every five minutes; cleanup runs daily; ERP synchronization runs hourly.
SharePoint and SQL orders are independent demo data sources: there is no flow copying records between them.
ERP synchronization sends all returned SQL rows on every run and does not mark them as synchronized, so use disposable data or an API that tolerates repeat submissions.

**Cleanup warning:** the cleanup flow deletes only the first item whose `Status` is `Expired` and has no empty-result guard. It intentionally retains demo issues; leave it disabled unless you are testing that behavior against a disposable list.

The package has been checked locally with PAC pack/unpack. A successful import into your target Dataverse environment is still required to confirm server-side acceptance; packaging alone cannot prove it.
