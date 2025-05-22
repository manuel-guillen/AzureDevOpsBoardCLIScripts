param (
    [Parameter(Mandatory = $true)][int]$SourceWorkItemId,
    [Parameter(Mandatory = $true)][int]$DestinationWorkItemId
)

# Implementation to move child items will go here.
$sourceRelations = az boards work-item relation show --id $SourceWorkItemId | ConvertFrom-Json
$sourceChildIds = $sourceRelations.relations 
                  | Where-Object { $_.rel -eq "Child" } 
                  | Select-Object -ExpandProperty url
                  | ForEach-Object { $_.Split("/")[-1] }

foreach ($childId in $sourceChildIds) {
    # Move each child item to the new parent
    az boards work-item relation remove `
        --id SourceWorkItemId `
        --relation-type "Child" `
        --target-id $childId | Out-Null
    az boards work-item relation add `
        --id $DestinationWorkItemId `
        --relation-type "Child" `
        --target-id $childId | Out-Null
    Write-Host "Moved item $childId to parent: $DestinationWorkItemId"
}