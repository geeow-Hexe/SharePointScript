<#
.SYNOPSIS
    サイトをハブ サイトに関連付け (または関連付け解除) します。
.PARAMETER HubSiteUrl
    ハブ サイトの URL。
.PARAMETER SiteUrl
    関連付けるサイトの URL (複数可)。
.PARAMETER RegisterHub
    HubSiteUrl がハブ サイトとして未登録の場合に登録します。
.PARAMETER Remove
    関連付けを解除します。
.EXAMPLE
    .\Set-HubSiteAssociation.ps1 -HubSiteUrl "https://contoso.sharepoint.com/sites/hub" -SiteUrl "https://contoso.sharepoint.com/sites/a","https://contoso.sharepoint.com/sites/b" -RegisterHub
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$HubSiteUrl,
    [Parameter(Mandatory)][string[]]$SiteUrl,
    [switch]$RegisterHub,
    [switch]$Remove
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPAdmin
try {
    if ($RegisterHub -and -not $Remove) {
        $hub = Get-PnPHubSite -Identity $HubSiteUrl -ErrorAction SilentlyContinue
        if ($hub) {
            Write-Log "ハブ サイトは登録済みです: $HubSiteUrl"
        }
        else {
            Register-PnPHubSite -Site $HubSiteUrl | Out-Null
            Write-Log "ハブ サイトとして登録しました: $HubSiteUrl" OK
        }
    }

    foreach ($s in $SiteUrl) {
        if ($Remove) {
            Remove-PnPHubSiteAssociation -Site $s
            Write-Log "関連付けを解除しました: $s" OK
        }
        else {
            Add-PnPHubSiteAssociation -Site $s -HubSite $HubSiteUrl
            Write-Log "ハブに関連付けました: $s -> $HubSiteUrl" OK
        }
    }
}
finally { Disconnect-SPSite }
