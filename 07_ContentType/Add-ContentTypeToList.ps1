<#
.SYNOPSIS
    リスト / ライブラリにコンテンツ タイプを追加し、必要に応じて既定に設定・不要なものを削除します。
.DESCRIPTION
    コンテンツ タイプの管理が無効な場合は自動で有効化します。
.PARAMETER List
    対象リスト名。
.PARAMETER ContentType
    追加するコンテンツ タイプ名 (複数可)。
.PARAMETER SetFirstAsDefault
    ContentType の先頭を既定のコンテンツ タイプにします。
.PARAMETER RemoveContentType
    リストから削除するコンテンツ タイプ名 (例: "アイテム", "ドキュメント")。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Add-ContentTypeToList.ps1 -List "申請書" -ContentType "申請書" -SetFirstAsDefault -RemoveContentType "ドキュメント"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$List,
    [Parameter(Mandatory)][string[]]$ContentType,
    [switch]$SetFirstAsDefault,
    [string[]]$RemoveContentType,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPSite -Url $SiteUrl
try {
    $l = Get-PnPList -Identity $List -Includes ContentTypesEnabled
    if (-not $l) { throw "リストが見つかりません: $List" }
    if (-not $l.ContentTypesEnabled) {
        Set-PnPList -Identity $List -EnableContentTypes $true | Out-Null
        Write-Log "コンテンツ タイプの管理を有効化しました: $List"
    }

    for ($i = 0; $i -lt $ContentType.Count; $i++) {
        $name = $ContentType[$i]
        if (-not (Get-PnPContentType -Identity $name -ErrorAction SilentlyContinue)) { throw "サイト コンテンツ タイプが見つかりません: $name" }
        $isDefault = ($SetFirstAsDefault -and $i -eq 0)
        Add-PnPContentTypeToList -List $List -ContentType $name -DefaultContentType:$isDefault
        Write-Log "追加しました: $name (既定: $isDefault)" OK
    }

    foreach ($name in $RemoveContentType) {
        Remove-PnPContentTypeFromList -List $List -ContentType $name
        Write-Log "削除しました: $name" OK
    }
}
finally { Disconnect-SPSite }
