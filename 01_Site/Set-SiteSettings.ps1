<#
.SYNOPSIS
    サイトのタイトル / 説明 / ロゴ / 地域設定を変更します。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.PARAMETER Title
    サイトのタイトル。
.PARAMETER Description
    サイトの説明。
.PARAMETER LogoUrl
    サイト ロゴの URL (サイト内の画像のサーバー相対 URL など)。
.PARAMETER ApplyRegionalSettings
    タイムゾーン / ロケールを適用します (既定は Config の値)。
.PARAMETER TimeZoneId
    適用するタイムゾーン ID (省略時は Config の TimeZoneId)。
.PARAMETER LocaleId
    適用するロケール ID (省略時は Config の Lcid)。
.EXAMPLE
    .\Set-SiteSettings.ps1 -Title "総務部ポータル" -Description "総務部の情報共有サイト" -ApplyRegionalSettings
#>
[CmdletBinding()]
param(
    [string]$SiteUrl,
    [string]$Title,
    [string]$Description,
    [string]$LogoUrl,
    [switch]$ApplyRegionalSettings,
    [int]$TimeZoneId,
    [int]$LocaleId
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPSite -Url $SiteUrl
try {
    $p = @{}
    if ($PSBoundParameters.ContainsKey('Title'))       { $p.Title       = $Title }
    if ($PSBoundParameters.ContainsKey('Description')) { $p.Description = $Description }
    if ($PSBoundParameters.ContainsKey('LogoUrl'))     { $p.SiteLogoUrl = $LogoUrl }
    if ($p.Count -gt 0) {
        Set-PnPWeb @p
        Write-Log "サイト設定を更新しました: $($p.Keys -join ', ')" OK
    }

    if ($ApplyRegionalSettings) {
        $rp = @{}
        if ($TimeZoneId) { $rp.TimeZoneId = $TimeZoneId }
        if ($LocaleId)   { $rp.LocaleId   = $LocaleId }
        Set-SPRegionalSettings @rp
    }

    if ($p.Count -eq 0 -and -not $ApplyRegionalSettings) {
        Write-Log "変更対象のパラメーターが指定されていません。" WARN
    }
}
finally { Disconnect-SPSite }
