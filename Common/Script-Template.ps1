<#
.SYNOPSIS
    新しいスクリプトを作成するときの雛形です。コピーして使用してください。
.DESCRIPTION
    (スクリプトの説明)
.PARAMETER SiteUrl
    操作対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Script-Template.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/sample"
#>
[CmdletBinding()]
param(
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPSite -Url $SiteUrl
try {
    # ここに処理を記述
    $web = Get-PnPWeb
    Write-Log "サイト: $($web.Title)" OK
}
finally {
    Disconnect-SPSite
}
