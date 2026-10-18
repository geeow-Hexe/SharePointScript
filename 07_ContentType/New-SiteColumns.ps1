<#
.SYNOPSIS
    CSV 定義からサイト列を一括作成します。
.DESCRIPTION
    CSV の列: DisplayName, InternalName, Type, Required, Choices, DefaultValue, Group, LookupList, LookupField
    形式は 02_List\Add-ListFields.ps1 と共通です (Group 列でサイト列グループを指定)。
    サンプル: Samples\SiteColumns.sample.csv
.PARAMETER DefinitionPath
    サイト列定義 CSV。
.PARAMETER Encoding
    CSV の文字コード (既定: utf8)。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\New-SiteColumns.ps1 -DefinitionPath .\Samples\SiteColumns.sample.csv
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$DefinitionPath,
    [string]$Encoding = 'utf8',
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

if (-not (Test-Path $DefinitionPath)) { throw "定義ファイルが見つかりません: $DefinitionPath" }
$definitions = Import-Csv -Path $DefinitionPath -Encoding $Encoding

Connect-SPSite -Url $SiteUrl
try {
    $count = 0
    foreach ($d in $definitions) {
        if ([string]::IsNullOrWhiteSpace($d.InternalName)) { continue }
        Add-SPFieldFromDefinition -Definition $d | Out-Null
        $count++
    }
    Write-Log "完了: $count 件のサイト列定義を処理しました。" OK
}
finally { Disconnect-SPSite }
