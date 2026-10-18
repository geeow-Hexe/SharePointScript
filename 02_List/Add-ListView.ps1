<#
.SYNOPSIS
    リストにビューを追加します。
.PARAMETER List
    対象リスト名。
.PARAMETER Title
    ビュー名。
.PARAMETER Fields
    表示する列の内部名 (順序どおり)。
.PARAMETER Query
    CAML クエリ (<Where>...</Where><OrderBy>...</OrderBy> 形式)。
.PARAMETER RowLimit
    1 ページの表示件数 (既定: 30)。
.PARAMETER SetAsDefault
    既定のビューにします。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Add-ListView.ps1 -List "申請一覧" -Title "承認待ち" -Fields "Title","Status","Author","Created" -Query "<Where><Eq><FieldRef Name='Status'/><Value Type='Choice'>承認待ち</Value></Eq></Where><OrderBy><FieldRef Name='Created' Ascending='FALSE'/></OrderBy>"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$List,
    [Parameter(Mandatory)][string]$Title,
    [Parameter(Mandatory)][string[]]$Fields,
    [string]$Query,
    [int]$RowLimit = 30,
    [switch]$SetAsDefault,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPSite -Url $SiteUrl
try {
    if (Get-PnPView -List $List -Identity $Title -ErrorAction SilentlyContinue) {
        Write-Log "同名のビューが既に存在します: $Title" WARN
        return
    }
    $p = @{ List = $List; Title = $Title; Fields = $Fields; RowLimit = $RowLimit; Paged = $true; SetAsDefault = $SetAsDefault }
    if ($Query) { $p.Query = $Query }

    $view = Add-PnPView @p
    Write-Log "ビューを作成しました: $List / $Title" OK
    $view
}
finally { Disconnect-SPSite }
