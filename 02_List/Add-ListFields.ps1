<#
.SYNOPSIS
    CSV 定義からリストに列を一括追加します。
.DESCRIPTION
    CSV の列: DisplayName, InternalName, Type, Required, Choices, DefaultValue, AddToDefaultView, LookupList, LookupField
    サンプル: Samples\Fields.sample.csv
    Type: Text / Note / Number / Currency / DateTime / Boolean / Choice / MultiChoice / User / UserMulti / URL / Lookup / LookupMulti
    既存の内部名はスキップされます。
.PARAMETER List
    対象リスト名。
.PARAMETER DefinitionPath
    列定義 CSV のパス。
.PARAMETER Encoding
    CSV の文字コード (既定: utf8。Shift-JIS の場合は "shift_jis")。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Add-ListFields.ps1 -List "申請一覧" -DefinitionPath .\Samples\Fields.sample.csv
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$List,
    [Parameter(Mandatory)][string]$DefinitionPath,
    [string]$Encoding = 'utf8',
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

if (-not (Test-Path $DefinitionPath)) { throw "定義ファイルが見つかりません: $DefinitionPath" }
$definitions = Import-Csv -Path $DefinitionPath -Encoding $Encoding

Connect-SPSite -Url $SiteUrl
try {
    if (-not (Get-PnPList -Identity $List -ErrorAction SilentlyContinue)) { throw "リストが見つかりません: $List" }

    $count = 0
    foreach ($d in $definitions) {
        if ([string]::IsNullOrWhiteSpace($d.InternalName)) { continue }
        Add-SPFieldFromDefinition -Definition $d -List $List | Out-Null
        $count++
    }
    Write-Log "完了: $count 件の列定義を処理しました。" OK
}
finally { Disconnect-SPSite }
