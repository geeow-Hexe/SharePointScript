<#
.SYNOPSIS
    サイトの基本情報 (テンプレート / 作成日 / 地域設定 / 容量 / 管理者など) を表示します。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Get-SiteInfo.ps1
.EXAMPLE
    .\Get-SiteInfo.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/portal" | Format-List
#>
[CmdletBinding()]
param(
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPSite -Url $SiteUrl
try {
    $site   = Get-PnPSite -Includes Usage, Id
    $web    = Get-PnPWeb  -Includes Created, Language, WebTemplate, Configuration, LastItemUserModifiedDate,
                                    RegionalSettings.LocaleId, RegionalSettings.TimeZone
    $admins = Get-PnPSiteCollectionAdmin
    $lists  = Get-PnPList | Where-Object { -not $_.Hidden }

    [pscustomobject]@{
        Title                = $web.Title
        Url                  = $web.Url
        SiteId               = $site.Id
        Template             = "$($web.WebTemplate)#$($web.Configuration)"
        Created              = $web.Created.ToLocalTime()
        LastModified         = $web.LastItemUserModifiedDate.ToLocalTime()
        Language             = $web.Language
        LocaleId             = $web.RegionalSettings.LocaleId
        TimeZone             = $web.RegionalSettings.TimeZone.Description
        StorageUsedMB        = [math]::Round($site.Usage.Storage / 1MB, 1)
        VisibleListCount     = @($lists).Count
        SiteCollectionAdmins = (($admins | ForEach-Object { if ($_.Email) { $_.Email } else { $_.Title } }) -join '; ')
    }
}
finally { Disconnect-SPSite }
