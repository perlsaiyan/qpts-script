$ApiUrl  = 'https://kallisti.nonserviam.net/api/v1'

If ($Null -eq $env:MUD_USERNAME)
{
    $USERNAME = Read-Host "Username"
}
Else
{
    $USERNAME = $Env:MUD_USERNAME
}

If ($null -eq $env:MUD_PASSWORD) 
{
  $PWD_SECURE = Read-Host "Password" -AsSecureString
}
Else
{
  $PWD_SECURE = ConvertTo-SecureString "$([Environment]::GetEnvironmentVariable('MUD_PASSWORD'))" -AsPlainText -Force
}

$TokenUrl = "$ApiUrl/auth/token/login"
$AuthParams = @{
    "email"=$USERNAME
    "password"= (New-Object PSCredential 0, $PWD_SECURE).GetNetworkCredential().Password
} | ConvertTo-Json

$Token = (Invoke-RestMethod -Uri $TokenUrl -Method Post -Body $AuthParams -ContentType "application/json") 

$Header =  @{
                'Authorization' = "Token $($Token.auth_token)"
            }

$CharUrl = "$ApiUrl/character?page_size=1000"

$Chars = ((Invoke-WebRequest -Uri $CharUrl -Method Get -Header $Header).Content | ConvertFrom-Json).Results

$Chars | Sort-Object level -Descending | Format-Table name, hero_points, level, race_name, cls, hp_cfu, mp_cfu, sp_cfu, skillpoints, qpoints, ancestor, child1, child2

Write-Host ''
Write-Host ('-' * 120)
Write-Host ''

$UnclaimedQps = 0
$TotalQps    = 0

ForEach ( $Char in $Chars )
{
    Write-Host "Char:"
    $Char | Format-Table name, level, race_name, cls, hp_cfu, mp_cfu, sp_cfu, skillpoints, qpoints, ancestor, child1, child2 | Out-Host

    $QuestsUrl = "$ApiUrl/char-quests/$($Char.name)?page_size=1000"
    
    $Quests    = ((Invoke-WebRequest -Uri $QuestsUrl -Method Get -Header $Header).Content | ConvertFrom-Json).Results.char_quests.Where{ ($_.qpoints -gt 0) -and ($_.completed -eq $false) -and ($_.quest_name.contains('Holiday') -eq $False) -and ($_.min_level -le $Char.level) }

    $Quests | Format-Table quest_name, min_level, qpoints, completed

    $Qps = 0

    ForEach ( $Quest in $Quests )
    {
        $Qps += $Quest.qpoints
    }

    Write-Host "Unclaimed Quest Points: [$Qps]."
    
    $UnclaimedQps += $Qps
    $TotalQps     += $Char.qpoints

    Write-Host ''
    Write-Host ('=' * 120)
    Write-Host ''

    Remove-Variable QuestsUrl, Quests, Qps
}

Write-Host ''
Write-Host ('-' * 120)
Write-Host ''

Write-Host "Total Quest points:           [$TotalQps]."
Write-Host "Total Unclaimed Quest Points: [$UnclaimedQps]."

