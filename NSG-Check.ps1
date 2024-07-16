
# Import modules
Import-Module Az.Accounts
Import-Module Az.Network
$tenant = '<Tenant ID>'
$ipAddress = Read-Host -Prompt 'Enter the IP address you would like to check inbound rules from, e.g 0.0.0.0'

# Check if already authenticated
if (Get-AzContext -ListAvailable) {
    Write-Output "AZ-Account Connected`r`n"
} else {
    # Login to Azure account
    Connect-AzAccount -TenantID $tenant
}

# Get the list of all subscriptions
$subscriptions = Get-AzSubscription -TenantID $tenant

Write-Host "Checking NSGs in subscriptions: " -ForegroundColor Green

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    # Set the current subscription
    Set-AzContext -Subscription $subscription.Id -TenantID $tenant

    # Get the list of all NSGs
    $NSGs = Get-AzNetworkSecurityGroup

    # Loop through each NSG and check the rules
    foreach ($NSG in $NSGs) {
        $rules = $NSG.SecurityRules
        foreach ($rule in $rules) {
            # Check if the rule allows access from the specified Ip Address
            if ($rule.SourceAddressPrefix -eq $ipAddress) {
                Write-Host "NSG $($NSG.Name) has a rule $($rule.Name) that allows access from $ipaddress in $($subscription.name)" -ForegroundColor Red
            }
        }
    }
}
