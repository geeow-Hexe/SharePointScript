<#
.SYNOPSIS
    モダン ページに Web パーツを追加します。
.DESCRIPTION
    指定したセクションが存在しない場合は 1 列セクションを追加します。
    -WebPartType List の場合は -ListTitle を指定すると対象リストが自動設定されます。
    その他の詳細プロパティは -Properties (ハッシュテーブル) で指定できます。
.PARAMETER Page
    ページ名 (例: Welcome または Welcome.aspx)。
.PARAMETER WebPartType
    追加する標準 Web パーツの種類。
.PARAMETER Section
    セクション番号 (1 始まり)。
.PARAMETER Column
    列番号 (1 始まり)。
.PARAMETER Order
    列内の順序 (1 始まり)。
.PARAMETER ListTitle
    (List 用) 表示するリスト名。
.PARAMETER Properties
    Web パーツ プロパティ (ハッシュテーブル)。
.PARAMETER Publish
    追加後にページを発行します。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Add-PageWebPart.ps1 -Page "Welcome" -WebPartType List -ListTitle "お知らせ" -Section 1 -Column 1 -Publish
.EXAMPLE
    .\Add-PageWebPart.ps1 -Page "Welcome" -WebPartType QuickLinks -Section 2 -Publish
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Page,
    [Parameter(Mandatory)]
    [ValidateSet('List', 'News', 'QuickLinks', 'Hero', 'People', 'Events', 'DocumentEmbed', 'Image', 'ImageGallery',
                 'Markdown', 'SiteActivity', 'YouTube', 'Divider', 'Spacer', 'Button', 'CallToAction', 'QuickChart',
                 'LinkPreview', 'ContentEmbed', 'MicrosoftForms', 'PowerBIReportEmbed', 'GroupCalendar', 'Planner',
                 'Weather', 'BingMap', 'VideoEmbed', 'ContentRollup', 'NewsFeed', 'NewsReel', 'PageTitle')]
    [string]$WebPartType,
    [int]$Section = 1,
    [int]$Column = 1,
    [int]$Order = 1,
    [string]$ListTitle,
    [hashtable]$Properties,
    [switch]$Publish,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPSite -Url $SiteUrl
try {
    $pageObj = Get-PnPPage -Identity $Page
    while ($pageObj.Sections.Count -lt $Section) {
        Add-PnPPageSection -Page $pageObj -SectionTemplate OneColumn -Order ($pageObj.Sections.Count + 1)
        $pageObj = Get-PnPPage -Identity $Page
    }

    $props = @{}
    if ($Properties) { $Properties.GetEnumerator() | ForEach-Object { $props[$_.Key] = $_.Value } }
    if ($WebPartType -eq 'List' -and $ListTitle) {
        $list = Get-PnPList -Identity $ListTitle
        if (-not $list) { throw "リストが見つかりません: $ListTitle" }
        $props.selectedListId = $list.Id.ToString()
        if (-not $props.ContainsKey('isDocumentLibrary')) { $props.isDocumentLibrary = ($list.BaseTemplate -eq 101) }
    }

    $p = @{ Page = $pageObj; DefaultWebPartType = $WebPartType; Section = $Section; Column = $Column; Order = $Order }
    if ($props.Count -gt 0) { $p.WebPartProperties = $props }
    Add-PnPPageWebPart @p | Out-Null
    Write-Log "Web パーツを追加しました: $WebPartType -> $Page (Section=$Section Column=$Column Order=$Order)" OK

    if ($Publish) {
        Set-PnPPage -Identity $Page -Publish | Out-Null
        Write-Log "ページを発行しました: $Page" OK
    }
}
finally { Disconnect-SPSite }
