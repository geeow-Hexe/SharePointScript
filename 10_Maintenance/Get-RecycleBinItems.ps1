<#
.SYNOPSIS
    サイトのごみ箱 (第 1 / 第 2 段階) のアイテムを一覧表示 / CSV 出力します。
.PARAMETER Stage
    All (既定) / First / Second。
.PARAMETER DeletedBy
    削除者のメール アドレスで絞り込みます。
.PARAMETER Since
    この日時以降に削除されたものに絞り込みます。
.PARAMETER OutPath
    出力先 CSV。省略時は画面表示のみ。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Get-RecycleBinItems.ps1 -Since (Get-Date).AddDays(-7)
#>
[CmdletBinding()]
param(
    [ValidateSet('All', 'First', 'Second')][string]$Stage = 'All',
    [string]$DeletedBy,
    [datetime]$Since,
    [string]$OutPath,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPSite -Url $SiteUrl
try {
    $p = @{}
    if ($Stage -eq 'First')  { $p.FirstStage  = $true }
    if ($Stage -eq 'Second') { $p.SecondStage = $true }
    $items = Get-PnPRecycleBinItem @p

    if ($DeletedBy) { $items = $items | Where-Object { $_.DeletedByEmail -eq $DeletedBy } }
    if ($Since)     { $items = $items | Where-Object { $_.DeletedDate.ToLocalTime() -ge $Since } }

    $rows = $items | ForEach-Object {
        [pscustomobject]@{
            Id          = $_.Id
            Title       = $_.Title
            ItemType    = $_.ItemType
            Location    = $_.DirName
            SizeKB      = [math]::Round($_.Size / 1KB, 1)
            DeletedDate = $_.DeletedDate.ToLocalTime()
            DeletedBy   = $_.DeletedByName
            DeletedByEmail = $_.DeletedByEmail
            Stage       = $_.ItemState
        }
    } | Sort-Object DeletedDate -Descending

    if ($OutPath) {
        $rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding utf8BOM
        Write-Log "出力完了: $(@($rows).Count) 件 -> $OutPath" OK
    }
    else {
        $rows | Format-Table Title, ItemType, Location, SizeKB, DeletedDate, DeletedBy, Stage -AutoSize
        Write-Log "合計: $(@($rows).Count) 件" OK
    }
}
finally { Disconnect-SPSite }
