# AzureDevOpsBoardCLIScripts

Useful scripts for automating common tasks in Azure DevOps taskboards and work items using Azure CLI and PowerShell.

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) with the Azure DevOps extension installed (`az extension add --name azure-devops`)
- PowerShell

**Note:** You must be logged in to Azure DevOps (`az login`) and set the correct default organization/project context before running these scripts.

## Scripts

### 1. `createItems.ps1`

Automates creation of Azure DevOps work items and relations based off a JSON config file, supporting default values (which can be universally applied and replaced without touching main work item template configs) and recursive related-item new item creation.

#### Usage

```powershell
.\createItems.ps1 [-workItemsPath] <filepath> [-Silent]
```

- `-workItemsPath`: Path to the JSON file describing work items.
- `-Silent`: (Optional) Suppresses informative output.

#### Example
```powershell
.\createItems.ps1 workItems.json
```

#### Example JSON Structure

```json
{
  "default": {
    "area": "Area\\Path",
    "iteration": "Org\\SprintNumber",
    "assignedTo": "userAlias"
  },
  "workItems": [
    {
      "title": "New Task 1",
      "type": "Task",
      "relations": [
        {
          "type": "Parent",
          "existingId": 123456
        },
        {
          "type": "Child",
          "newItem": {
            "title": "Child Task 1",
            "type": "Task",
            "iteration": "Org\\NextSprint"
          }
        }
      ]
    }
  ]
}
```

- `default`: (Optional) Default values for work items.
- `workItems`: Array of work item objects.
  - `title`, `type`, `area`, `iteration`, `assignedTo`, `description`, `fields`: Standard work item fields. (See linked CLI documentation in references below)
  - `relations`: (Optional) Array of relation objects:
    - `type`: Relation type (e.g., `Parent`, `Child`, `Related`, etc.).
    - `existingId`: ID of an existing work item to relate to.
    - `newItem`: Inline definition of a new related work item to also be created with relation created.

### 2. `moveChildItems.ps1`

Moves all child work items from one parent to another.

#### Usage

```powershell
.\moveChildItems.ps1 [-SourceWorkItemId] <id> [-DestinationWorkItemId] <id>
```

- `-SourceWorkItemId`: ID of the current parent work item.
- `-DestinationWorkItemId`: ID of the new parent work item.

## References
- [Azure CLI Reference: DevOps > `boards` > `work-item`](https://learn.microsoft.com/en-us/cli/azure/boards/work-item?view=azure-cli-latest)