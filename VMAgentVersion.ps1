#Connect-AzAccount

$subs=Get-AzSubscription | Sort Name | Select Name
foreach ($sub in $subs)
{
Set-AzContext -SubscriptionName $sub.Name | Out-null
#$subname= (Get-AzSubscription -SubscriptionId $subid).Name
$vms = Get-AzVM
Write-Host "`n Subscription Name $($sub.Name)"
foreach ($vm in $vms) 
    {
        $azvm = Get-AzVM -Name $vm
        #$subid = ($azvm.Id -split '/')[2]
        #$subname= (Get-AzSubscription -SubscriptionId $subid).Name
        $vmStatus = Invoke-AzRestMethod -Path ('{0}/instanceView?api-version=2020-06-01' -f $vm.Id) -Method GET | 
                            Select-Object -ExpandProperty Content | ConvertFrom-Json
          
               if ($vmStatus.vmAgent.statuses.displayStatus -ne "Ready") {
                Write-Host "$($vm.Name) is missing an agent"
            } else {
                Write-Host "$($vm.Name) is running agent version $($vmStatus.vmAgent.vmAgentVersion)"
            }
      }
}