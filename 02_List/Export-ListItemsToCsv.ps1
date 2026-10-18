<#
.SYNOPSIS
    リスト アイテムを CSV にエクスポートします。
.DESCRIPTION
    ユーザー / 参照 / URL 列は表示値に変換し、日時はローカル時刻にします。
    -Fields 省略時は既定ビューの列 + ID を出力します。
.PARAMETER List
    対象リスト名。
.PARAMETER Fields
    出力する列の内部名。
.PARAMETER Query
    CAML クエリによる絞り込み。
.PARAMETER OutPath
    出力先 CSV。省略時は Output フォルダーにタイムスタンプ付きで出力します。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Export-ListItemsToCsv.ps1 -List "申請一覧" -Fields "ID","Title","Status","Author","Created"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$List,
    [string[]]$Fields,
    [string]$Query,
    [string]$OutPath,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

function ConvertTo-PlainValue {
    param($Value)
    if ($null -eq $Value) { return '' }
    if ($Value -is [string]) { return $Value }
    if ($Value -is [datetime]) { return $Value.ToLocalTime().ToString('yyyy/MM/dd HH:mm:ss') }
    if ($Value -is [System.Collections.IEnumerable]) {
        return (($Value | ForEach-Object { ConvertTo-PlainValue $_ }) -join '; ')
    }
    switch ($Value.GetType().Name) {
        'FieldUserValue'     { if ($Value.Email) { return $Value.Email } else { return $Value.LookupValue } }
        'FieldLookupValue'   { return $Value.LookupValue }
        'FieldUrlValue'      { return $Value.Url }
        'TaxonomyFieldValue' { return $Value.Label }
        default              { return [string]$Value }
    }
}

Connect-SPSite -Url $SiteUrl
try {
    if (-not $Fields) {
        $view   = Get-PnPView -List $List -Includes ViewFields, DefaultView | Where-Object DefaultView | Select-Object -First 1
        $Fields = @('ID') + @($view.ViewFields | Where-Object { $_ -ne 'ID' })
    }
    $p = @{ List = $List; PageSize = 1000; Fields = $Fields }
    if ($Query) { $p.Query = $Query }

    $items = Get-PnPListItem @p
    $rows  = foreach ($item in $items) {
        $o = [ordered]@{}
        foreach ($f in $Fields) { $o[$f] = ConvertTo-PlainValue $item.FieldValues[$f] }
        [pscustomobject]$o
    }

    if (-not $OutPath) { $OutPath = Get-SPOutputPath -FileName "ListItems_$List.csv" -WithTimestamp }
    $rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding utf8BOM
    Write-Log "エクスポート完了: $(@($rows).Count) 件 -> $OutPath" OK
}
finally { Disconnect-SPSite }
