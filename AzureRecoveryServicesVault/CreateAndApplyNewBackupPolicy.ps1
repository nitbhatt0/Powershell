Connect-azaccount
$DailyRetention = 8 #days
$WeeklyBackup= 4 #weeks
$MonthlyBackup=3 #months
$WorkloadType= 'AzureVM'
$BackupPolicyName ='test9996'

$Subscriptions = Get-AzSubscription

foreach ($sub in $Subscriptions) {
    Set-AzContext -SubscriptionName $sub
    
    $rsvs= Get-AzRecoveryServicesVault
    foreach ($rsv in $rsvs)  {
            Get-AzRecoveryServicesVault -Name $rsv.Name | Set-AzRecoveryServicesVaultContext            
            $rsvpollist= Get-AzRecoveryServicesBackupProtectionPolicy | Select-Object Name
        
            If ($rsvpollist -contains $BackupPolicyName) {
            Write-Host "$BackPolicyName is already present in Subscription>>" $sub.Name    }
        
            else {
                    Write-Host "`nCreating Policy>>" $BackupPolicyName "Subscription>>" $sub.Name "Vault>>"$rsv.Name -ForegroundColor Green
                    $SchPol = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType $WorkloadType
                    $SchPol.ScheduleRunTimes.Clear()
                    $timeZone = Get-TimeZone
                    $SchPol.ScheduleRunTimeZone = $timeZone.Id
                    $Dt= Get-Date -Hour 1 -Minute 00 -Second 0 -Year 2023 -Day 19 -Month 1 -Millisecond 0
                    $Dt = [DateTime]::SpecifyKind($Dt,[DateTimeKind]::Utc)
                    $SchPol.ScheduleRunTimes.Add($Dt)

                    #Getting a Base Backup Retention Policy object
                    $RetPol = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType $WorkloadType -ScheduleRunFrequency  Daily

                    Write-Host "`nSet Daily Schedule for $DailyRetention days..." -ForegroundColor Yellow
                    $RetPol.DailySchedule.DurationCountInDays = $DailyRetention

                    Write-Host "Set Weekly Schedule for $WeeklyBackup weeks, every SATURDAY" -ForegroundColor Yellow
                    $RetPol.WeeklySchedule.DaysOfTheWeek = "Saturday"
                    $RetPol.WeeklySchedule.DurationCountInWeeks = $WeeklyBackup


                    Write-Host "Set Monthly Schedule for $MonthlyBackup months..." -ForegroundColor Yellow
                    $RetPol.MonthlySchedule.DurationCountInMonths = $MonthlyBackup
                    $RetPol.MonthlySchedule.RetentionScheduleFormatType= 'Daily'
                    $retpol.MonthlySchedule.RetentionScheduleDaily.DaysOfTheMonth[0].Date=0
                    $retpol.MonthlySchedule.RetentionScheduleDaily.DaysOfTheMonth[0].IsLast=$true


                    Write-Host "No Yearly Schedule set.." -ForegroundColor Red
                    $RetPol.IsYearlyScheduleEnabled= $false

                    $ProtectionPolicy = New-AzRecoveryServicesBackupProtectionPolicy -Name $BackupPolicyName `
                    -WorkloadType $WorkloadType -RetentionPolicy $RetPol -SchedulePolicy $SchPol

             }
         }
        }



