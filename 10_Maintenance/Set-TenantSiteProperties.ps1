<#
.SYNOPSIS
    サイト コレクションのテナント レベル設定 (ロック / 共有 / カスタム スクリプト / 容量) を変更します。
.DESCRIPTION
    SharePoint 管理者権限が必要です。指定したパラメーターのみ変更します。
.PARAMETER Url
    対象サイト URL。
.PARAMETER LockState
    Unlock / ReadOnly / NoAccess。
.PARAMETER SharingCapability
    Disabled / ExistingExternalUserSharingOnly / ExternalUserSharingOnly / ExternalUserAndGuestSharing。
.PARAMETER CustomScript
    Allow / Deny (カスタム スクリプトの許可。クラシック機能やテンプレート保存に必要な場合は Allow)。
.PARAMETER StorageQuotaMB
    サイトの記憶域クォータ (MB)。テナントの記憶域管理が手動の場合のみ有効。
.PARAMETER Title
    サイト タイトル。
.EXAMPLE
    .\Set-TenantSiteProperties.ps1 -Url "https://contoso.sharepoint.com/sites/old" -LockState ReadOnly
.EXAMPLE
    .\Set-TenantSiteProperties.ps1 -Url "https://contoso.sharepoint.com/sites/portal" -SharingCapability Disabled -CustomScript Allow
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Url,
    [ValidateSet('Unlock', 'ReadOnly', 'NoAccess')][string]$LockState,
    [ValidateSet('Disabled', 'ExistingExternalUserSharingOnly', 'ExternalUserSharingOnly', 'ExternalUserAndGuestSharing')][string]$SharingCapability,
    [ValidateSet('Allow', 'Deny')][string]$CustomScript,
    [long]$StorageQuotaMB,
    [string]$Title
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

$p = @{ Identity = $Url }
if ($LockState)         { $p.LockState = $LockState }
if ($SharingCapability) { $p.SharingCapability = $SharingCapability }
if ($CustomScript)      { $p.DenyAddAndCustomizePages = ($CustomScript -eq 'Deny') }
if ($StorageQuotaMB)    { $p.StorageMaximumLevel = $StorageQuotaMB }
if ($Title)             { $p.Title = $Title }
if ($p.Count -eq 1) { throw "変更するパラメーターを 1 つ以上指定してください。" }

Connect-SPAdmin
try {
    Set-PnPTenantSite @p
    $changed = ($p.Keys | Where-Object { $_ -ne 'Identity' } | ForEach-Object { "$_=$($p[$_])" }) -join ', '
    Write-Log "サイト設定を更新しました: $Url ($changed)" OK
}
finally { Disconnect-SPSite }
