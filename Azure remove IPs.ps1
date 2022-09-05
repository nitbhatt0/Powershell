Set-AzContext -Subscription ""

$ips= Import-Csv -Path C:\Users\nitbhatt\Downloads\export_data.csv

foreach ($item in $ips)
{
Remove-AzPublicIpAddress -Name $item.IPName -ResourceGroupName $item.PIPRG -Force
}

