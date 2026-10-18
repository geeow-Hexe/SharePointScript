<#
.SYNOPSIS
    テナント内の全サイト コレクション一覧 (容量 / 最終更新 / 共有設定など) を CSV に出力します。
.DESCRIPTION
    SharePoint 管理者権限が必要です。
.PARAMETER IncludeOneDrive
    OneDrive (個人用サイト) も含めます。
.PARAMETER OutPath
    出力先 CSV。省略時は Output フォルダーにタイムスタンプ付きで出力します。
.EXAMPLE
    .\Get-TenantSiteList.ps1
#>
[CmdletBinding()]
param(
    [switch]$IncludeOneDrive,
    [string]$OutPath
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPAdmin
try {
    Write-Log "サイト一覧を取得しています (件数が多いと時間がかかります)..."
    $sites = Get-PnPTenantSite -Detailed -IncludeOneDriveSites:$IncludeOneDrive
    $rows = $sites | ForEach-Object {
        [pscustomobject]@{
            Title             = $_.Title
            Url               = $_.Url
            Template          = $_.Template
            StorageUsedMB     = $_.StorageUsageCurrent
            StorageQuotaMB    = $_.StorageQuota
            LastContentModified = $_.LastContentModifiedDate
            Owner             = $_.OwnerEmail
            SharingCapability = $_.SharingCapability
            LockState         = $_.LockState
            IsHubSite         = $_.IsHubSite
            HubSiteId         = $_.HubSiteId
            GroupId           = $_.GroupId
        }
    }
    if (-not $OutPath) { $OutPath = Get-SPOutputPath -FileName "TenantSites.csv" -WithTimestamp }
    $rows | Sort-Object Url | Export-Csv -Path $OutPath -NoTypeInformation -Encoding utf8BOM
    Write-Log "出力完了: $(@($rows).Count) サイト -> $OutPath" OK
}
finally { Disconnect-SPSite }
