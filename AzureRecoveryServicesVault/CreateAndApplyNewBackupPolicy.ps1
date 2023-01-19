#Connect-azaccount
$DailyRetention = 8 #days
$WeeklyBackup= 4 #weeks
$MonthlyBackup=3 #months
$WorkloadType= 'AzureVM'
$BackupPolicyName ='tp999rtttMast1'

$Subscriptions = Get-AzSubscription
foreach ($sub in $Subscriptions) {
    Set-AzContext -SubscriptionName $sub
    $rsvlist= Get-AzRecoveryServicesBackupProtectionPolicy | Select-Object Name
          
        If ($rsvlist -contains $BackupPolicyName) {
            Write-Host "$BackPolicyName is already present in Subscription> $sub"    }
        
            else {
                    Write-Host "`nCreating Policy>> $BackupPolicyName in Subscription==" $sub.Name 
                    $SchPol = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType $WorkloadType
                    $SchPol.ScheduleRunTimes.Clear()
                    $timeZone = Get-TimeZone
                    $SchPol.ScheduleRunTimeZone = $timeZone.Id
                    #$startTime = Get-Date -Date "2021-12-22T06:00:00.00+00:00"

                    $Dt= Get-Date -Hour 1 -Minute 00 -Second 0 -Year 2023 -Day 19 -Month 1 -Millisecond 0
                    $Dt = [DateTime]::SpecifyKind($Dt,[DateTimeKind]::Utc)
                    $SchPol.ScheduleRunTimes.Add($Dt)

                    #Getting a Base Backup Retention Policy object
                    $RetPol = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType $WorkloadType -ScheduleRunFrequency  Daily

                    Write-Host "`nSet Daily Schedule for $DailyRetention days..."
                    $RetPol.DailySchedule.DurationCountInDays = $DailyRetention

                    Write-Host "Set Weekly Schedule for $WeeklyBackup weeks, every Saturday"
                    $RetPol.WeeklySchedule.DaysOfTheWeek = "Saturday"
                    $RetPol.WeeklySchedule.DurationCountInWeeks = $WeeklyBackup


                    Write-Host "Set Monthly Schedule for $MonthlyBackup months..."
                    $RetPol.MonthlySchedule.DurationCountInMonths = $MonthlyBackup
                    $RetPol.MonthlySchedule.RetentionScheduleFormatType= 'Daily'
                    #$retpol.MonthlySchedule.RetentionScheduleDaily.DaysOfTheMonth= $MonthlyDays
                    $retpol.MonthlySchedule.RetentionScheduleDaily.DaysOfTheMonth[0].Date=0
                    $retpol.MonthlySchedule.RetentionScheduleDaily.DaysOfTheMonth[0].IsLast=$true


                    Write-Host "No Yearly Schedule set"
                    $RetPol.IsYearlyScheduleEnabled= $false

                    #Setting Azure Recovery Services Vault Context
                    Get-AzRecoveryServicesVault -Name $RSVaultName | Set-AzRecoveryServicesVaultContext

                    $ProtectionPolicy = New-AzRecoveryServicesBackupProtectionPolicy -Name $BackupPolicyName `
                    -WorkloadType $WorkloadType -RetentionPolicy $RetPol -SchedulePolicy $SchPol

             }
         }



