<#
.SYNOPSIS
    コミュニケーション サイトを作成します。
.DESCRIPTION
    New-PnPSite でコミュニケーション サイトを作成し、作成後にタイムゾーン / ロケールを
    Config\Settings.ps1 の値 (既定: 東京 / 日本語) に合わせます。
.PARAMETER Title
    サイトのタイトル。
.PARAMETER Url
    サイトの完全 URL (例: https://contoso.sharepoint.com/sites/portal)。
.PARAMETER Description
    サイトの説明。
.PARAMETER SiteDesign
    サイト デザイン (Topic / Showcase / Blank)。
.PARAMETER Owner
    サイト所有者の UPN。省略時は接続ユーザー。
.PARAMETER SkipRegionalSettings
    作成後の地域設定の適用をスキップします。
.EXAMPLE
    .\New-CommunicationSite.ps1 -Title "総務部ポータル" -Url "https://contoso.sharepoint.com/sites/soumu"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Title,
    [Parameter(Mandatory)][string]$Url,
    [string]$Description = "",
    [ValidateSet('Topic', 'Showcase', 'Blank')][string]$SiteDesign = 'Topic',
    [string]$Owner,
    [switch]$SkipRegionalSettings
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPAdmin
try {
    $p = @{ Type = 'CommunicationSite'; Title = $Title; Url = $Url; Lcid = $SPConfig.Lcid; SiteDesign = $SiteDesign; Wait = $true }
    if ($Description) { $p.Description = $Description }
    if ($Owner)       { $p.Owner = $Owner }

    Write-Log "コミュニケーション サイトを作成します: $Url"
    $newUrl = New-PnPSite @p
    Write-Log "作成完了: $newUrl" OK
}
finally { Disconnect-SPSite }

if (-not $SkipRegionalSettings) {
    Connect-SPSite -Url $Url
    try { Set-SPRegionalSettings } finally { Disconnect-SPSite }
}
