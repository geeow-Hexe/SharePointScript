<#
.SYNOPSIS
    ナビゲーションの表示設定 (メガメニュー / 水平ナビ / ヘッダー / フッター) を変更します。
.PARAMETER MegaMenu
    メガメニュー (On / Off)。
.PARAMETER HorizontalQuickLaunch
    クイック起動を水平表示 (On / Off)。チーム サイト向け。
.PARAMETER QuickLaunch
    クイック起動の表示 (On / Off)。
.PARAMETER Footer
    フッターの表示 (On / Off)。コミュニケーション サイト向け。
.PARAMETER HeaderLayout
    ヘッダー レイアウト (Standard / Compact / Minimal / Extended)。
.PARAMETER HeaderEmphasis
    ヘッダーの強調 (None / Neutral / Soft / Strong)。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Set-NavigationSettings.ps1 -MegaMenu On -HeaderLayout Compact -Footer Off
#>
[CmdletBinding()]
param(
    [ValidateSet('On', 'Off')][string]$MegaMenu,
    [ValidateSet('On', 'Off')][string]$HorizontalQuickLaunch,
    [ValidateSet('On', 'Off')][string]$QuickLaunch,
    [ValidateSet('On', 'Off')][string]$Footer,
    [ValidateSet('Standard', 'Compact', 'Minimal', 'Extended')][string]$HeaderLayout,
    [ValidateSet('None', 'Neutral', 'Soft', 'Strong')][string]$HeaderEmphasis,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

$p = @{}
if ($MegaMenu)              { $p.MegaMenuEnabled       = ($MegaMenu -eq 'On') }
if ($HorizontalQuickLaunch) { $p.HorizontalQuickLaunch = ($HorizontalQuickLaunch -eq 'On') }
if ($QuickLaunch)           { $p.QuickLaunchEnabled    = ($QuickLaunch -eq 'On') }
if ($Footer)                { $p.FooterEnabled         = ($Footer -eq 'On') }
if ($HeaderLayout)          { $p.HeaderLayout          = $HeaderLayout }
if ($HeaderEmphasis)        { $p.HeaderEmphasis        = $HeaderEmphasis }
if ($p.Count -eq 0) { throw "変更するパラメーターを 1 つ以上指定してください。" }

Connect-SPSite -Url $SiteUrl
try {
    Set-PnPWeb @p
    Write-Log "ナビゲーション設定を更新しました: $(($p.Keys | ForEach-Object { "$_=$($p[$_])" }) -join ', ')" OK
}
finally { Disconnect-SPSite }
