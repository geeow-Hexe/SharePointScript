<#
.SYNOPSIS
    リストを作成します (内部 URL は英数字、表示名は日本語という運用を想定)。
.PARAMETER Title
    リストの表示名。
.PARAMETER InternalName
    リストの URL 部分 (例: Requests → /Lists/Requests)。半角英数字を推奨。
.PARAMETER Template
    リスト テンプレート。
.PARAMETER Description
    リストの説明。
.PARAMETER OnQuickLaunch
    クイック起動 (左ナビ) に表示します。
.PARAMETER EnableVersioning
    バージョン管理を有効にします。
.PARAMETER EnableContentTypes
    コンテンツ タイプの管理を有効にします。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\New-List.ps1 -Title "申請一覧" -InternalName "Requests" -OnQuickLaunch -EnableVersioning
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Title,
    [Parameter(Mandatory)][string]$InternalName,
    [ValidateSet('GenericList', 'DocumentLibrary', 'Announcements', 'Contacts', 'Events', 'Links', 'Tasks', 'IssueTracking', 'Survey', 'PictureLibrary')]
    [string]$Template = 'GenericList',
    [string]$Description,
    [switch]$OnQuickLaunch,
    [switch]$EnableVersioning,
    [switch]$EnableContentTypes,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPSite -Url $SiteUrl
try {
    if (Get-PnPList -Identity $Title -ErrorAction SilentlyContinue) {
        Write-Log "同名のリストが既に存在します: $Title" WARN
        return
    }

    $listUrl = if ($Template -in 'DocumentLibrary', 'PictureLibrary') { $InternalName } else { "Lists/$InternalName" }
    $p = @{
        Title              = $Title
        Template           = $Template
        Url                = $listUrl
        OnQuickLaunch      = $OnQuickLaunch
        EnableVersioning   = $EnableVersioning
        EnableContentTypes = $EnableContentTypes
    }
    $list = New-PnPList @p
    if ($Description) { Set-PnPList -Identity $list.Id -Description $Description | Out-Null }

    Write-Log "リストを作成しました: $Title ($listUrl)" OK
    $list
}
finally { Disconnect-SPSite }
