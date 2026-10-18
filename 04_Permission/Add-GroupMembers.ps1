<#
.SYNOPSIS
    SharePoint グループにメンバーを一括追加 (または削除) します。
.DESCRIPTION
    -Members で直接指定するか、-CsvPath で LoginName 列 (または Email 列) を持つ CSV を指定します。
    サンプル: Samples\Members.sample.csv
.PARAMETER Group
    対象グループ名。
.PARAMETER Members
    メール アドレス / ログイン名。
.PARAMETER CsvPath
    LoginName または Email 列を持つ CSV。
.PARAMETER Remove
    追加ではなく削除します。
.PARAMETER Encoding
    CSV の文字コード (既定: utf8)。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Add-GroupMembers.ps1 -Group "総務部 編集者" -CsvPath .\Samples\Members.sample.csv
.EXAMPLE
    .\Add-GroupMembers.ps1 -Group "総務部 編集者" -Members "taro@contoso.com" -Remove
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Group,
    [string[]]$Members,
    [string]$CsvPath,
    [switch]$Remove,
    [string]$Encoding = 'utf8',
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

$targets = @()
if ($Members) { $targets += $Members }
if ($CsvPath) {
    if (-not (Test-Path $CsvPath)) { throw "CSV が見つかりません: $CsvPath" }
    $targets += Import-Csv -Path $CsvPath -Encoding $Encoding | ForEach-Object {
        if ($_.LoginName) { $_.LoginName } elseif ($_.Email) { $_.Email }
    }
}
$targets = $targets | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique
if (-not $targets) { throw "-Members または -CsvPath でメンバーを指定してください。" }

Connect-SPSite -Url $SiteUrl
try {
    if (-not (Get-PnPGroup -Identity $Group -ErrorAction SilentlyContinue)) { throw "グループが見つかりません: $Group" }

    $ok = 0; $ng = 0
    foreach ($m in $targets) {
        try {
            if ($Remove) {
                Remove-PnPGroupMember -Group $Group -LoginName $m
                Write-Log "削除: $m"
            }
            else {
                Add-PnPGroupMember -Group $Group -LoginName $m | Out-Null
                Write-Log "追加: $m"
            }
            $ok++
        }
        catch {
            Write-Log "失敗: $m - $($_.Exception.Message)" ERROR
            $ng++
        }
    }
    Write-Log "完了: 成功 $ok 件 / 失敗 $ng 件" OK
}
finally { Disconnect-SPSite }
