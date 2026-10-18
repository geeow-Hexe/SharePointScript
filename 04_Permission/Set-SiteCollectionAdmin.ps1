<#
.SYNOPSIS
    サイト コレクション管理者を追加 / 削除 / 一覧表示します。
.PARAMETER Add
    追加するユーザーのメール アドレス。
.PARAMETER Remove
    削除するユーザーのメール アドレス。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Set-SiteCollectionAdmin.ps1 -Add "admin@contoso.com"
.EXAMPLE
    .\Set-SiteCollectionAdmin.ps1
#>
[CmdletBinding()]
param(
    [string[]]$Add,
    [string[]]$Remove,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPSite -Url $SiteUrl
try {
    if ($Add) {
        Add-PnPSiteCollectionAdmin -Owners $Add
        Write-Log "サイト コレクション管理者を追加しました: $($Add -join ', ')" OK
    }
    if ($Remove) {
        Remove-PnPSiteCollectionAdmin -Owners $Remove
        Write-Log "サイト コレクション管理者を削除しました: $($Remove -join ', ')" OK
    }
    Write-Log "現在のサイト コレクション管理者:"
    Get-PnPSiteCollectionAdmin | Select-Object Title, Email, LoginName
}
finally { Disconnect-SPSite }
