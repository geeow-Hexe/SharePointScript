<#
.SYNOPSIS
    ドキュメント ライブラリを作成します。
.PARAMETER Title
    ライブラリの表示名。
.PARAMETER InternalName
    ライブラリの URL 部分 (例: Contracts → /Contracts)。半角英数字を推奨。
.PARAMETER Description
    説明。
.PARAMETER OnQuickLaunch
    クイック起動 (左ナビ) に表示します。
.PARAMETER MajorVersions
    保持するメジャー バージョン数 (既定: 500)。
.PARAMETER EnableMinorVersions
    下書き (マイナー) バージョンを有効にします。
.PARAMETER EnableContentTypes
    コンテンツ タイプの管理を有効にします。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\New-DocumentLibrary.ps1 -Title "契約書" -InternalName "Contracts" -OnQuickLaunch -EnableMinorVersions
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Title,
    [Parameter(Mandatory)][string]$InternalName,
    [string]$Description,
    [switch]$OnQuickLaunch,
    [int]$MajorVersions = 500,
    [switch]$EnableMinorVersions,
    [switch]$EnableContentTypes,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPSite -Url $SiteUrl
try {
    if (Get-PnPList -Identity $Title -ErrorAction SilentlyContinue) {
        Write-Log "同名のライブラリが既に存在します: $Title" WARN
        return
    }
    $lib = New-PnPList -Title $Title -Template DocumentLibrary -Url $InternalName -OnQuickLaunch:$OnQuickLaunch -EnableVersioning -EnableContentTypes:$EnableContentTypes

    $p = @{ Identity = $lib.Id; MajorVersions = $MajorVersions; EnableMinorVersions = $EnableMinorVersions }
    if ($Description) { $p.Description = $Description }
    Set-PnPList @p | Out-Null

    Write-Log "ライブラリを作成しました: $Title (/$InternalName)" OK
    $lib
}
finally { Disconnect-SPSite }
