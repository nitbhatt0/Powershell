Connect-AzAccount
$rg= "<ResourceGroup Name>"
$rsv= "<Name of the Recovery service vault>"
$vms = Get-AzVM
$backupVaults = Get-AzRecoveryServicesVault
$outputs=@();
$targetpolicy= "<Target Backup Policy Name"

Get-AzRecoveryServicesVault  -Name "$rsv" | Set-AzRecoveryServicesVaultContext

#VM protection Status
 
 foreach ($vm in $vms) 
{
        $recoveryVaultInfo = Get-AzRecoveryServicesBackupStatus -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Type 'AzureVM'

 if ($recoveryVaultInfo.BackedUp -eq $true)
        {
            $vmBackupVault = $backupVaults | Where-Object {$_.ID -eq $recoveryVaultInfo.VaultId}
            $container = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM -VaultId $vmBackupVault.ID -FriendlyName $vm.Name #-Status "Registered" 
            $backupItem = Get-AzRecoveryServicesBackupItem -Container $container -WorkloadType AzureVM -VaultId $vmBackupVault.ID

            $obj = [pscustomobject]@{ 
                  "VMName" = ($vm.Name)   
                  "ARSVaultName" = ($vmBackupVault.Name)    
                  "BackupPolicyName"=($backupItem.ProtectionPolicyName)    
                                     }    
              $outputs+= $obj

        } 
else 
        {
            Write-Host "$($vm.Name) - BackedUp : No" -BackgroundColor DarkRed
            $vmBackupVault = $null
            $container =  $null
            $backupItem =  $null
        } 
}

#ASRVault remains the same, only Backup policy is changed.
$TargetPol1 = Get-AzRecoveryServicesBackupProtectionPolicy -Name $targetpolicy -VaultId $Vault.ID
foreach ($output in $outputs)
{
    $anotherBkpItem = Get-AzRecoveryServicesBackupItem -WorkloadType AzureVM -BackupManagementType AzureVM -Name $output.VMName -VaultId $Vault.ID
    Enable-AzRecoveryServicesBackupProtection -Item $anotherBkpItem -Policy $TargetPol1 -VaultId $Vault.ID
}