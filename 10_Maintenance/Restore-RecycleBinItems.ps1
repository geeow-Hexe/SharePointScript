<#
.SYNOPSIS
    ごみ箱のアイテムを条件指定で一括復元します (-WhatIf で事前確認可)。
.PARAMETER DeletedBy
    削除者のメール アドレスで絞り込みます。
.PARAMETER Since
    この日時以降に削除されたものに絞り込みます。
.PARAMETER TitleLike
    名前のワイルドカード (例: "*.xlsx")。
.PARAMETER Location
    元の場所 (DirName) のワイルドカード (例: "sites/sample/Shared Documents/総務*")。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Restore-RecycleBinItems.ps1 -DeletedBy "taro@contoso.com" -Since (Get-Date).AddDays(-1) -WhatIf
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string]$DeletedBy,
    [datetime]$Since,
    [string]$TitleLike,
    [string]$Location,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

if (-not ($DeletedBy -or $Since -or $TitleLike -or $Location)) {
    throw "誤復元防止のため、-DeletedBy / -Since / -TitleLike / -Location のいずれかで条件を指定してください。"
}

Connect-SPSite -Url $SiteUrl
try {
    $items = Get-PnPRecycleBinItem
    if ($DeletedBy) { $items = $items | Where-Object { $_.DeletedByEmail -eq $DeletedBy } }
    if ($Since)     { $items = $items | Where-Object { $_.DeletedDate.ToLocalTime() -ge $Since } }
    if ($TitleLike) { $items = $items | Where-Object { $_.Title -like $TitleLike } }
    if ($Location)  { $items = $items | Where-Object { $_.DirName -like $Location } }
    $items = @($items)

    Write-Log "復元対象: $($items.Count) 件"
    $restored = 0
    foreach ($item in $items) {
        if ($PSCmdlet.ShouldProcess("$($item.DirName)/$($item.Title)", "復元")) {
            Restore-PnPRecycleBinItem -Identity $item.Id -Force
            Write-Log "復元: $($item.DirName)/$($item.Title)" OK
            $restored++
        }
    }
    Write-Log "完了: $restored 件を復元しました。" OK
}
finally { Disconnect-SPSite }
