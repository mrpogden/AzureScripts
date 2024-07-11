# A quick script to cycle through all storage accounts in a tenant or subscription to look for any that allow public access


# Import the required module
Import-Module Az.Accounts

# Check if already authenticated
if (Get-AzContext -ListAvailable) {
    Write-Output "AZ-Account Connected"
} else {
    # Login to Azure account
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

# Function to check storage accounts
function Check-StorageAccounts ($subscription) {
    # Select the subscription
    Select-AzSubscription -SubscriptionId $subscription.Id

    # Get all storage accounts in the subscription
    $storageAccounts = Get-AzStorageAccount

    # Iterate over each storage account
    foreach ($storageAccount in $storageAccounts) {
        try {
            # Get the network rule set of the storage account
            $networkRuleSet = Get-AzStorageAccountNetworkRuleSet -ResourceGroupName $storageAccount.ResourceGroupName -Name $storageAccount.StorageAccountName
        }
        catch {
            Write-Output "Error retrieving network rule set for storage account: $($storageAccount.StorageAccountName)"
            continue
        }

        # Check if the storage account has public access enabled
        if ($networkRuleSet.DefaultAction -eq 'Allow') {
            $output = "Storage Account: $($storageAccount.StorageAccountName), Default Network Access: Allow"
            
            # Output the results based on the menu choice
            if ($outputOption -eq '1') {
                Write-Output $output
            }
            else {
                $fileName = $subscription.Name.Replace(" ", "_") + ".txt"
                Add-Content -Path $fileName -Value $output
            }
        }
    }
}

# Check the storage accounts based on the menu choice
if ($selectedSubscriptionIndex -le $subscriptions.Count) {
    Check-StorageAccounts -subscription $subscriptions[$selectedSubscriptionIndex - 1]
}
else {
    foreach ($subscription in $subscriptions) {
        Check-StorageAccounts -subscription $subscription
    }
}
