
Function Get-ApiHeader
{
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

    Return $Header
}

Function Get-Chars
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)] [hashtable] $Header
    )
    
    $ApiUrl  = 'https://kallisti.nonserviam.net/api/v1'
    $CharUrl = "$ApiUrl/character?page_size=1000"

    $Chars = ((Invoke-WebRequest -Uri $CharUrl -Method Get -Header $Header).Content | ConvertFrom-Json).Results

    ForEach ( $Char in $Chars )
    {
        $QuestsUrl = "$ApiUrl/char-quests/$($Char.name)?page_size=1000"
        $Quests    = ((Invoke-WebRequest -Uri $QuestsUrl -Method Get -Header $Header).Content | ConvertFrom-Json).Results.char_quests.Where{ ($_.qpoints -gt 0) -and ($_.completed -eq $false) -and ($_.min_level -le $Char.level) }
        
        $Char   | Add-Member -MemberType NoteProperty -Name Quests -Value $Quests

        Remove-Variable QuestsUrl, Quests
    }

    Return ($Chars | Sort-Object name)
}


Function Get-CharsNeedingQuest
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)] [PSCustomObject[]] $Chars,
        [Parameter(Mandatory=$true)] [string]           $Quest
    )

    $Chars.Where{ $_.quests.quest_name -eq $quest }.name | Sort-Object
}

Function Get-QuestsForChar
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)] [PSCustomObject[]] $Chars,
        [Parameter(Mandatory=$true)] [string]           $CharName
    )

    $Chars.Where{ $_.name -eq $CharName }.Quests | Sort-Object quest_name
}

Function Get-CharsQuestList
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)] [PSCustomObject[]] $Chars
    )

    $QuestList = $Chars.Quests.quest_name | Sort-Object | Get-Unique

    ForEach ( $Quest in $QuestList )
    {
        $CharsNeedingQuest = $Chars.Where{ $_.Quests.quest_name -eq $Quest }
        $QptValue = ($CharsNeedingQuest.quests.where{ $_.quest_name -eq $Quest } | Select-Object -First 1).qpoints
        
        Write-Host "QuestName:  [$($Quest)]"
        Write-Host "Qpts Value: [$QptValue]"
        Write-Host "TotalValue: [$($QptValue * $CharsNeedingQuest.Count)]"
        
        Write-Host "Chars needing quest:"
        $CharsNeedingQuest.Name | Sort-Object | Out-Host

        Write-Host ('-' * 60)
    }
}