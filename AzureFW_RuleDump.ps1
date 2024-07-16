# Set up your import CSV by navigating to https://portal.azure.com/#browse/all
#filtering 'Type = Firewall Policy' 
#manage view so only Name, Resource group and Subscription are showing. 
#Export CSV
# Import the CSV file
$csvData = Import-Csv -Path "<Location of exported CSV file>"
foreach ($row in $csvData) {
    Set-AzContext -Subscription $row.'SUBSCRIPTION' # optional -Tenant <Tennant ID if you have multiple tenants>
    $rg = $row.'RESOURCE GROUP'
    $policyname = $row.'NAME'
    $csv_path = "<Location for output>"
   

    # Fetch rule collection groups
    $colgroups = Get-AzFirewallPolicy -Name $policyname -ResourceGroupName $rg

    foreach ($colgroup in $colgroups.RuleCollectionGroups) {
        $c = Out-String -InputObject $colgroup -Width 500
        $collist = $c -split "/"
        $colname = ($collist[-1]).Trim()

        $rulecolgroup = Get-AzFirewallPolicyRuleCollectionGroup -Name $colname -ResourceGroupName $rg -AzureFirewallPolicyName $policyname

        if ($rulecolgroup.properties.RuleCollection.rules.RuleType -contains "NetworkRule") {
            $rulecolgroup.properties.RuleCollection.rules | Select-Object Name, RuleType, `
                @{n="SourceAddresses";e={$_.SourceAddresses -join ","}}, `
                @{n="protocols";e={$_.protocols -join ","}}, `
                @{n="DestinationAddresses";e={$_.DestinationAddresses -join ","}}, `
                @{n="SourceIpGroups";e={$_.SourceIpGroups -join ","}}, `
                @{n="DestinationIpGroups";e={$_.DestinationIpGroups -join ","}}, `
                @{n="DestinationPorts";e={$_.DestinationPorts -join ","}}, `
                @{n="DestinationFqdns";e={$_.DestinationFqdns -join ","}} | Export-Csv -Path "$csv_path\$policyname.NetworkRules.csv" -Append -NoTypeInformation -Force
        }

        if ($rulecolgroup.properties.RuleCollection.rules.RuleType -contains "ApplicationRule") {
            $rulecolgroup.properties.RuleCollection.rules | Select-Object Name, RuleType, TerminateTLS, `
                @{n="SourceAddresses";e={$_.SourceAddresses -join ","}}, `
                @{n="TargetFqdns";e={$_.TargetFqdns -join ","}}, `
                @{n="Protocols";e={$_.Protocols -join ","}}, `
                @{n="SourceIpGroups";e={$_.SourceIpGroups -join ","}}, `
                @{n="WebCategories";e={$_.WebCategories -join ","}}, `
                @{n="TargetUrls";e={$_.TargetUrls -join ","}} | Export-Csv -Path "$csv_path\$policyname.ApplicationRules.csv" -Append -NoTypeInformation -Force
        }
    }
}
