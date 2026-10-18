<#
.SYNOPSIS
    CSV からリスト アイテムを一括登録します。
.DESCRIPTION
    CSV のヘッダー行は列の「内部名」にしてください。空欄の値はスキップされます。
    値の書式:
      日付        2026/04/01 または 2026/04/01 09:00
      ユーザー    メール アドレス (複数は ; 区切り)
      選択肢      表示文字列 (複数選択は ; 区切り)
      参照        参照先アイテムの ID
      はい/いいえ  1 / 0 / true / false
    サンプル: Samples\Items.sample.csv
.PARAMETER List
    対象リスト名。
.PARAMETER CsvPath
    取り込む CSV のパス。
.PARAMETER Encoding
    CSV の文字コード (既定: utf8。Shift-JIS の場合は "shift_jis")。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Import-ListItemsFromCsv.ps1 -List "申請一覧" -CsvPath .\Samples\Items.sample.csv
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$List,
    [Parameter(Mandatory)][string]$CsvPath,
    [string]$Encoding = 'utf8',
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

if (-not (Test-Path $CsvPath)) { throw "CSV が見つかりません: $CsvPath" }
$rows = @(Import-Csv -Path $CsvPath -Encoding $Encoding)
if ($rows.Count -eq 0) { throw "CSV にデータ行がありません。" }

Connect-SPSite -Url $SiteUrl
try {
    $fields = Get-PnPField -List $List | Where-Object { -not $_.ReadOnlyField } | ForEach-Object InternalName
    $multiValueFields = Get-PnPField -List $List |
        Where-Object { $_.TypeAsString -in 'MultiChoice', 'UserMulti', 'LookupMulti' } | ForEach-Object InternalName

    $columns = $rows[0].PSObject.Properties.Name
    $unknown = $columns | Where-Object { $fields -notcontains $_ }
    if ($unknown) { Write-Log "リストに存在しない列は無視します: $($unknown -join ', ')" WARN }
    $target = $columns | Where-Object { $fields -contains $_ }

    $i = 0
    foreach ($row in $rows) {
        $i++
        $values = @{}
        foreach ($col in $target) {
            $v = $row.$col
            if ([string]::IsNullOrWhiteSpace($v)) { continue }
            if ($col -in $multiValueFields) { $v = @($v -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
            $values[$col] = $v
        }
        if ($values.Count -eq 0) { Write-Log "行 $i : 値が空のためスキップ" WARN; continue }
        $item = Add-PnPListItem -List $List -Values $values
        Write-Log "行 $i : 登録しました (ID=$($item.Id))"
    }
    Write-Log "完了: $i 行を処理しました。" OK
}
finally { Disconnect-SPSite }
