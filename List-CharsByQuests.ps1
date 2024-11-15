
Set-Location $PSScriptRoot

Import-Module .\QuestPoints.psm1

$Header = Get-ApiHeader

$Chars = Get-Chars -Header $Header

Get-CharsQuestList -Chars $Chars
