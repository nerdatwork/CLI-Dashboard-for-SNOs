
# CLI Dashboard for SNOs
# Brought to you by </NerdAtWork>

function Pause (){
	Write-Host "`tPress ENTER to refresh" -BackgroundColor Gray -ForegroundColor Magenta
	$null = Read-Host 
}

do
{
	Clear-Host
	
	$satData = Invoke-WebRequest 'http://127.0.0.1:14002/api/sno/satellites' | ConvertFrom-Json
	$SNOdata = Invoke-WebRequest 'http://127.0.0.1:14002/api/sno' | ConvertFrom-Json
	$payData = Invoke-WebRequest 'http://127.0.0.1:14002/api/sno/estimated-payout' | ConvertFrom-Json
	$ver = Invoke-WebRequest 'https://api.github.com/repos/storj/storj/releases' | ConvertFrom-Json
	$tokenData = Invoke-WebRequest 'https://api.coingecko.com/api/v3/coins/ethereum/contract/0xB64ef51C888972c908CFacf59B47C1AfBC0Ab8aC' | ConvertFrom-Json
	
	# Get Etherscan.io API key
	$apiKey = Get-Content apikey.txt
	
	$ethAdd = $SNOdata.wallet
	$customURL = "https://api.etherscan.io/api?module=account&action=tokenbalance&contractaddress=0xB64ef51C888972c908CFacf59B47C1AfBC0Ab8aC&address=$ethAdd&tag=latest&apikey=$apiKey"
	
	$walletData = Invoke-WebRequest $customURL | ConvertFrom-Json
	
	$uptime = New-TimeSpan -Start $SNOdata.startedAt -End $SNOdata.lastPinged
	$ageDiff = (Get-Date) - $satData.earliestJoinedAt
	$age = [System.Math]::Round($ageDiff.TotalDays)
	
	$quicUptime = New-TimeSpan -Start $SNOdata.lastQuicPingedAt -End (Get-Date)
	
	# Wallet balance feature
	$tokenPrice = $tokenData.market_data.current_price.usd
	$balanceInUSD = $tokenPrice * ($walletData.result/100000000)
	$balanceInUSD = [math]::round($balanceInUSD, 2)
	
	Write-Host "`t`t`t`t`t###########" -ForegroundColor Magenta -NoNewline; Write-Host " Nerdboard " -ForegroundColor Green -NoNewline; Write-Host "###############" -ForegroundColor Magenta
	Write-Host "Node ID  : " -ForegroundColor Cyan -NoNewline; Write-Host $SNOdata.nodeID -NoNewline; Write-Host " | " -NoNewline; Write-Host "Age (Days) : " -ForegroundColor Cyan -NoNewline; Write-Host $age
	if ($SNOdata.walletFeatures -eq $null) { $walletFeatures = "None"}
	Write-Host "Wallet   : " -NoNewline -ForegroundColor Cyan ; Write-Host $SNOdata.wallet -ForegroundColor "Red" -NoNewline; Write-Host " | Wallet Features: " -NoNewline;  Write-Host $walletFeatures -ForegroundColor Green
	Write-Host "Uptime   : " -ForegroundColor Cyan -NoNewline; Write-Host $uptime.Days"Days" $uptime.Hours"Hours" $uptime.Minutes"Mins" $uptime.Seconds"Secs" -NoNewline; Write-Host " | " -NoNewline; Write-Host "Tokens : " -ForegroundColor Cyan -NoNewline; Write-Host ($walletData.result/100000000) -ForegroundColor Green -NoNewline; Write-Host " | " -NoNewline; Write-Host "Token in USD : " -ForegroundColor Cyan -NoNewline; Write-Host $balanceInUSD -ForegroundColor Green -NoNewline; Write-Host " | " -NoNewline; Write-Host "1 token (USD) : " -ForegroundColor Cyan -NoNewline; Write-Host $tokenPrice -ForegroundColor Green
	iF($SNOdata.quicStatus -eq "OK") { $fontColor = "Green" } else { $fontColor="Red" }
	Write-Host "Time since last QUIC ping :" -ForegroundColor Cyan -NoNewline; Write-Host $quicUptime.Days"Days" $quicUptime.Hours"Hours" $quicUptime.Minutes"Mins" $quicUptime.Seconds"Secs Ago | " -NoNewline; Write-Host "QUIC status: " -ForegroundColor Cyan -NoNewline; Write-Host $SNOdata.quicStatus -ForegroundColor $fontColor -NoNewline; Write-Host " | " -NoNewline; Write-Host "Configured Port: " -ForegroundColor Cyan -NoNewline; Write-Host $SNOdata.configuredPort
	Write-Host "_______________________________________________________________________________________________________________"
	Write-Host "`t   Current |`tAllowed  |`t Latest Release |`tLatest Release Published on | Is version uptodate?" -ForegroundColor Cyan
	if ($SNOdata.upToDate -eq "True") { $fontColor = "Green" }
	else { $fontColor = "Red" }
	Write-Host "Version  :" $SNOdata.version " |`t" $SNOdata.allowedVersion " |`t" $ver[0].name "`t|`t" $ver[0].published_at "`t    |  " -NoNewline; Write-Host $SNOdata.upToDate -ForegroundColor $fontColor
	Write-Host "______________________________________________________________________________________"
	Write-Host "`t`t Used(GB)`t  |  Allocated(GB) |`t Trash(GB) |`t Overused(GB)" -ForegroundColor Cyan
	Write-Host "DiskSpace: `t" ([math]::round($SNOdata.diskSpace.used/1000000000, 3)) "`t  |`t" ([math]::round($SNOdata.diskSpace.available/1000000000, 3)) "`t   |`t" ([math]::round($SNOdata.diskSpace.trash/1000000000, 3)) "  |`t" ([math]::Round($SNOdata.diskSpace.overused/1000000000, 3))
	Write-Host "Bandwidth: `t" ([math]::round($SNOdata.bandwidth.used/1000000000, 3))
	
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
		
		#Color code audit/suspension/online scores: Less than 99: Yellow ; Less than 96: Red 
		
		if ($satData.audits[$i].auditScore -lt 0.99) { $fontColor = "Yellow" }
		elseif ($satData.audits[$i].auditScore -lt 0.96) { $fontColor = "Red" }
		else { $fontColor = "White" }
		Write-Host ("{0:n7}" -f $satData.audits[$i].auditScore) -NoNewline -ForegroundColor $fontColor
		Write-Host "   |   " -NoNewline
		
		if ($satData.audits[$i].suspensionScore -lt 0.99) { $fontColor = "Yellow" }
		elseif ($satData.audits[$i].suspensionScore -lt 0.96) { $fontColor = "Red" }
		else { $fontColor = "White" }
		Write-Host ("{0:n7}" -f $satData.audits[$i].suspensionScore) -NoNewline -ForegroundColor $fontColor
		Write-Host "      |   " -NoNewline
		
		if ($satData.audits[$i].onlineScore -lt 0.99) { $fontColor = "Yellow" }
		elseif ($satData.audits[$i].onlineScore -lt 0.96) { $fontColor = "Red" }
		else { $fontColor = "White" }
		Write-Host ("{0:n7}" -f $satData.audits[$i].onlineScore) -NoNewline -ForegroundColor $fontColor
		Write-Host "  | " -NoNewline
		
		Write-Host $SNOdata.satellites[$i].url
	}
	
	# Payout Data
	Write-Host "Payout (USD) -> Current Month: " -NoNewline -ForegroundColor Cyan
	Write-Host ('{0:0.##}' -f ([math]::Round($payData.currentMonth.payout, 2)/100)) " | " -NoNewline
	Write-Host "Previous Month: " -NoNewline -ForegroundColor Cyan
	Write-Host ('{0:0.##}' -f ([math]::Round($payData.previousMonth.payout, 2)/100)) " | " -NoNewline
	Write-Host "Current Month Expected : " -NoNewline -ForegroundColor Cyan
	Write-Host ('{0:0.##}' -f ([math]::Round($payData.currentMonthExpectations, 2)/100))
	
	Pause
}while ($true)


	