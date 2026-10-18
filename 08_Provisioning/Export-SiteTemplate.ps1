<#
.SYNOPSIS
    サイトの構成を PnP プロビジョニング テンプレート (XML / .pnp) として書き出します。
.DESCRIPTION
    開発サイトで構築した リスト / 列 / コンテンツ タイプ / ナビゲーション / ページ などをテンプレート化し、
    Invoke-SiteTemplate.ps1 で別サイトに適用できます。
.PARAMETER OutPath
    出力先 (.xml または .pnp)。省略時は Output フォルダーにタイムスタンプ付き XML。
.PARAMETER Handlers
    書き出す対象 (例: Lists, Fields, ContentTypes, Navigation, Pages, SiteSecurity)。省略時はすべて。
.PARAMETER IncludeBranding
    テーマ / ロゴなどのブランディング ファイルを含めます。
.PARAMETER IncludeAllPages
    すべてのモダン ページを含めます。
.PARAMETER IncludeListData
    データ行も含めるリスト名 (マスタ系リストなど)。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Export-SiteTemplate.ps1 -Handlers Lists,Fields,ContentTypes,Navigation -IncludeListData "部署マスタ"
#>
[CmdletBinding()]
param(
    [string]$OutPath,
    [string[]]$Handlers,
    [switch]$IncludeBranding,
    [switch]$IncludeAllPages,
    [string[]]$IncludeListData,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

if (-not $OutPath) { $OutPath = Get-SPOutputPath -FileName "SiteTemplate.xml" -WithTimestamp }

Connect-SPSite -Url $SiteUrl
try {
    $p = @{ Out = $OutPath; Force = $true }
    if ($Handlers)        { $p.Handlers = ($Handlers -join ',') }
    if ($IncludeBranding) { $p.PersistBrandingFiles = $true }
    if ($IncludeAllPages) { $p.IncludeAllClientSidePages = $true }

    Write-Log "テンプレートを書き出しています..."
    Get-PnPSiteTemplate @p
    Write-Log "テンプレートを書き出しました: $OutPath" OK

    foreach ($l in $IncludeListData) {
        Add-PnPDataRowsToSiteTemplate -Path $OutPath -List $l -Query "<View></View>"
        Write-Log "データ行を追加しました: $l" OK
    }
}
finally { Disconnect-SPSite }
