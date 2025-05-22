param (
    [Parameter(Mandatory = $true)][string]$workItemsPath,
    [switch]$Silent
)

if (-not (Test-Path $workItemsPath)) {
    Write-Error "Input JSON file not found: $workItemsPath"
    exit 1
}

# Load work items from JSON
$workItemsObj = Get-Content $workItemsPath | ConvertFrom-Json

# Extract default values from JSON
$default = $workItemsObj.default

function New-WorkItemRecursive {
    param (
        [Parameter(Mandatory = $true)]$item,
        [switch]$Silent
    )
    # Use default values if not specified in the item
    $itemTitle = if ($item.title) { $item.title } elseif ($default.title) { $default.title } else { $null }
    $itemType = if ($item.type) { $item.type } elseif ($default.type) { $default.type } else { $null }
    $itemArea = if ($item.area) { $item.area } elseif ($default.area) { $default.area } else { $null }
    $itemAssignedTo = if ($item.assignedTo) { $item.assignedTo } elseif ($default.assignedTo) { $default.assignedTo } else { $null }
    $itemDescription = if ($item.description) { $item.description } elseif ($default.description) { $default.description } else { $null }
    $itemIteration = if ($item.iteration) { $item.iteration } elseif ($default.iteration) { $default.iteration } else { $null }

    $azArgs = @("--output", "json")
    if ($itemTitle)      { $azArgs += @("--title", $itemTitle) }
    if ($itemType)       { $azArgs += @("--type", $itemType) }
    if ($itemArea)       { $azArgs += @("--area", $itemArea) }
    if ($itemAssignedTo) { $azArgs += @("--assigned-to", $itemAssignedTo) }
    if ($itemDescription){ $azArgs += @("--description", $itemDescription) }
    if ($itemIteration)  { $azArgs += @("--iteration", $itemIteration) }

    if ($item.fields) {
        foreach ($key in $item.fields.PSObject.Properties.Name) {
            $azArgs += "--fields"
            $azArgs += "$key=$($item.fields.$key)"
        }
    }

    $createdItem = az boards work-item create @azArgs | ConvertFrom-Json

    $createdItemId = $createdItem.id
    if (-not $Silent) { Write-Host "Created work item: $createdItemId ($itemTitle)" }

    # Process relations recursively if any
    if ($item.relations) {
        foreach ($rel in $item.relations) {
            if ($rel.existingId) {
                az boards work-item relation add `
                    --id $createdItemId `
                    --relation-type $rel.type `
                    --target-id $rel.existingId | Out-Null
                if (-not $Silent) { Write-Host "Linked work items: $createdItemId -> $($rel.existingId) (Relation: $($rel.type))" }
            }
            elseif ($rel.newItem) {
                $relatedItem = New-WorkItemRecursive -item $rel.newItem -Silent:$Silent
                $relatedItemId = $relatedItem.id
                az boards work-item relation add `
                    --id $createdItemId `
                    --relation-type $rel.type `
                    --target-id $relatedItemId | Out-Null
                if (-not $Silent) { Write-Host "Linked work items: $createdItemId -> $relatedItemId (Relation: $($rel.type))" }
            }
        }
    }
    return $createdItem
}

foreach ($item in $workItemsObj.workItems) {
    New-WorkItemRecursive -item $item -Silent:$Silent | Out-Null
}