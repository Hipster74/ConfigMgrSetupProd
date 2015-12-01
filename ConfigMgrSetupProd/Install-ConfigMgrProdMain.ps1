Workflow Install-ConfigMgrProdMain {
	Param(
		[Parameter(Mandatory=$true)]
		[int]$CustomerNumber,

		[Parameter(Mandatory=$true)]
		[int]$CustomerName,

		[Parameter(Mandatory=$true)]
		[int]$CustomerDomain,

		[Parameter(Mandatory=$true)]
		[int]$CustomerDomainNetBiosName,
		
		[Parameter(Mandatory=$true)]
		[string]$CustomerCMSiteCode,

		[Parameter(Mandatory=$true)]
		[string]$CustomerCMSrvHostname
	)
	$AutomationAccountName = 'ManagedSystemsProductionAutomation'
	$AzureSubscriptionName = 'Visual Studio Premium med MSDN'
	$AzureCredential = Get-AutomationPSCredential -Name 'AzureOrgIdCredential'
	$HybridWorkerGroup = 'ConfigMgrServers'

	#$CustomerName = 'RunTCOn'
	#$CustomerDomain = "s11.se.tconet.net"
	#$CustomerDomainNetBiosName = "s11"
	#$CustomerCMSrvHostname = "S11ARNSAS108"
	#$CustomerCMSiteCode = 'P34'
	#$CustomerADSrvHostname = "$CustomerNumber-AD01"
	#$CustomerDomainControllerFQDN = "$CustomerNumber-AD01.$CustomerDomain"

	# RunTCOn CustomerNumber 800000
	# S11 Domain DC=s11,DC=se,DC=tconet,DC=net
	$CustomerTCStdAdDn = "OU=$CustomerNumber,OU=Customers,OU=TCONARN,OU=ASP"
	#$CustomerTCStdAdDn = "OU=$CustomerNumber,OU=Customers,OU=$CustomerNumber" + 'ARN,OU=ASP'

	$SourceFilesDestination = 'd:\CMSetupSource' # Installationsfiles(SQL,CM, MDT etc.) goes to this folder in CMsrv

	$CMProductCode = 'BXH69-M62YX-QQD6R-3GPWX-8WMFY' # Telecomputings System Center licensekey
	$CMPrerequisitePath = "$SourceFilesDestination\SystemCenter\ConfigMgr2012wSP2PreReqs"
	$CMInstallDir = 'd:\ConfigMgr'
	$CMSharesParentFolder = 'd:\Shares'
	
	$CMSetupInstallerAccountPassword = ConvertTo-SecureString 'Al3xander!"#' -AsPlainText -Force
	$CMSetupInstallerAccountUsername = "$CustomerDomainNetBiosName\500001jja-adm"
	$CMSetupInstallerCred = New-Object System.Management.Automation.PSCredential ($CMSetupInstallerAccountUsername, $CMSetupInstallerAccountPassword)

__TCONARN-JoinAcc
DJBA%Bnm+SYUnhUBjmVv
	
	$CMNetworkAccountPassword = ConvertTo-SecureString 'A7+d1czSMycVz-v+s7Zb' -AsPlainText -Force
	$CMNetworkAccountUsername = "$CustomerDomainNetBiosName\__$CustomerNumber-R-NwAAcc"
	$CMNwAACCCred = New-Object System.Management.Automation.PSCredential ($CMNetworkAccountUsername, $CMNetworkAccountPassword)

	$CMSQLServiceAccountPassword = ConvertTo-SecureString 'a=[6@)RDdsRUtCz)' -AsPlainText -Force
	$CMSQLServiceAccountUsername = "$CustomerDomainNetBiosName\__$CustomerNumber" + 'SQLSvc'
	$CMSQLServiceAccountCred = New-Object System.Management.Automation.PSCredential ($CMSQLServiceAccountUsername, $CMSQLServiceAccountPassword)

	$CMSQLServerSAAccountPassword = ConvertTo-SecureString 'g72BDJsy80361nMrwzP7fhsLVpG4H1YRBF4' -AsPlainText -Force
	$CMSQLServerSAAccountUsername = 'SA'
	$CMSQLServerSAAccountCred = New-Object System.Management.Automation.PSCredential ($CMSQLServerSAAccountUsername, $CMSQLServerSAAccountPassword)

	# Execution start timestamp
	[datetime]$StartRun = Get-Date
	Configure-Assets `
	-CustomerNumber $CustomerNumber -CustomerName $CustomerName -AzureOrgIdCredential $AzureCredential -AzureSubscriptionName $AzureSubscriptionName -AutomationAccountName $AutomationAccountName -CMSetupInstallerCred $CMSetupInstallerCred -CMNwAACCCred $CMNwAACCCred -CMSQLServiceAccountCred $CMSQLServiceAccountCred -CMSQLServerSAAccountCred $CMSQLServerSAAccountCred -CMProductCode $CMProductCode -CustomerCMSiteCode $CustomerCMSiteCode -CustomerCMSrvHostname $CustomerCMSrvHostname -CustomerDomain $CustomerDomain -CMInstallDir $CMInstallDir -CMPrerequisitePath $CMPrerequisitePath

	$ChildRunbookName = "Create-CMShares"
    $ChildRunbookInputParams = @{"VMName"="$CustomerCMSrvHostname";'CMNetworkAccountCredential'="CMSetupCred-$CustomerNumber NetworkAccessAccount";'CMSharesParentFolder'="$CMSharesParentFolder";"VMCredential"="CMSetupCred-$CustomerNumber CMInstaller Domainaccount"}
	Start-HybridChildRunbook -ChildRunbookName $ChildRunbookName -ChildRunbookInputParams $ChildRunbookInputParams -AzureOrgIdCredential $AzureCredential -AzureSubscriptionName $AzureSubscriptionName -AutomationAccountName $AutomationAccountName -WaitForJobCompletion:$true -ReturnJobOutput:$true -HybridWorkerGroup $HybridWorkerGroup
	
	$ChildRunbookName = "Install-CMPrimarySiteWinFeatures"
    $ChildRunbookInputParams = @{"VMName"="$CustomerCMSrvHostname";"VMCredential"="CMSetupCred-$CustomerNumber CMInstaller Domainaccount";"MacSupport"=$true}
	Start-HybridChildRunbook -ChildRunbookName $ChildRunbookName -ChildRunbookInputParams $ChildRunbookInputParams -AzureOrgIdCredential $AzureCredential -AzureSubscriptionName $AzureSubscriptionName -AutomationAccountName $AutomationAccountName -WaitForJobCompletion:$true -ReturnJobOutput:$true -HybridWorkerGroup $HybridWorkerGroup
	
	$ChildRunbookName = "Install-WDS"
    $ChildRunbookInputParams = @{"VMName"="$CustomerCMSrvHostname";"VMCredential"="CMSetupCred-$CustomerNumber CMInstaller Domainaccount"}
	Start-HybridChildRunbook -ChildRunbookName $ChildRunbookName -ChildRunbookInputParams $ChildRunbookInputParams -AzureOrgIdCredential $AzureCredential -AzureSubscriptionName $AzureSubscriptionName -AutomationAccountName $AutomationAccountName -WaitForJobCompletion:$true -ReturnJobOutput:$true -HybridWorkerGroup $HybridWorkerGroup
	
	$ChildRunbookName = "Install-MDT2013U1"
	$ChildRunbookInputParams = @{"VMName"="$CustomerCMSrvHostname";"VMCredential"="CMSetupCred-$CustomerNumber CMInstaller Domainaccount";"SourceFilesParentDir"="$SourceFilesDestination"}
	Start-HybridChildRunbook -ChildRunbookName $ChildRunbookName -ChildRunbookInputParams $ChildRunbookInputParams -AzureOrgIdCredential $AzureCredential -AzureSubscriptionName $AzureSubscriptionName -AutomationAccountName $AutomationAccountName -WaitForJobCompletion:$true -ReturnJobOutput:$true -HybridWorkerGroup $HybridWorkerGroup
	
	$ChildRunbookName = "Install-ADK10"
	$ChildRunbookInputParams = @{"VMName"="$CustomerCMSrvHostname";"VMCredential"="CMSetupCred-$CustomerNumber CMInstaller Domainaccount";"SourceFilesParentDir"="$SourceFilesDestination"}
	Start-HybridChildRunbook -ChildRunbookName $ChildRunbookName -ChildRunbookInputParams $ChildRunbookInputParams -AzureOrgIdCredential $AzureCredential -AzureSubscriptionName $AzureSubscriptionName -AutomationAccountName $AutomationAccountName -WaitForJobCompletion:$true -ReturnJobOutput:$true -HybridWorkerGroup $HybridWorkerGroup
	
	$ChildRunbookName = "Install-CMSQLSrv"
	$ChildRunbookInputParams = @{"VMName"="$CustomerCMSrvHostname";"VMCredential"="CMSetupCred-$CustomerNumber CMInstaller Domainaccount";"SourceFilesParentDir"="$SourceFilesDestination";"SQLSrvUnattendName"="CMSetupVar-$CustomerNumber SQLserver 2014 Unattend";"CMSQLServiceAccountCredential"="CMSetupCred-$CustomerNumber SQL Service Account";"CMSQLServerSAAccountCredential"="CMSetupCred-$CustomerNumber SQL SA Account"}
	Start-HybridChildRunbook -ChildRunbookName $ChildRunbookName -ChildRunbookInputParams $ChildRunbookInputParams -AzureOrgIdCredential $AzureCredential -AzureSubscriptionName $AzureSubscriptionName -AutomationAccountName $AutomationAccountName -WaitForJobCompletion:$true -ReturnJobOutput:$true -HybridWorkerGroup $HybridWorkerGroup -JobPollingTimeoutInSeconds 1800
	
	$ChildRunbookName = "Restart-VM"
	$ChildRunbookInputParams = @{"VMName"="$CustomerCMSrvHostname";"VMCredential"="CMSetupCred-$CustomerNumber CMInstaller Domainaccount"}
	Start-HybridChildRunbook -ChildRunbookName $ChildRunbookName -ChildRunbookInputParams $ChildRunbookInputParams -AzureOrgIdCredential $AzureCredential -AzureSubscriptionName $AzureSubscriptionName -AutomationAccountName $AutomationAccountName -WaitForJobCompletion:$true -ReturnJobOutput:$true -HybridWorkerGroup $HybridWorkerGroup
	
	$ChildRunbookName = "Install-CM2012SP2"
	$ChildRunbookInputParams = @{"VMName"="$CustomerCMSrvHostname";"VMCredential"="CMSetupCred-$CustomerNumber CMInstaller Domainaccount";"SourceFilesParentDir"="$SourceFilesDestination";"CM2012SP2UnattendName"="CMSetupVar-$CustomerNumber Configuration Manager 2012 Unattend"}
	Start-HybridChildRunbook -ChildRunbookName $ChildRunbookName -ChildRunbookInputParams $ChildRunbookInputParams -AzureOrgIdCredential $AzureCredential -AzureSubscriptionName $AzureSubscriptionName -AutomationAccountName $AutomationAccountName -WaitForJobCompletion:$true -ReturnJobOutput:$true -HybridWorkerGroup $HybridWorkerGroup -JobPollingTimeoutInSeconds 1800
	
	$ChildRunbookName = "Install-CM2012R2SP1"
	$ChildRunbookInputParams = @{"VMName"="$CustomerCMSrvHostname";"VMCredential"="CMSetupCred-$CustomerNumber CMInstaller Domainaccount";"SourceFilesParentDir"="$SourceFilesDestination"}
	Start-HybridChildRunbook -ChildRunbookName $ChildRunbookName -ChildRunbookInputParams $ChildRunbookInputParams -AzureOrgIdCredential $AzureCredential -AzureSubscriptionName $AzureSubscriptionName -AutomationAccountName $AutomationAccountName -WaitForJobCompletion:$true -ReturnJobOutput:$true -HybridWorkerGroup $HybridWorkerGroup
	
	$ChildRunbookName = "Install-CM2012R2SP1CU2"
	$ChildRunbookInputParams = @{"VMName"="$CustomerCMSrvHostname";"VMCredential"="CMSetupCred-$CustomerNumber CMInstaller Domainaccount";"SourceFilesParentDir"="$SourceFilesDestination"}
	Start-HybridChildRunbook -ChildRunbookName $ChildRunbookName -ChildRunbookInputParams $ChildRunbookInputParams -AzureOrgIdCredential $AzureCredential -AzureSubscriptionName $AzureSubscriptionName -AutomationAccountName $AutomationAccountName -WaitForJobCompletion:$true -ReturnJobOutput:$true -HybridWorkerGroup $HybridWorkerGroup
	
	$ChildRunbookName = "Configure-CMPostinstall"
	$ChildRunbookInputParams = @{"VMName"="$CustomerCMSrvHostname";"VMCredential"="CMSetupCred-$CustomerNumber CMInstaller Domainaccount";"CMNetworkAccountCredential"="CMSetupCred-$CustomerNumber NetworkAccessAccount";"OULaptops"="OU=Laptops,OU=Computers,$CustomerTCStdAdDn";"OUDesktops"="OU=Desktops,OU=Computers,$CustomerTCStdAdDn";"OUUsers"="OU=Users,$CustomerTCStdAdDn";"OUAppGroups"="OU=Resources,$CustomerTCStdAdDn"}
	Start-HybridChildRunbook -ChildRunbookName $ChildRunbookName -ChildRunbookInputParams $ChildRunbookInputParams -AzureOrgIdCredential $AzureCredential -AzureSubscriptionName $AzureSubscriptionName -AutomationAccountName $AutomationAccountName -WaitForJobCompletion:$true -ReturnJobOutput:$true -HybridWorkerGroup $HybridWorkerGroup
	
	[datetime]$EndRun = Get-Date
	[timespan]$Runtime = New-TimeSpan -Start $StartRun.ToLongTimeString() -End $EndRun.ToLongTimeString()

	Write-Verbose "Labsetup executiontime: $Runtime" -Verbose
}