<#
.SYNOPSIS
    リスト / ライブラリの設定 (バージョン管理・添付・フォルダー・コンテンツ タイプなど) を変更します。
.DESCRIPTION
    指定したパラメーターのみ変更します。
.PARAMETER List
    対象リスト名。
.PARAMETER Title
    リストの表示名を変更します。
.PARAMETER Description
    説明。
.PARAMETER EnableVersioning
    バージョン管理 ($true / $false)。
.PARAMETER MajorVersions
    保持するメジャー バージョン数。
.PARAMETER EnableMinorVersions
    下書き (マイナー) バージョン ($true / $false)。ライブラリのみ。
.PARAMETER MinorVersions
    保持するマイナー バージョン数。
.PARAMETER EnableAttachments
    添付ファイル ($true / $false)。リストのみ。
.PARAMETER EnableFolderCreation
    フォルダーの作成 ($true / $false)。
.PARAMETER EnableContentTypes
    コンテンツ タイプの管理 ($true / $false)。
.PARAMETER ForceCheckout
    チェックアウトの必須化 ($true / $false)。ライブラリのみ。
.PARAMETER Hidden
    非表示 ($true / $false)。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Set-ListSettings.ps1 -List "申請一覧" -EnableVersioning $true -MajorVersions 100 -EnableAttachments $false
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$List,
    [string]$Title,
    [string]$Description,
    [bool]$EnableVersioning,
    [int]$MajorVersions,
    [bool]$EnableMinorVersions,
    [int]$MinorVersions,
    [bool]$EnableAttachments,
    [bool]$EnableFolderCreation,
    [bool]$EnableContentTypes,
    [bool]$ForceCheckout,
    [bool]$Hidden,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

$passthrough = 'Title', 'Description', 'EnableVersioning', 'MajorVersions', 'EnableMinorVersions', 'MinorVersions',
               'EnableAttachments', 'EnableFolderCreation', 'EnableContentTypes', 'ForceCheckout', 'Hidden'
$p = @{ Identity = $List }
foreach ($name in $passthrough) {
    if ($PSBoundParameters.ContainsKey($name)) { $p[$name] = $PSBoundParameters[$name] }
}
if ($p.Count -eq 1) { throw "変更するパラメーターを 1 つ以上指定してください。" }

Connect-SPSite -Url $SiteUrl
try {
    if (-not (Get-PnPList -Identity $List -ErrorAction SilentlyContinue)) { throw "リストが見つかりません: $List" }
    Set-PnPList @p | Out-Null
    $changed = ($p.Keys | Where-Object { $_ -ne 'Identity' } | ForEach-Object { "$_=$($p[$_])" }) -join ', '
    Write-Log "リスト設定を更新しました: $List ($changed)" OK
}
finally { Disconnect-SPSite }
