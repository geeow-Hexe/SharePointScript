<#
.SYNOPSIS
    チーム サイトを作成します (Microsoft 365 グループ連携 / 非連携の両方に対応)。
.DESCRIPTION
    -Alias を指定するとグループ連携のチーム サイト、-Url を指定するとグループ非連携のチーム サイトを作成します。
    作成後にタイムゾーン / ロケールを Config\Settings.ps1 の値に合わせます。
.PARAMETER Title
    サイトのタイトル。
.PARAMETER Alias
    (グループ連携) サイト / グループのエイリアス。URL は https://<tenant>.sharepoint.com/sites/<Alias> になります。
.PARAMETER IsPublic
    (グループ連携) パブリック グループとして作成します。既定はプライベート。
.PARAMETER Owners
    (グループ連携) 所有者の UPN。
.PARAMETER Members
    (グループ連携) メンバーの UPN。
.PARAMETER Url
    (グループ非連携) サイトの完全 URL。
.PARAMETER Owner
    (グループ非連携) サイト所有者の UPN。
.PARAMETER Description
    サイトの説明。
.PARAMETER SkipRegionalSettings
    作成後の地域設定の適用をスキップします。
.EXAMPLE
    .\New-TeamSite.ps1 -Title "営業チーム" -Alias "sales" -Owners "taro@contoso.com"
.EXAMPLE
    .\New-TeamSite.ps1 -Title "業務システム" -Url "https://contoso.sharepoint.com/sites/gyomu" -Owner "taro@contoso.com"
#>
[CmdletBinding(DefaultParameterSetName = 'Group')]
param(
    [Parameter(Mandatory)][string]$Title,
    [Parameter(Mandatory, ParameterSetName = 'Group')][string]$Alias,
    [Parameter(ParameterSetName = 'Group')][switch]$IsPublic,
    [Parameter(ParameterSetName = 'Group')][string[]]$Owners,
    [Parameter(ParameterSetName = 'Group')][string[]]$Members,
    [Parameter(Mandatory, ParameterSetName = 'NoGroup')][string]$Url,
    [Parameter(ParameterSetName = 'NoGroup')][string]$Owner,
    [string]$Description = "",
    [switch]$SkipRegionalSettings
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPAdmin
try {
    if ($PSCmdlet.ParameterSetName -eq 'Group') {
        $p = @{ Type = 'TeamSite'; Title = $Title; Alias = $Alias; IsPublic = $IsPublic; Lcid = $SPConfig.Lcid; Wait = $true }
        if ($Owners)  { $p.Owners  = $Owners }
        if ($Members) { $p.Members = $Members }
        Write-Log "チーム サイト (グループ連携) を作成します: alias=$Alias"
    }
    else {
        $p = @{ Type = 'TeamSiteWithoutMicrosoft365Group'; Title = $Title; Url = $Url; Lcid = $SPConfig.Lcid; Wait = $true }
        if ($Owner) { $p.Owner = $Owner }
        Write-Log "チーム サイト (グループ非連携) を作成します: $Url"
    }
    if ($Description) { $p.Description = $Description }

    $newUrl = New-PnPSite @p
    Write-Log "作成完了: $newUrl" OK
}
finally { Disconnect-SPSite }

if (-not $SkipRegionalSettings -and $newUrl) {
    Connect-SPSite -Url $newUrl
    try { Set-SPRegionalSettings } finally { Disconnect-SPSite }
}
