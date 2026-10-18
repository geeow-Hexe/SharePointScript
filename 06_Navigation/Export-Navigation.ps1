<#
.SYNOPSIS
    サイト ナビゲーションを CSV に出力します (Set-Navigation.ps1 の入力形式と互換)。
.PARAMETER Location
    QuickLaunch (既定) / TopNavigationBar。
.PARAMETER OutPath
    出力先 CSV。省略時は Output フォルダーにタイムスタンプ付きで出力します。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Export-Navigation.ps1 -Location QuickLaunch
#>
[CmdletBinding()]
param(
    [ValidateSet('QuickLaunch', 'TopNavigationBar')][string]$Location = 'QuickLaunch',
    [string]$OutPath,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPSite -Url $SiteUrl
try {
    $rows = foreach ($n in Get-PnPNavigationNode -Location $Location) {
        [pscustomobject]@{ Title = $n.Title; Url = $n.Url; Parent = ''; External = [int]$n.IsExternal }
        $children = Get-PnPProperty -ClientObject $n -Property Children
        foreach ($c in $children) {
            [pscustomobject]@{ Title = $c.Title; Url = $c.Url; Parent = $n.Title; External = [int]$c.IsExternal }
        }
    }
    if (-not $OutPath) { $OutPath = Get-SPOutputPath -FileName "Navigation_$Location.csv" -WithTimestamp }
    $rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding utf8BOM
    Write-Log "出力完了: $(@($rows).Count) 件 -> $OutPath" OK
}
finally { Disconnect-SPSite }
