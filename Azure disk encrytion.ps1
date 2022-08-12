Connect-AzAccount
Write-Host "Creating Folder >> 'C:\DiskDetails'  All reports from this PS will be stored here" -fore green
New-Item "C:\DiskDetails" -itemType Directory

            $isreg=Get-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute" 

            if ($isreg.RegistrationState -eq 'NotRegistered')
            { 
            Register-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"
            Write-Host "Enabling Feature -> EncryptionAtHost for Subcription, please wait for ~15mins" -fore green
            Start-Sleep -Seconds 1500
            }
            $isreg=Get-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"
            echo $isreg.RegistrationState

$vms = @();
$output=@();
$vms=Get-Azvm

foreach ($vm in $vms)
{
$diskStats = Get-AzVMDiskEncryptionStatus -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name
$obj = [pscustomobject]@{"MachineName" = ($vm.Name)
                        "OSVolumeEncrypted" = ($diskStats.OSVolumeEncrypted)
                        "DataVolumesEncrypted" = ($diskStats.DataVolumesEncrypted)
                        }
                        
$output+= $obj
}

$output | Export-Csv -Path C:\Diskdetails\VMDisk.csv -NoTypeInformation

#KeyVault Section
Write-Host "Enter the KeyVault Name Ex. MyKeyVault1" -ForegroundColor Green
$kvn = Read-Host 
Write-Host "Enter the ResourceGroup Name that contains KeyVault Ex. MyRG1"  -fore green
$rgn = Read-Host
Write-Host "Enter the key Name"  -fore green
$key = Read-Host

Write-Host "Selected KeyVault '$kvn' , Resource Group '$rgn', Key Name '$key'" -ForegroundColor YELLOW


$KeyVault = Get-AzKeyVault -VaultName $kvn -ResourceGroupName $rgn
$keyEncryptionKeyUrl = (Get-AZKeyVaultKey -VaultName $kvn -Name $key).Key.kid;


$nvm= Import-Csv -Path C:\Diskdetails\VMDisk.csv

foreach ($item in $nvm)
{
    if ($item.OSVolumeEncrypted -eq 'NotEncrypted' -and $item.DataVolumesEncrypted -eq 'NotEncrypted')
        {
        Write-Host "VM>> $item.MachineName Both disks needs to be encrypted, will take ~10-15mins..."  -fore green
        Set-AzVMDiskEncryptionExtension -ResourceGroupName $rgn -VMName $item.MachineName -DiskEncryptionKeyVaultUrl $KeyVault.VaultUri -DiskEncryptionKeyVaultId $KeyVault.ResourceId -KeyEncryptionKeyUrl $keyEncryptionKeyUrl -KeyEncryptionKeyVaultId $KeyVault.ResourceId -VolumeType All -Force
        Write-Host "Script/ PS Session will end after 2mins"
        #Start-Sleep -Seconds 120
        exit   
        }
    elseif($item.OSVolumeEncrypted -eq 'NotEncrypted')
    {
    Write-Host "VM>> $item.MachineName OS disk needs to be encrypted, will take ~10-15mins..."  -fore green
    Set-AzVMDiskEncryptionExtension -ResourceGroupName $rgn -VMName $item.MachineName -DiskEncryptionKeyVaultUrl $KeyVault.VaultUri -DiskEncryptionKeyVaultId $KeyVault.ResourceId -KeyEncryptionKeyUrl $keyEncryptionKeyUrl -KeyEncryptionKeyVaultId $KeyVault.ResourceId -VolumeType Os -Confirm:$false
    }

    elseif($item.DataVolumesEncrypted -eq 'NotEncrypted')
    {
    Write-Host "VM>> $item.MachineName Data disks needs to be encrypted, will take ~10-15mins..."  -fore green
    Set-AzVMDiskEncryptionExtension -ResourceGroupName $rgn -VMName $item.MachineName -DiskEncryptionKeyVaultUrl $KeyVault.VaultUri -DiskEncryptionKeyVaultId $KeyVault.ResourceId -KeyEncryptionKeyUrl $keyEncryptionKeyUrl -KeyEncryptionKeyVaultId $KeyVault.ResourceId -VolumeType Data -Confirm:$false
    }

}



