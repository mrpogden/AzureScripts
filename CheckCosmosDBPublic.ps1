# Import Modules
Import-Module Az.Accounts

# Check if already authenticated
if (Get-AzContext -ListAvailable) {
    Write-Output "AZ-Account Connected"
} else {
    # Login to the Azure account if no token exists
    Connect-AzAccount
}

# Get all subscriptions in the tenant
$subscriptions = Get-AzSubscription

# Display a menu to choose a subscription
Write-Output "Please select a subscription:"
for ($i=0; $i -lt $subscriptions.Count; $i++) {
    Write-Output "$($i+1): $($subscriptions[$i].Name)"
}
Write-Output "$($subscriptions.Count+1): All Subscriptions"
$selectedSubscriptionIndex = Read-Host -Prompt 'Enter the number of the subscription'

# Ask where to output the results
Write-Output "Please select an output option:"
Write-Output "1: Display on screen"
Write-Output "2: Send to a .txt file"
$outputOption = Read-Host -Prompt 'Enter the number of the output option'
# Function to check Cosmos DB accounts
function Check-CosmosDBAccounts ($subscription) {
    # Select the subscription
    Select-AzSubscription -SubscriptionId $subscription.Id

    # Get all resource groups in the subscription
    $resourceGroups = Get-AzResourceGroup

    # Iterate over each resource group
    foreach ($resourceGroup in $resourceGroups) {
        # Get all the Cosmos DB accounts in the resource group
        $cosmosDBAccounts = Get-AzCosmosDBAccount -ResourceGroupName $resourceGroup.ResourceGroupName

        # Iterate over each Cosmos DB account
        foreach ($cosmosDbAccount in $cosmosDbAccounts) {
            Write-Host "Checking Cosmos DB account: $($cosmosDbAccount.Name)"
    
            # Check for public network access
            $publicNetworkAccess = $cosmosDbAccount.PublicNetworkAccess
            Write-Host "Public Network Access: $publicNetworkAccess"
    
            # Check IP firewall rules
            $ipRules = $cosmosDbAccount.IpRules
            if ($ipRules.Count -eq 0) {
                Write-Host "No IP firewall rules set."
            } else {
                Write-Host "IP firewall rules:"
                $ipRules | ForEach-Object { Write-Host $_.IpAddressOrRange }
            }
    
            # Check Virtual Network Rules
            $vNetRules = $cosmosDbAccount.VirtualNetworkRules
            if ($vNetRules.Count -eq 0) {
                Write-Host "No Virtual Network rules set."
            } else {
                Write-Host "Virtual Network rules:"
                $vNetRules | ForEach-Object { Write-Host $_.Id }
            }
    
            # Check if Azure public data center access is enabled
            $allowAzureAccess = $cosmosDbAccount.EnableAutomaticFailover
            Write-Host "Azure public data center access enabled: $allowAzureAccess"
        }
            
    }
}


# Check the Cosmos DB accounts based on the menu choices
if ($selectedSubscriptionIndex -le $subscriptions.Count) {
    Check-CosmosDBAccounts -subscription $subscriptions[$selectedSubscriptionIndex - 1]
}
else {
    foreach ($subscription in $subscriptions) {
        Check-CosmosDBAccounts -subscription $subscription
    }
}
