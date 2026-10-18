<#
.SYNOPSIS
    サイト コレクションを削除します (確認あり)。
.DESCRIPTION
    Microsoft 365 グループ連携サイトの場合はグループを削除します (サイトは後追いで削除されます)。
    グループ削除には アプリ登録に Graph の Group.ReadWrite.All 権限が必要です。
    それ以外のサイトは Remove-PnPTenantSite で削除します (既定ではごみ箱に移動)。
.PARAMETER Url
    削除するサイトの URL。
.PARAMETER SkipRecycleBin
    ごみ箱を経由せず完全に削除します (グループ非連携サイトのみ)。
.EXAMPLE
    .\Remove-Site.ps1 -Url "https://contoso.sharepoint.com/sites/old"
.EXAMPLE
    .\Remove-Site.ps1 -Url "https://contoso.sharepoint.com/sites/old" -WhatIf
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$Url,
    [switch]$SkipRecycleBin
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPAdmin
try {
    $site = Get-PnPTenantSite -Identity $Url
    Write-Log "対象: $($site.Title) ($($site.Url)) Template=$($site.Template)"

    if ($PSCmdlet.ShouldProcess($Url, "サイトの削除")) {
        if ($site.GroupId -and $site.GroupId -ne [guid]::Empty) {
            Remove-PnPMicrosoft365Group -Identity $site.GroupId
            Write-Log "Microsoft 365 グループを削除しました。サイトは数分以内に自動削除されます。" OK
        }
        else {
            Remove-PnPTenantSite -Url $Url -Force -SkipRecycleBin:$SkipRecycleBin
            Write-Log "サイトを削除しました: $Url" OK
        }
    }
}
finally { Disconnect-SPSite }
