<#
.SYNOPSIS
    CSV 定義からサイト ナビゲーション (クイック起動 / 上部ナビ) を構築します。
.DESCRIPTION
    CSV の列: Title, Url, Parent, External
      Parent   : 親ノードのタイトル (空なら第 1 階層)。親は先に定義してください。
      External : 外部リンクなら 1 (サイト外 URL を指定する場合)
    サンプル: Samples\Navigation.sample.csv
    チーム サイトの左ナビは QuickLaunch、コミュニケーション サイトの上部メニューは TopNavigationBar を指定します。
.PARAMETER DefinitionPath
    ナビゲーション定義 CSV。
.PARAMETER Location
    QuickLaunch (既定) / TopNavigationBar。
.PARAMETER ClearExisting
    既存のノードを全削除してから作成します。
.PARAMETER Encoding
    CSV の文字コード (既定: utf8)。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Set-Navigation.ps1 -DefinitionPath .\Samples\Navigation.sample.csv -ClearExisting
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$DefinitionPath,
    [ValidateSet('QuickLaunch', 'TopNavigationBar')][string]$Location = 'QuickLaunch',
    [switch]$ClearExisting,
    [string]$Encoding = 'utf8',
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

if (-not (Test-Path $DefinitionPath)) { throw "定義ファイルが見つかりません: $DefinitionPath" }
$nodes = @(Import-Csv -Path $DefinitionPath -Encoding $Encoding | Where-Object { $_.Title })

Connect-SPSite -Url $SiteUrl
try {
    if ($ClearExisting) {
        $existing = @(Get-PnPNavigationNode -Location $Location)
        foreach ($n in $existing) { Remove-PnPNavigationNode -Identity $n.Id -Force }
        Write-Log "既存ノードを削除しました: $($existing.Count) 件 ($Location)" WARN
    }

    $created = @{}
    foreach ($n in $nodes) {
        $p = @{ Location = $Location; Title = $n.Title; Url = $n.Url }
        if (Convert-SPBool $n.External) { $p.External = $true }

        if ($n.Parent) {
            $parentId = $created[$n.Parent]
            if (-not $parentId) {
                $parentNode = Get-PnPNavigationNode -Location $Location | Where-Object Title -eq $n.Parent | Select-Object -First 1
                if ($parentNode) { $parentId = $parentNode.Id }
            }
            if (-not $parentId) { Write-Log "親ノードが見つからないためスキップ: $($n.Title) (Parent=$($n.Parent))" WARN; continue }
            $p.Parent = $parentId
        }

        $node = Add-PnPNavigationNode @p
        $created[$n.Title] = $node.Id
        Write-Log "追加: $(if ($n.Parent) { "$($n.Parent) > " })$($n.Title) -> $($n.Url)" OK
    }
    Write-Log "完了: $($created.Count) 件" OK
}
finally { Disconnect-SPSite }
