<######################################################################
Exchange Task Menu

v2.1    29th July 2016:    Created by NOC 

<#
.SYNOPSIS
    Exchange Tools Menu
.DESCRIPTION
    Script uses menu options to launch various exchange tools for three datacenters. Note this version has been scrubbed and would corrections to work.
	Orginial Script menu http://chucklindblom.com/creating-a-simple-menu-in-powershell/
#>


######################################################################>
$xAppName    = "Menu"
[BOOLEAN]$Script:xExitSession=$false
function LoadMenuSystem(){
	[INT]$xMenu1=0
	[INT]$xMenu2=0
	[BOOLEAN]$xValidSelection=$false
	while ( $xMenu1 -lt 1 -or $xMenu1 -gt 6 ){
		CLS
		#… Present the Menu Options
		Write-Host "`n`t NOC Exchange Tools and Information - Version 2.1`n" -ForegroundColor Magenta
		Write-Host "`t`tPlease select the desired Datacenter`n" -Fore Cyan
		Write-Host "`t`t`t1. ADC" -Fore Cyan
		Write-Host "`t`t`t2. EDC" -Fore Cyan
		Write-Host "`t`t`t3. PDC" -Fore Cyan
		Write-Host "`t`t`t4. SDC" -Fore Cyan
		Write-Host "`t`t`t5. Global" -Fore Cyan
		Write-Host "`t`t`t6. Quit and exit`n" -Fore Cyan
		#… Retrieve the response from the user
		[int]$xMenu1 = Read-Host "`t`tEnter Menu Option Number"
		if( $xMenu1 -lt 1 -or $xMenu1 -gt 6 ){
			Write-Host "`tPlease select one of the options available.`n" -Fore Red;start-Sleep -Seconds 1
		}
	}
	Switch ($xMenu1){    #… User has selected a valid entry.. load next menu
		1 {
			while ( $xMenu2 -lt 1 -or $xMenu2 -gt 14 ){
				CLS
				# Present the Menu Options
				Write-Host "`n`tAsian Datacenter (ADC) Exchange Tools and Information`n" -Fore Magenta
				Write-Host "`t`t>>>>  Single Server and CAS Server need to be ran for a complete Email List  <<<<" -Fore Red
				Write-Host "`t`t      Single Server" -Fore Red -nonewline; Write-Host " for mailboxes house on the affected server" -Fore Yellow
                Write-Host "`t`t      CAS Server" -Fore Red -nonewline; Write-Host " for client connections through the affected server`n" -Fore Yellow
                Write-Host "`t`t`t1. Single User Information (On Screen)" -Fore Cyan
				Write-Host "`t`t`t2. Single Database Email List (Email Report)" -Fore Cyan
				Write-Host "`t`t`t3. Single Server Email List (Email Report)" -Fore Cyan
				Write-Host "`t`t`t4. CAS Server Email List (Email Report)" -Fore Cyan
                Write-Host "`t`t`t5. Database Locations (On Screen)" -Fore Cyan
                Write-Host "`t`t`t6. Database Health Check (Email Report)" -Fore Cyan
                Write-Host "`t`t`t7. Check Quorm State and move PAM" -Fore Cyan
                Write-Host "`t`t`t8. Exchange Overall Health (Email Report)" -Fore Cyan
                Write-Host "`t`t`t9. DAG Layout (Email Report)" -Fore Cyan
                Write-Host "`t`t`t10. Check Mailbox Queues" -Fore Cyan
                Write-Host "`t`t`t11. Check Activation Policy" -Fore Cyan
                Write-Host "`t`t`t12. Change Activation Policy to Blocked"-Fore Cyan -nonewline; Write-Host " (Run command before patching or reboot)" -Fore Red
                Write-Host "`t`t`t13. Change Activation Policy to Unrestricted"-Fore Cyan -nonewline; Write-Host " (Run command once patching or reboot is completed)" -Fore Red
                Write-Host "`t`t`t14. Go to Main Menu`n" -Fore Cyan
				[int]$xMenu2 = Read-Host "`t`tEnter Menu Option Number"
				if( $xMenu2 -lt 1 -or $xMenu2 -gt 14 ){
					Write-Host "`tPlease select one of the options available.`n" -Fore Red;start-Sleep -Seconds 1
				}
			}
			Switch ($xMenu2){
				1{ $user = Read-Host 'Enter User Logon Name';Write-output (get-logonstatistics  "$user" | select-object LastAccessTime,username,clientname,servername,databasename | select-object -last 1 | ft);Write-host "`nPress any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")}
                2{ $database = Read-Host 'Enter Database'; Write-Output (Get-Mailbox -Database $database -ResultSize Unlimited |Select-Object PrimarySmtpAddress | Out-File Databaseemails.csv  -append); Write-host "`nEmail list sent, press any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); send-mailmessage -from "NOC@domain.com" -to "noc@domain.com" -subject "Database $database Email Addresses" -body (Get-Content Databaseemails.csv | out-string) -smtpServer smtp-pdc.domain.com; remove-item databaseemails.csv | Where { ! $_.PSIsContainer } }
                3{ $server = Read-Host 'Enter Server Name';Write-output (Get-mailboxserver $server | get-mailbox | select-object primarysmtpaddress | Out-file serveremails.csv –append) ; Write-host "`nEmail list sent, press any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown");send-mailmessage -from "NOC@domain.com" -to "NOC@domain.com" -subject "$server Email Addresses" -body (Get-Content serveremails.csv | out-string) -smtpServer smtp-pdc.domain.com;remove-item serveremails.csv | Where { ! $_.PSIsContainer } }
                4{ $server = Read-Host 'Enter Server Name';Get-LogonStatistics -Server $server | where {$_.applicationid -like "*RPC*"} | Get-Mailbox | select PrimarySmtpAddress | export-csv CASraw.csv -NoTypeInformation; Get-Content CASraw.csv | sort | get-unique | % {$_ -replace '"', ""} | select-string -pattern 'PrimarySmtpAddress' -notmatch | select-string -pattern 'BESADMIN' -notmatch | select-string -pattern 'ZZZZ' -notmatch >CASEmail.txt;send-mailmessage -from "NOC@domain.com" -to "NOC@domain.com" -subject "CAS connections on $server Email Addresses" -body (Get-Content CASEmail.txt | out-string) -smtpServer smtp-pdc.domain.com; Write-host "`nEmail list sent, press any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); remove-item CASEmail.txt;remove-item CasRaw.csv}
                5{ Get-MailboxDatabase | Sort Name | ForEach {$db=$_.Name; $xNow=$_.Server.Name ;$dbown=$_.ActivationPreference| Where {$_.Value -eq 1};  Write-Host $db “on” $xNow “Should be on” $dbOwn.Key -NoNewLine; If ( $xNow -ne $dbOwn.Key){Write-host ” WRONG” -ForegroundColor Red; } Else {Write-Host ” OK” -ForegroundColor Green}};;Write-host "`nPress any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")  }
                6{ Write-output (Get-MailboxServer MailServermail* | Get-MailboxDatabaseCopyStatus | Out-file dbhealth.csv) ;send-mailmessage -from "NOC@domain.com" -to "NOC@domain.com" -subject "ADC Database Health Check" -body (Get-Content dbhealth.csv | out-string) -smtpServer smtp-pdc.domain.com;Write-host "`nEmail list sent, press any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown");remove-item dbhealth.csv| Where { ! $_.PSIsContainer } }
				7{ .\MovePamScript -datacenter ADC}
                8{ .\Test-ExchangeServerHealth.ps1 -Server MailServermail* -reportmode –sendemail; Write-host "`nReport has been emailed, press any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")  }
                9{ .\Get-CorpDAGLayoutv2.ps1 -ScriptFilesPath .\  -SendMail:$true -MailFrom NOC@domain.com  -MailTo NOC@domain.com  -MailServer smtp-pdc.domain.com -InputDAGs ADC-DAG1; Write-host "`nReport has been emailed, press any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
                10{ Get-TransportServer | where {$_ -like "*MailServermail*"} | get-queue | where {($_.messagecount –gt "1") -AND ($_.deliverytype -ne "ShadowRedundancy")} | ogv | Sleep (10); Write-host "`nQueue Report has been generated, if no box appears - there is no queue backup, press any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")}
                11{ cls
                Get-MailboxServer –Identity MailServermail00*  | select name, DatabaseCopyAutoActivationPolicy
                ""
                ""
                Read-Host "Press ENTER"
	           Press ENTER:}
                12{ D:\"NOC scripts\ActivationPolicyScript.ps1" -DCserver AS -Policy Blocked}                
                13{ D:\"NOC scripts\ActivationPolicyScript.ps1" -DCserver AS -Policy UnRestricted}
               default { Write-Host "`n`tYou Selected Option 14 – Quit the Administration Tasks`n" -Fore Yellow; break}
			}
		}
		2 {
			while ( $xMenu2 -lt 1 -or $xMenu2 -gt 14 ){
				CLS
				# Present the Menu Options
				Write-Host "`n`tEuropean Datacenter (EDC) Exchange Tools and Information`n" -Fore Magenta
				Write-Host "`t`t>>>>  Single Server and CAS Server need to be ran for a complete Email List  <<<<" -Fore Red
				Write-Host "`t`t      Single Server" -Fore Red -nonewline; Write-Host " for mailboxes house on the affected server" -Fore Yellow
                Write-Host "`t`t      CAS Server" -Fore Red -nonewline; Write-Host " for client connections through the affected server`n" -Fore Yellow
                Write-Host "`t`t`t1. Single User Information (On Screen)" -Fore Cyan
				Write-Host "`t`t`t2. Single Database Email List (Email Report)" -Fore Cyan
				Write-Host "`t`t`t3. Single Server Email List (Email Report)" -Fore Cyan
				Write-Host "`t`t`t4. CAS Server Email List (Email Report)" -Fore Cyan
                Write-Host "`t`t`t5. Database Locations (On Screen)" -Fore Cyan
                Write-Host "`t`t`t6. Database Health Check (Email Report)" -Fore Cyan
                Write-Host "`t`t`t7. Check Quorm State and move PAM" -Fore Cyan
                Write-Host "`t`t`t8. Exchange Overall Health (Email Report)" -Fore Cyan
                Write-Host "`t`t`t9. DAG Layout (Email Report)" -Fore Cyan
                Write-Host "`t`t`t10. Check Mailbox Queues" -Fore Cyan
                Write-Host "`t`t`t11. Check Activation Policy" -Fore Cyan
                Write-Host "`t`t`t12. Change Activation Policy to Blocked"-Fore Cyan -nonewline; Write-Host " (Run command before patching or reboot)" -Fore Red
                Write-Host "`t`t`t13. Change Activation Policy to Unrestricted"-Fore Cyan -nonewline; Write-Host " (Run command once patching or reboot is completed)" -Fore Red
                Write-Host "`t`t`t14. Go to Main Menu`n" -Fore Cyan
				[int]$xMenu2 = Read-Host "`t`tEnter Menu Option Number"
			}
			if( $xMenu2 -lt 1 -or $xMenu2 -gt 14 ){
				Write-Host "`tPlease select one of the options available.`n" -Fore Red;start-Sleep -Seconds 1
			}
			Switch ($xMenu2){
				1{ $user = Read-Host 'Enter User Logon Name';Write-output (get-logonstatistics  "$user" | select-object LastAccessTime,username,clientname,servername,databasename | select-object -last 1 | ft);Write-host "`nPress any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")}
                2{ $database = Read-Host 'Enter Database'; Write-Output (Get-Mailbox -Database $database -ResultSize Unlimited |Select-Object PrimarySmtpAddress | Out-File Databaseemails.csv  -append); Write-host "`nEmail list sent, press any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); send-mailmessage -from "NOC@domain.com" -to "noc@domain.com" -subject "Database $database Email Addresses" -body (Get-Content Databaseemails.csv | out-string) -smtpServer smtp-pdc.domain.com; remove-item databaseemails.csv | Where { ! $_.PSIsContainer } }
                3{ $server = Read-Host 'Enter Server Name';Write-output (Get-mailboxserver $server | get-mailbox | select-object primarysmtpaddress | Out-file serveremails.csv –append) ; Write-host "`nEmail list sent, press any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown");send-mailmessage -from "NOC@domain.com" -to "NOC@domain.com" -subject "$server Email Addresses" -body (Get-Content serveremails.csv | out-string) -smtpServer smtp-pdc.domain.com;remove-item serveremails.csv | Where { ! $_.PSIsContainer } }
                4{ $server = Read-Host 'Enter Server Name';Get-LogonStatistics -Server $server | where {$_.applicationid -like "*RPC*"} | Get-Mailbox | select PrimarySmtpAddress | export-csv CASraw.csv -NoTypeInformation; Get-Content CASraw.csv | sort | get-unique | % {$_ -replace '"', ""} | select-string -pattern 'PrimarySmtpAddress' -notmatch | select-string -pattern 'BESADMIN' -notmatch | select-string -pattern 'ZZZZ' -notmatch >CASEmail.txt;send-mailmessage -from "NOC@domain.com" -to "NOC@domain.com" -subject "CAS Connections on $server Email Addresses" -body (Get-Content CASEmail.txt | out-string) -smtpServer smtp-pdc.domain.com; Write-host "`nEmail list sent, press any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); remove-item CASEmail.txt;remove-item CasRaw.csv }
                5{ Get-MailboxDatabase | Sort Name | ForEach {$db=$_.Name; $xNow=$_.Server.Name ;$dbown=$_.ActivationPreference| Where {$_.Value -eq 1};  Write-Host $db “on” $xNow “Should be on” $dbOwn.Key -NoNewLine; If ( $xNow -ne $dbOwn.Key){Write-host ” WRONG” -ForegroundColor Red; } Else {Write-Host ” OK” -ForegroundColor Green}};;Write-host "`nPress any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")  }
				6{ Write-output (Get-MailboxServer MailServermail* | Get-MailboxDatabaseCopyStatus| Out-file dbhealth.csv) ; send-mailmessage -from "NOC@domain.com" -to "NOC@domain.com" -subject "EDC Database Health Check" -body (Get-Content dbhealth.csv | out-string) -smtpServer smtp-pdc.domain.com;Write-host "`nEmail list sent, press any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown");remove-item dbhealth.csv| Where { ! $_.PSIsContainer } }
                7{ .\MovePamScript -datacenter EDC}
                8{ .\Test-ExchangeServerHealth.ps1 -Server MailServermail* -reportmode –sendemail; Write-host "`nReport has been emailed, press any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")  }
                9{ .\Get-CorpDAGLayoutv2.ps1 -ScriptFilesPath .\  -SendMail:$true -MailFrom NOC@domain.com  -MailTo NOC@domain.com  -MailServer smtp-pdc.domain.com -InputDAGs EDC-DAG1; Write-host "`nReport has been emailed, press any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
                10{ Get-TransportServer | where {$_ -like "*MailServermail*"} | get-queue | where {($_.messagecount –gt "1") -AND ($_.deliverytype -ne "ShadowRedundancy")} | ogv | Sleep (10); Write-host "`nQueue Report has been generated, if no box appears - there is no queue backup, press any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")}
                11{  cls
                Get-MailboxServer –Identity MailServermail01*  | select name, DatabaseCopyAutoActivationPolicy
                ""
                ""
                Read-Host "Press ENTER"
	           Press ENTER:}
                12{ D:\"NOC scripts\ActivationPolicyScript.ps1" -DCserver EU -Policy Blocked}                
                13{ D:\"NOC scripts\ActivationPolicyScript.ps1" -DCserver EU -Policy UnRestricted}
                default { Write-Host "`n`tYou Selected Option 14 – Quit the Administration Tasks`n" -Fore Yellow; break}
			}
		}
		3 {
			while ( $xMenu2 -lt 1 -or $xMenu2 -gt 14 ){
				CLS
				# Present the Menu Options
				Write-Host "`n`tPrimary Datacenter (PDC) Exchange Tools and Information`n" -Fore Magenta
				Write-Host "`t`t>>>>  Single Server and CAS Server need to be ran for a complete Email List  <<<<" -Fore Red
				Write-Host "`t`t      Single Server" -Fore Red -nonewline; Write-Host " for mailboxes house on the affected server" -Fore Yellow
                Write-Host "`t`t      CAS Server" -Fore Red -nonewline; Write-Host " for client connections through the affected server`n" -Fore Yellow
                Write-Host "`t`t`t1. Single User Information (On Screen)" -Fore Cyan
				Write-Host "`t`t`t2. Single Database Email List (Email Report)" -Fore Cyan
				Write-Host "`t`t`t3. Single Server Email List (Email Report)" -Fore Cyan
				Write-Host "`t`t`t4. CAS Server Email List (Email Report)" -Fore Cyan
                Write-Host "`t`t`t5. Database Locations (On Screen)" -Fore Cyan
                Write-Host "`t`t`t6. Database Health Check (Email Report)" -Fore Cyan
                Write-Host "`t`t`t7. Check Quorm State and move PAM" -Fore Cyan
                Write-Host "`t`t`t8. Exchange Overall Health (Email Report)" -Fore Cyan
                Write-Host "`t`t`t9. DAG Layout (Email Report)" -Fore Cyan
                Write-Host "`t`t`t10. Check Mailbox Queues" -Fore Cyan
                Write-Host "`t`t`t11. Check Activation Policy" -Fore Cyan
                Write-Host "`t`t`t12. Change Activation Policy to Blocked"-Fore Cyan -nonewline; Write-Host " (Run command before patching or reboot)" -Fore Red
                Write-Host "`t`t`t13. Change Activation Policy to Unrestricted"-Fore Cyan -nonewline; Write-Host " (Run command once patching or reboot is completed)" -Fore Red
                Write-Host "`t`t`t14. Go to Main Menu`n" -Fore Cyan
				[int]$xMenu2 = Read-Host "`t`tEnter Menu Option Number"
				if( $xMenu2 -lt 1 -or $xMenu2 -gt 14 ){
					Write-Host "`tPlease select one of the options available.`n" -Fore Red;start-Sleep -Seconds 1
				}
			}
			Switch ($xMenu2){
				1{ $user = Read-Host 'Enter User Logon Name';Write-output (get-logonstatistics  "$user" | select-object LastAccessTime,username,clientname,servername,databasename | select-object -last 1 | ft);Write-host "`nPress any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")}
                2{ $database = Read-Host 'Enter Database'; Write-Output (Get-Mailbox -Database $database -ResultSize Unlimited |Select-Object PrimarySmtpAddress | Out-File Databaseemails.csv  -append); Write-host "`nEmail list sent, press any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); send-mailmessage -from "NOC@domain.com" -to "noc@domain.com" -subject "Database $database Email Addresses" -body (Get-Content Databaseemails.csv | out-string) -smtpServer smtp-pdc.domain.com; remove-item databaseemails.csv | Where { ! $_.PSIsContainer } }
                3{ $server = Read-Host 'Enter Server Name';Write-output (Get-mailboxserver $server | get-mailbox | select-object primarysmtpaddress | Out-file serveremails.csv –append) ; Write-host "`nEmail list sent, press any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown");send-mailmessage -from "NOC@domain.com" -to "NOC@domain.com" -subject "$server Email Addresses" -body (Get-Content serveremails.csv | out-string) -smtpServer smtp-pdc.domain.com;remove-item serveremails.csv | Where { ! $_.PSIsContainer } }
                4{ $server = Read-Host 'Enter Server Name';Get-LogonStatistics -Server $server | where {$_.applicationid -like "*RPC*"} | Get-Mailbox | select PrimarySmtpAddress | export-csv CASraw.csv -NoTypeInformation; Get-Content CASraw.csv | sort | get-unique | % {$_ -replace '"', ""} | select-string -pattern 'PrimarySmtpAddress' -notmatch | select-string -pattern 'BESADMIN' -notmatch | select-string -pattern 'ZZZZ' -notmatch >CASEmail.txt;send-mailmessage -from "NOC@domain.com" -to "NOC@domain.com" -subject "CAS Connections on $server Email Addresses" -body (Get-Content CASEmail.txt | out-string) -smtpServer smtp-pdc.domain.com; Write-host "`nEmail list sent, press any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); remove-item CASEmail.txt;remove-item CasRaw.csv}
                5{ Get-MailboxDatabase | Sort Name | ForEach {$db=$_.Name; $xNow=$_.Server.Name ;$dbown=$_.ActivationPreference| Where {$_.Value -eq 1};  Write-Host $db “on” $xNow “Should be on” $dbOwn.Key -NoNewLine; If ( $xNow -ne $dbOwn.Key){Write-host ” WRONG” -ForegroundColor Red; } Else {Write-Host ” OK” -ForegroundColor Green}};;Write-host "`nPress any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")  }
				6{ Write-output (Get-MailboxServer domain* | Get-MailboxDatabaseCopyStatus| Out-file dbhealth.csv) ; send-mailmessage -from "NOC@domain.com" -to "NOC@domain.com" -subject "PDC Database Health Check" -body (Get-Content dbhealth.csv | out-string) -smtpServer smtp-pdc.domain.com;Write-host "`nEmail list sent, press any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown");remove-item dbhealth.csv| Where { ! $_.PSIsContainer } }
                7{ .\MovePamScript -datacenter PDC}
                8{ .\Test-ExchangeServerHealth.ps1 -Server domain* -reportmode –sendemail; Write-host "`nReport has been emailed, press any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")  }
                9{ .\Get-CorpDAGLayoutv2.ps1 -ScriptFilesPath .\  -SendMail:$true -MailFrom NOC@domain.com  -MailTo NOC@domain.com  -MailServer smtp-pdc.domain.com -InputDAGs PDC-DAG1; Write-host "`nReport has been emailed, press any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
                10{ Get-TransportServer | where {$_ -like "*domain*"} | get-queue | where {($_.messagecount –gt "1") -AND ($_.deliverytype -ne "ShadowRedundancy")} | ogv | Sleep (10); Write-host "`nQueue Report has been generated, if no box appears - there is no queue backup, press any key to continue..."; $x=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")}
                11{ cls
                Get-MailboxServer –Identity domain01*  | select name, DatabaseCopyAutoActivationPolicy
                ""
                ""
                Read-Host "Press ENTER"
	           Press ENTER:}
                12{ D:\"NOC scripts\ActivationPolicyScript.ps1" -DCserver US -Policy Blocked}                
                13{ D:\"NOC scripts\ActivationPolicyScript.ps1" -DCserver US -Policy UnRestricted}
				default { Write-Host "`n`tYou Selected Option 14 – Quit the Administration Tasks`n" -Fore Yellow; break}
			}
		}
        #************************
        4 {
			while ( $xMenu2 -lt 1 -or $xMenu2 -gt 3 ){
				CLS
				# Present the Menu Options
				Write-Host "`n`tDisaster Recovery Datacenter (SDC) Exchange Tools and Information`n" -Fore Magenta
                Write-Host "`t`t`t1. Resume/Start SDC Replication" -Fore Cyan
				Write-Host "`t`t`t2. Suspend/Stop SDC Replication" -Fore Cyan
                Write-Host "`t`t`t3. Go to Main Menu`n" -Fore Cyan
				[int]$xMenu2 = Read-Host "`t`tEnter Menu Option Number"
			}
			if( $xMenu2 -lt 1 -or $xMenu2 -gt 3 ){
				Write-Host "`tPlease select one of the options available.`n" -Fore Red;start-Sleep -Seconds 1
			}
			Switch ($xMenu2){
				1{ d:\"NOC scripts\DRC-ReplicationStart.ps1"}
                2{ d:\"NOC scripts\DRC-ReplicationStop.ps1"}
                default { Write-Host "`n`tYou Selected Option 3 – Quit the Administration Tasks`n" -Fore Yellow; break}
			}
		}

        #**********************
        5 {
			while ( $xMenu2 -lt 1 -or $xMenu2 -gt 3 ){
				CLS
				# Present the Menu Options
				Write-Host "`n`tGlobal Exchange Tools and Information`n" -Fore Magenta
                Write-Host "`t`t`t1. eXclaimer & Exchange Transport Service Monitor and Autostart" -Fore Cyan
                Write-Host "`t`t`t2. Check Quorm State and move PAM" -Fore Cyan
                Write-Host "`t`t`t3. Go to Main Menu`n" -Fore Cyan
				[int]$xMenu2 = Read-Host "`t`tEnter Menu Option Number"
				if( $xMenu2 -lt 1 -or $xMenu2 -gt 3 ){
					Write-Host "`tPlease select one of the options available.`n" -Fore Red;start-Sleep -Seconds 1
				}
			}
			Switch ($xMenu2){
				1{ d:\"NOC scripts\eXclaimerServicesStart.ps1"}
                2{ .\MovePamScript}
                default { Write-Host "`n`tYou Selected Option 3 – Quit the Administration Tasks`n" -Fore Yellow; break}
			}
		}
       # ************************
		default { $Script:xExitSession=$true;break }
	}
}
LoadMenuSystem
If ($xExitSession){
	exit-pssession    #… User quit & Exit
}else{
	.\Menu.ps1    #… Loop the function
}