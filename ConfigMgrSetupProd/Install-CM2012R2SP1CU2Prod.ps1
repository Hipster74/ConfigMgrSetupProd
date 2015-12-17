workflow Install-CM2012R2SP1CU2Prod
{
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [string]$VMName,
		[Parameter(Mandatory=$true)]
		[PSCredential] $VMCredential,
        [Parameter(Mandatory=$true,HelpMessage="Default is datadisk on d:\CMSetupSource")]
        [string]$SourceFilesParentDir
    )    
    
    inlinescript {
        $SourceFilesParentDir = $using:SourceFilesParentDir
                        
        try {
            Write-Verbose "Verifying Configuration Manager is installed"
            # Verifying Configuration Manager is installed
            if (Test-Path HKLM:\SOFTWARE\Microsoft\SMS\Setup) {
                Write-Verbose "Configuration Manager version $((Get-ItemProperty HKLM:\SOFTWARE\Microsoft\SMS\Setup)."Full Version") with CULevel $((Get-ItemProperty HKLM:\SOFTWARE\Microsoft\SMS\Setup).CULevel) installed, proceeding"
            }
            else {
                Write-Error "Configuration Manager installation not found, aborting"
                Throw "Configuration Manager installation not found, aborting"
               
            }
			# Make sure Trend Micro Officescan is not passwordprotected, CU2 installation tries to kill tmlisten service, but will fail if password is set
			if (Test-Path 'HKLM:\SOFTWARE\Wow6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion\Misc.') {
				Write-Verbose "Registrykey HKLM:\SOFTWARE\Wow6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion\Misc. found, making sure password protection is disabled" -Verbose
				Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion\Misc.' -Name 'NoPWDProtect' -Value 1 -Force
				# Stop Trend Micro Officescan temporarely, we must disable services to avoid autorestart
				Sleep -Seconds 15
                Stop-Process -ProcessName PccNTMon -Force
				Sleep -Seconds 15
                Set-Service -Name tmlisten -StartupType Disabled
				Stop-Process -ProcessName TmListen -Force
                Set-Service -Name NTRTScan -StartupType Disabled
                Stop-Process -ProcessName NTRTScan -Force
			}

			Write-Verbose "Starting CM 2012R2SP1 Cumulative Update 2 installation"
            if (Test-Path "$SourceFilesParentDir\SystemCenter\ConfigMgr2012CU2\CM12_SP2R2SP1CU2-KB3100144-X64-ENU.exe") {
                # Save CM 2012 R2 SP1 Cumulative Update 2 commandline arguments as array
                $CM2012R2SP1CU2UnattendArg = '/Unattended'
                # Call CM 2012 R2 SP1 Cumulative Update 2 CM12_SP2R2SP1CU2-KB3100144-X64-ENU.exe with arguments for unattended installation
                $CM2012R2SP1CU2InstallJob = Start-Job -Name 'CM2012R2SP1CU2Install'  -ScriptBlock {
    		        param(
        		        [parameter(Mandatory=$true)]
        			    $CM2012R2SP1CU2UnattendArg,
                        [parameter(Mandatory=$true)]
        			    $SourceFilesParentDir
                    )
    			    Start-Process -FilePath "$SourceFilesParentDir\SystemCenter\ConfigMgr2012CU2\CM12_SP2R2SP1CU2-KB3100144-X64-ENU.exe" -ArgumentList $CM2012R2SP1CU2UnattendArg -Wait
			    
                } -ArgumentList $CM2012R2SP1CU2UnattendArg, $SourceFilesParentDir
			    
                # Wait for installation to finish
                While (($CM2012R2SP1CU2InstallJob | Get-Job).State -eq 'Running') {
                    Write-Output "Heartbeat from Configuration Manager 2012R2SP1 Cumulative Update 2 Installation...."
                    Start-Sleep -Seconds 60
                }
                # Verify CM 2012R2SP1 Cumulative Update 2 installation
                if ((get-item -Path "$($env:SMS_ADMIN_UI_PATH.TrimEnd('\i386'))\Microsoft.ConfigurationManagement.exe").VersionInfo.productversion -eq '5.0.8239.1302') {
                    Write-Output "Configuration manager 2012R2SP1 Cumulative Update 2 installed successfully"
                }
                else {
                    Write-Error "Configuration manager 2012R2SP1 Cumulative Update 2 installation failed"
                    Throw "Configuration manager 2012R2SP1 Cumulative Update 2 installation failed"
                }
            }
            else {
                Write-Error "Could not find $SourceFilesParentDir\SystemCenter\ConfigMgr2012CU2\CM12_SP2R2SP1CU2-KB3100144-X64-ENU.exe , unable to install Configuration manager 2012R2SP1 Cumulative Update 2"
                Throw "Unable to locate Configuration manager 2012R2SP1 Cumulative Update 2 CM12_SP2R2SP1CU2-KB3100144-X64-ENU.exe"
            }
        } catch {
			# Enabling Trend Micro Officescan services again
			Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion\Misc.' -Name 'NoPWDProtect' -Value 0 -Force
			Set-Service -Name tmlisten -StartupType Automatic
            Set-Service -Name NTRTScan -StartupType	Automatic
            Write-Verbose "Failed to install Configuration manager 2012R2SP1 Cumulative Update 2"
            Write-Error $_.Exception
			Throw "Failed to install Configuration manager 2012R2SP1 Cumulative Update 2"
        }
		# Enabling Trend Micro Officescan services again
		Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion\Misc.' -Name 'NoPWDProtect' -Value 0 -Force
		Set-Service -Name tmlisten -StartupType Automatic
        Set-Service -Name NTRTScan -StartupType	Automatic
                           
    } -PSComputerName $VMName -PSCredential $VMCredential
}