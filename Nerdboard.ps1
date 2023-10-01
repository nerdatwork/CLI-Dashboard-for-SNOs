# CLI Dashboard for SNOs
# Brought to you by </NerdAtWork>

# Title the window
$host.ui.rawui.windowtitle="NerdBoard"

# Powershell 7.2 introduced this amazing $PSStyle variable.
$PSStyle.Progress.View = "Minimal"
$PSStyle.Progress.Style = "`e[45m"

function Pause (){
	Write-Host "`t`t$($PSStyle.Blink)" "Press ENTER to refresh" "$($PSStyle.BlinkOff)" -BackgroundColor Gray -ForegroundColor Magenta 
	$null = Read-Host 
}

do
{
	Clear-Host
	
	$satData = Invoke-WebRequest 'http://127.0.0.1:14002/api/sno/satellites' | ConvertFrom-Json
	Write-Progress -Activity "Collecting data" -Status "Processing ..." -PercentComplete ((1/9) * 100);
	
	$SNOdata = Invoke-WebRequest 'http://127.0.0.1:14002/api/sno' | ConvertFrom-Json
	Write-Progress -Activity "Collecting data" -Status "Processing ..." -PercentComplete ((2/9) * 100);
	
	$payData = Invoke-WebRequest 'http://127.0.0.1:14002/api/sno/estimated-payout' | ConvertFrom-Json
	Write-Progress -Activity "Collecting data" -Status "Processing ..." -PercentComplete ((3/9) * 100);
	
	$ver = Invoke-WebRequest 'https://api.github.com/repos/storj/storj/releases' | ConvertFrom-Json
	Write-Progress -Activity "Collecting data" -Status "Processing ..." -PercentComplete ((4/9) * 100);
	
	$nodeVersion = Invoke-WebRequest 'https://version.storj.io' | ConvertFrom-Json
	Write-Progress -Activity "Collecting data" -Status "Processing ..." -PercentComplete ((5/9) * 100);
	
	$tokenData = Invoke-WebRequest 'https://api.coingecko.com/api/v3/coins/ethereum/contract/0xB64ef51C888972c908CFacf59B47C1AfBC0Ab8aC' | ConvertFrom-Json
	Write-Progress -Activity "Collecting data" -Status "Processing ..." -PercentComplete ((6/9) * 100);
	
	$githubFile = Invoke-WebRequest 'https://api.github.com/repos/nerdatwork/CLI-Dashboard-for-SNOs' | ConvertFrom-Json
	Write-Progress -Activity "Collecting data" -Status "Processing ..." -PercentComplete ((7/9) * 100);
	
	# Get Etherscan.io API key
	$apiKey = Get-Content apikey.txt
	
	$ethAdd = $SNOdata.wallet
	$customURL = "https://api.etherscan.io/api?module=account&action=tokenbalance&contractaddress=0xB64ef51C888972c908CFacf59B47C1AfBC0Ab8aC&address=$ethAdd&tag=latest&apikey=$apiKey"
	
	$walletData = Invoke-WebRequest $customURL | ConvertFrom-Json
	Write-Progress -Activity "Collecting data" -Status "Processing ..." -PercentComplete ((8/9) * 100);
	
	# Getting Latest payment info from Etherscan
	$customURL = "https://api.etherscan.io/api?module=account&action=tokentx&contractaddress=0xB64ef51C888972c908CFacf59B47C1AfBC0Ab8aC&address=$ethAdd&page=1&offset=1&sort=desc&apikey=$apiKey"
	
	$latestTokenTransaction = Invoke-WebRequest $customURL | ConvertFrom-Json
	Write-Progress -Activity "Collecting data" -Status "Completed!" -PercentComplete ((9/9) * 100) -Completed;
	
	$tokenPayTime = (Get-Date "1/1/1970").AddSeconds($latestTokenTransaction.result[0].timeStamp)
	$tokenAmount = ($latestTokenTransaction.result[0].value)/100000000
	
	$uptime = New-TimeSpan -Start $SNOdata.startedAt -End $SNOdata.lastPinged
	$ageDiff = (Get-Date) - $satData.earliestJoinedAt
	$age = [System.Math]::Round($ageDiff.TotalDays)
	
	$quicUptime = New-TimeSpan -Start $SNOdata.lastQuicPingedAt -End (Get-Date)
	
	# Wallet balance feature
	$tokenPrice = $tokenData.market_data.current_price.usd
	$balanceInUSD = $tokenPrice * ($walletData.result/100000000)
	$balanceInUSD = [math]::round($balanceInUSD, 2)

    # Check if script is updated or not
	$localFile = (Get-Item "Nerdboard.ps1").LastWriteTime
	if ($localFile -lt $githubFile.pushed_at)
	{
		$scriptVersion = "No"
		$scriptLinkColor = "Red"
	}
	else
	{
		$scriptVersion = "Yes"
		$scriptLinkColor = "Green"
	}
	
	# Creating Hyperlinks
	$walletLink = $PSStyle.FormatHyperlink($SNOdata.wallet, "https://etherscan.io/address/"+ $SNOdata.wallet +"#tokentxns")
	$githubLatest = $PSStyle.FormatHyperlink($ver[0].name,"https://github.com/storj/storj/releases/tag/"+ $ver[0].name)
	$githubCurrent = $PSStyle.FormatHyperlink($SNOdata.version, "https://github.com/storj/storj/releases/tag/v" + $SNOdata.version)
	$scriptLink = $PSStyle.FormatHyperlink($scriptVersion, "https://github.com/nerdatwork/CLI-Dashboard-for-SNOs")
 
	Write-Host (Get-Date).ToLocalTime() "`t`t`t`t`t###########" -ForegroundColor Magenta -NoNewline; Write-Host " Nerdboard " -ForegroundColor Green -NoNewline; Write-Host "###############" -ForegroundColor Magenta
	Write-Host "Node ID  : " -ForegroundColor Cyan -NoNewline; Write-Host $SNOdata.nodeID -NoNewline; Write-Host " | " -NoNewline; Write-Host "Age (Days) : " -ForegroundColor Cyan -NoNewline; Write-Host $age
	if ($SNOdata.walletFeatures -eq $null) { $walletFeatures = "None"}
	Write-Host "Wallet   : " -NoNewline -ForegroundColor Cyan ; Write-Host $walletLink -ForegroundColor "Red" -NoNewline; Write-Host " | Wallet Features: " -NoNewline;  Write-Host $walletFeatures -ForegroundColor Green
	Write-Host "Uptime   : " -ForegroundColor Cyan -NoNewline; Write-Host $uptime.Days"Days" $uptime.Hours"Hours" $uptime.Minutes"Mins" $uptime.Seconds"Secs" -NoNewline; Write-Host " | " -NoNewline; Write-Host "Tokens : " -ForegroundColor Cyan -NoNewline; Write-Host ($walletData.result/100000000) -ForegroundColor Green -NoNewline; Write-Host " | " -NoNewline; Write-Host "Token in USD : " -ForegroundColor Cyan -NoNewline; Write-Host $balanceInUSD -ForegroundColor Green -NoNewline; Write-Host " | " -NoNewline; Write-Host "1 token (USD) : " -ForegroundColor Cyan -NoNewline; Write-Host $tokenPrice -ForegroundColor Green
	iF($SNOdata.quicStatus -eq "OK") { $fontColor = "Green" } else { $fontColor="Red" }
	Write-Host "Time since last QUIC ping :" -ForegroundColor Cyan -NoNewline; Write-Host $quicUptime.Days"Days" $quicUptime.Hours"Hours" $quicUptime.Minutes"Mins" $quicUptime.Seconds"Secs Ago | " -NoNewline; Write-Host "QUIC status: " -ForegroundColor Cyan -NoNewline; Write-Host $SNOdata.quicStatus -ForegroundColor $fontColor -NoNewline; Write-Host " | " -NoNewline; Write-Host "Configured Port: " -ForegroundColor Cyan -NoNewline; Write-Host $SNOdata.configuredPort
	Write-Host "_______________________________________________________________________________________________________________________________________________________________"
	Write-Host "`t   Current |`tAllowed  |`t Latest Release |`tLatest Release Published on | Is version uptodate? | Is this Script Uptodate ?" -ForegroundColor Cyan
	if ($SNOdata.upToDate -eq "True") { $fontColor = "Green" }
	else { $fontColor = "Red" }
	Write-Host "Version  :" $githubCurrent " |`t" $SNOdata.allowedVersion " |`t" $githubLatest "`t|`t" $ver[0].published_at "`t    |  " -NoNewline; Write-Host $SNOdata.upToDate -ForegroundColor $fontColor -NoNewline ; Write-Host "`t           |  " -NoNewline;
 	if ($scriptLinkColor -eq "Green") { Write-Host  $scriptVersion -ForegroundColor $scriptLinkColor }
	else { Write-Host "$($PSStyle.Blink)" $scriptLink -ForegroundColor $scriptLinkColor }
	Write-Host "________________________________________________________________________________________________________"
	Write-Host "`t`t Used(GB)`t  |  Allocated(GB) |`t Trash(GB) |`t Overused(GB) |`t Available(GB)" -ForegroundColor Cyan
	Write-Host "DiskSpace: `t" ([math]::round($SNOdata.diskSpace.used/1000000000, 3)) "`t  |`t" ([math]::round($SNOdata.diskSpace.available/1000000000, 3)) "`t   |`t" ([math]::round($SNOdata.diskSpace.trash/1000000000, 3)) "  |`t " ([math]::Round($SNOdata.diskSpace.overused/1000000000, 3)) "`t      |`t" (([math]::round($SNOdata.diskSpace.available/1000000000, 3)) -(([math]::round($SNOdata.diskSpace.used/1000000000, 3)) + ([math]::round($SNOdata.diskSpace.trash/1000000000, 3))) )
	Write-Host "Bandwidth: `t" ([math]::round($SNOdata.bandwidth.used/1000000000, 3)) -NoNewline
	Write-Host "`t`t  [Egress (GB)] : " -NoNewline -ForegroundColor Cyan
	Write-Host ([math]::round($satData.egressSummary/1000000000, 3)) -NoNewline
	Write-Host "`t`t   [Ingress (GB)] : " -NoNewline -ForegroundColor Cyan
	Write-Host ([math]::Round($satData.ingressSummary/1000000000,3))

	# Today's bandwidth
	$egressToday = $satData.bandwidthDaily[($satData.bandwidthDaily.count) - 1].egress.repair + $satData.bandwidthDaily[($satData.bandwidthDaily.count) - 1].egress.audit + $satData.bandwidthDaily[($satData.bandwidthDaily.count) - 1].egress.usage
	$ingressToday = $satData.bandwidthDaily[($satData.bandwidthDaily.count) - 1].ingress.repair + $satData.bandwidthDaily[($satData.bandwidthDaily.count) - 1].ingress.usage
	Write-Host "Bandwidth Today:" -NoNewline -ForegroundColor Yellow
	Write-Host "`t`t  [Egress (GB)] : " -NoNewline -ForegroundColor Cyan
	Write-Host ([math]::round($egressToday/1000000000, 3)) -NoNewline
	Write-Host "`t`t   [Ingress (GB)] : " -NoNewline -ForegroundColor Cyan
	Write-Host ([math]::round($ingressToday/1000000000, 3))
 
	Write-Host "________________________________________________________________________________________________________"
	Write-Host "SN |`tSatellite ID`t`t`t`t`t`t| Disqualified? | Suspended?`t| Storage Used(GB)| Audit Score | Suspension Score | Online Score | Satellite URL " -ForegroundColor Cyan
	Write-Host "__________________________________________________________________________________________________________________________________________________________________________________________________"
	for ($i = 0; $i -lt ($SNOdata.satellites).Count; $i++)
	{
		$auditScore = $satData.audits[$i].auditScore
		$suspensionScore = $satData.audits[$i].suspensionScore
		$onlineScore = $satData.audits[$i].onlineScore
		
		if (($SNOdata.satellites[$i].disqualified) -eq $null) { $disqualified = "No"; $fontColor = "Green" }
		else { $disqualified = "Yes"; $fontColor = "Red" }
		if (($SNOdata.satellites[$i].suspended) -eq $null) { $suspended = "No"; $fontColor = "Green" }
		else { $suspended = "Yes"; $fontColor = "Red" }
		
		Write-Host ($i + 1) " |" $SNOdata.satellites[$i].id  "`t|`t" -NoNewline; Write-Host $disqualified -ForegroundColor $fontColor -NoNewline; Write-Host "`t|`t" -NoNewline; Write-Host $suspended -ForegroundColor $fontColor -NoNewline; Write-Host "`t|" ([math]::round($SNOdata.satellites[$i].currentStorageUsed/1000000000, 3)) "`t  | " -NoNewline;
		
		# Color code audit/suspension/online scores: Less than 99: Yellow ; Less than 96: Red 
		
		if (($satData.audits[$i].auditScore -gt 0.96) -and ($satData.audits[$i].auditScore -lt 0.99) ) { $fontColor = "Yellow" }
		elseif ($satData.audits[$i].auditScore -lt 0.96) { $fontColor = "Red" }
		else { $fontColor = "White" }
		Write-Host ("{0:n7}" -f $satData.audits[$i].auditScore) -NoNewline -ForegroundColor $fontColor
		Write-Host "   |   " -NoNewline
		
		if (($satData.audits[$i].suspensionScore -gt 0.96) -and ($satData.audits[$i].suspensionScore -lt 0.99) ) { $fontColor = "Yellow" }
		elseif ($satData.audits[$i].suspensionScore -lt 0.96) { $fontColor = "Red" }
		else { $fontColor = "White" }
		Write-Host ("{0:n7}" -f $satData.audits[$i].suspensionScore) -NoNewline -ForegroundColor $fontColor
		Write-Host "      |   " -NoNewline
		
		if (($satData.audits[$i].onlineScore -gt 0.96) -and ($satData.audits[$i].onlineScore -lt 0.99)) { $fontColor = "Yellow" }
		elseif ($satData.audits[$i].onlineScore -lt 0.96) { $fontColor = "Red" }
		else { $fontColor = "White" }
		Write-Host ("{0:n7}" -f $satData.audits[$i].onlineScore) -NoNewline -ForegroundColor $fontColor
		Write-Host "  | " -NoNewline
		
		Write-Host $SNOdata.satellites[$i].url
	}
	
	# Payout Data
	Write-Host "__________________________________________________________________________________________________________________________________________________________________________________________________"
	Write-Host "Payout (USD) -> Current Month: " -NoNewline -ForegroundColor Cyan
	Write-Host ('{0:0.##}' -f ([math]::Round($payData.currentMonth.payout, 2)/100)) " | " -NoNewline
	Write-Host "Previous Month: " -NoNewline -ForegroundColor Cyan
	Write-Host ('{0:0.##}' -f ([math]::Round($payData.previousMonth.payout, 2)/100)) " | " -NoNewline
	Write-Host "Current Month Expected : " -NoNewline -ForegroundColor Cyan
	Write-Host ('{0:0.##}' -f ([math]::Round($payData.currentMonthExpectations, 2)/100)) " | " -NoNewline
	
	# Transaction Data
	Write-Host "Last transaction on : " -NoNewline -ForegroundColor Cyan
	if ($tokenPayTime.Month -eq (Get-Date).Month) { $fontColor = "Green" } else { $fontColor = "Red" }
	Write-Host $tokenPayTime -NoNewline -ForegroundColor $fontColor
	Write-Host " | " -NoNewline
	Write-Host "Last transaction amt (Storj) : " -NoNewline -ForegroundColor Cyan
	Write-Host $tokenAmount
	
	# Bandwidth for current month
	Write-Host "`t`t`t$($PSStyle.Bold)" "## Bandwidth usage for current month ##" -ForegroundColor Magenta
	
	Write-Host "___________________________________________________________________________________________________________________________________________________________________________"
	Write-Host "Day| " -NoNewline
	Write-Host "`t       Egress (GB)         " -ForegroundColor Green -NoNewline
	Write-Host "| " -NoNewline
	Write-Host "`t Ingress (GB)  " -NoNewline -ForegroundColor Yellow
	Write-Host "|| " -ForegroundColor Cyan -NoNewline
	Write-host "Day|" -NoNewline
	Write-Host "`t`t Egress (GB)         " -ForegroundColor Green -NoNewline
	Write-Host "|     " -NoNewline
	Write-Host "Ingress (GB)  " -ForegroundColor Yellow -NoNewline
	
	Write-Host "|| " -ForegroundColor Cyan -NoNewline
	Write-host "Day|" -NoNewline
	Write-Host "`t   Egress (GB)         " -ForegroundColor Green -NoNewline
	Write-Host "|     " -NoNewline
	Write-Host "Ingress (GB)" -ForegroundColor Yellow
	
	Write-Host "   |" -NoNewline
	Write-Host "  Repair  |Audit(MB)| Usage    " -ForegroundColor Green -NoNewline
	Write-Host "| " -NoNewline
	Write-Host "Repair  |  Usage  " -NoNewline -ForegroundColor Yellow
	Write-Host "||" -ForegroundColor Cyan -NoNewline
	Write-Host "    |" -NoNewline
	Write-Host "  Repair  |Audit(MB)| Usage    " -ForegroundColor Green -NoNewline
	Write-Host "| " -NoNewline
	Write-Host "Repair  |  Usage  " -ForegroundColor Yellow -NoNewline
	
	Write-Host "||" -ForegroundColor Cyan -NoNewline
	Write-Host "    |" -NoNewline
	Write-Host "  Repair  |Audit(MB)| Usage    " -ForegroundColor Green -NoNewline
	Write-Host "| " -NoNewline
	Write-Host "Repair  |  Usage  " -ForegroundColor Yellow
	Write-Host "___________________________________________________________________________________________________________________________________________________________________________"
	
	for ($i = 0; $i -lt ($satData.bandwidthDaily.count); ($i = $i + 3))
	{
		Write-Host ($i + 1).tostring('00') "|  " -NoNewline
		Write-Host  ([math]::round($satData.bandwidthDaily[$i].egress.repair/1000000000, 2)).ToString('000.00') " |  " ([math]::round($satData.bandwidthDaily[$i].egress.audit/1000000, 2)).ToString('00.00') "| " ([math]::round($satData.bandwidthDaily[$i].egress.usage/1000000000, 2)).ToString('000.00') -ForegroundColor Green -NoNewline
		Write-Host "  | " -NoNewline
		Write-Host ([math]::round($satData.bandwidthDaily[$i].ingress.repair/1000000000, 2)).ToString('000.00') " | " ([math]::round($satData.bandwidthDaily[$i].ingress.usage/1000000000, 2)).ToString('000.00') -ForegroundColor Yellow -NoNewline
		Write-Host " || " -ForegroundColor Cyan -NoNewline
		if (($i + 2 -gt ($satData.bandwidthDaily.count))) { break }
		Write-Host ($i + 2).tostring('00') "|  " -NoNewline
		Write-Host ([math]::round($satData.bandwidthDaily[($i + 1)].egress.repair/1000000000, 2)).ToString('000.00') " |  " ([math]::round($satData.bandwidthDaily[($i + 1)].egress.audit/1000000, 2)).ToString('00.00') "| " ([math]::round($satData.bandwidthDaily[($i + 1)].egress.usage/1000000000, 2)).ToString('000.00') -ForegroundColor Green -NoNewline
		Write-Host "  | " -NoNewline
		Write-Host ([math]::round($satData.bandwidthDaily[($i + 1)].ingress.repair/1000000000, 2)).ToString('000.00') " | " ([math]::round($satData.bandwidthDaily[($i + 1)].ingress.usage/1000000000, 2)).ToString('000.00') -ForegroundColor Yellow -NoNewline
		Write-Host " || " -ForegroundColor Cyan -NoNewline
		if (($i + 3 -gt ($satData.bandwidthDaily.count))) { break }
		Write-Host ($i + 3).tostring('00') "|  " -NoNewline
		Write-Host ([math]::round($satData.bandwidthDaily[($i + 2)].egress.repair/1000000000, 2)).ToString('000.00') " |  " ([math]::round($satData.bandwidthDaily[($i + 2)].egress.audit/1000000, 2)).ToString('00.00') "| " ([math]::round($satData.bandwidthDaily[($i + 2)].egress.usage/1000000000, 2)).ToString('000.00') -ForegroundColor Green -NoNewline
		Write-Host "  | " -NoNewline
		Write-Host ([math]::round($satData.bandwidthDaily[($i + 2)].ingress.repair/1000000000, 2)).ToString('000.00') " | " ([math]::round($satData.bandwidthDaily[($i + 2)].ingress.usage/1000000000, 2)).ToString('000.00') -ForegroundColor Yellow
	}
	
	Pause
}while ($true)
