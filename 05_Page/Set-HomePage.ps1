<#
.SYNOPSIS
    サイトのホーム ページを変更します。
.PARAMETER PageName
    SitePages 内のページ名 (例: Welcome または Welcome.aspx)。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Set-HomePage.ps1 -PageName "Welcome"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PageName,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

$PageName = ($PageName -replace '\.aspx$', '') + '.aspx'

Connect-SPSite -Url $SiteUrl
try {
    if (-not (Get-PnPPage -Identity $PageName -ErrorAction SilentlyContinue)) { throw "ページが見つかりません: SitePages/$PageName" }
    Set-PnPHomePage -RootFolderRelativeUrl "SitePages/$PageName"
    Write-Log "ホーム ページを設定しました: SitePages/$PageName" OK
}
finally { Disconnect-SPSite }
