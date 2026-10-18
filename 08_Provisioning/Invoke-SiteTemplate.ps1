<#
.SYNOPSIS
    PnP プロビジョニング テンプレートをサイトに適用します。
.PARAMETER Path
    テンプレート ファイル (.xml / .pnp)。
.PARAMETER Parameters
    テンプレート内の {parameter:xxx} に渡す値 (ハッシュテーブル)。
.PARAMETER Handlers
    適用する対象 (例: Lists, Fields, ContentTypes)。省略時はテンプレートに含まれるすべて。
.PARAMETER ClearNavigation
    適用前に既存のナビゲーションをクリアします。
.PARAMETER SiteUrl
    適用先サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Invoke-SiteTemplate.ps1 -Path ..\Output\SiteTemplate.xml -SiteUrl "https://contoso.sharepoint.com/sites/new"
.EXAMPLE
    .\Invoke-SiteTemplate.ps1 -Path .\template.xml -Parameters @{ SiteTitle = "営業部" } -Handlers Lists,Fields
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Path,
    [hashtable]$Parameters,
    [string[]]$Handlers,
    [switch]$ClearNavigation,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

if (-not (Test-Path $Path)) { throw "テンプレートが見つかりません: $Path" }
$Path = (Resolve-Path $Path).Path

Connect-SPSite -Url $SiteUrl
try {
    $p = @{ Path = $Path }
    if ($Parameters)      { $p.Parameters = $Parameters }
    if ($Handlers)        { $p.Handlers = ($Handlers -join ',') }
    if ($ClearNavigation) { $p.ClearNavigation = $true }

    Write-Log "テンプレートを適用しています: $Path"
    Invoke-PnPSiteTemplate @p
    Write-Log "テンプレートの適用が完了しました。" OK
}
finally { Disconnect-SPSite }
