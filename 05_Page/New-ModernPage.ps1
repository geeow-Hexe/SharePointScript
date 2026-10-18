<#
.SYNOPSIS
    モダン ページを作成して発行します。
.PARAMETER Name
    ページのファイル名 (.aspx は不要。例: Welcome)。
.PARAMETER Title
    ページ タイトル。省略時は Name。
.PARAMETER LayoutType
    ページ レイアウト (Article / Home)。
.PARAMETER HeaderLayout
    ヘッダー レイアウト (NoImage / FullWidthImage / ColorBlock / CutInShape)。
.PARAMETER Text
    1 列セクションにテキスト Web パーツとして配置する本文 (HTML 可)。
.PARAMETER PromoteAsNews
    ニュース記事として投稿します。
.PARAMETER SetAsHomePage
    サイトのホーム ページに設定します。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\New-ModernPage.ps1 -Name "Welcome" -Title "ようこそ" -Text "<h2>総務部ポータル</h2><p>各種申請はこちらから</p>" -SetAsHomePage
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Name,
    [string]$Title,
    [ValidateSet('Article', 'Home')][string]$LayoutType = 'Article',
    [ValidateSet('NoImage', 'FullWidthImage', 'ColorBlock', 'CutInShape')][string]$HeaderLayout = 'NoImage',
    [string]$Text,
    [switch]$PromoteAsNews,
    [switch]$SetAsHomePage,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

$Name = $Name -replace '\.aspx$', ''
if (-not $Title) { $Title = $Name }

Connect-SPSite -Url $SiteUrl
try {
    if (Get-PnPPage -Identity $Name -ErrorAction SilentlyContinue) {
        Write-Log "同名のページが既に存在します: $Name.aspx" WARN
        return
    }

    $page = Add-PnPPage -Name $Name -Title $Title -LayoutType $LayoutType -HeaderLayoutType $HeaderLayout
    Write-Log "ページを作成しました: $Name.aspx"

    if ($Text) {
        Add-PnPPageSection -Page $page -SectionTemplate OneColumn -Order 1
        Add-PnPPageTextPart -Page $page -Section 1 -Column 1 -Text $Text | Out-Null
        Write-Log "テキスト Web パーツを追加しました"
    }

    if ($PromoteAsNews) { Set-PnPPage -Identity $page -PromoteAs NewsArticle -Publish | Out-Null }
    else                { Set-PnPPage -Identity $page -Publish | Out-Null }
    Write-Log "ページを発行しました: $Name.aspx" OK

    if ($SetAsHomePage) {
        Set-PnPHomePage -RootFolderRelativeUrl "SitePages/$Name.aspx"
        Write-Log "ホーム ページに設定しました: $Name.aspx" OK
    }
}
finally { Disconnect-SPSite }
