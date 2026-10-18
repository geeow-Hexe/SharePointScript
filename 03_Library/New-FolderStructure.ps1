<#
.SYNOPSIS
    ライブラリ内にフォルダー構成を一括作成します。
.DESCRIPTION
    フォルダーは "部署/総務/2026" のようにスラッシュ区切りで階層指定できます (親フォルダーは自動作成)。
    -Folders で直接指定するか、-DefinitionPath で 1 行 1 パスのテキスト ファイルを指定します。
    サンプル: Samples\Folders.sample.txt
.PARAMETER Library
    対象ライブラリ名 (リストにも使用可)。
.PARAMETER Folders
    作成するフォルダー パス。
.PARAMETER DefinitionPath
    フォルダー パスを列挙したテキスト ファイル (# 始まりはコメント)。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\New-FolderStructure.ps1 -Library "ドキュメント" -Folders "総務/規程","総務/議事録/2026","経理/請求書"
.EXAMPLE
    .\New-FolderStructure.ps1 -Library "ドキュメント" -DefinitionPath .\Samples\Folders.sample.txt
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Library,
    [string[]]$Folders,
    [string]$DefinitionPath,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

$targets = @()
if ($Folders) { $targets += $Folders }
if ($DefinitionPath) {
    if (-not (Test-Path $DefinitionPath)) { throw "定義ファイルが見つかりません: $DefinitionPath" }
    $targets += Get-Content -Path $DefinitionPath -Encoding utf8 | Where-Object { $_ -and $_ -notmatch '^\s*#' }
}
$targets = $targets | ForEach-Object { $_.Trim().Trim('/').Replace('\', '/') } | Where-Object { $_ } | Select-Object -Unique
if (-not $targets) { throw "-Folders または -DefinitionPath でフォルダーを指定してください。" }

Connect-SPSite -Url $SiteUrl
try {
    $root = Get-SPListRootFolderUrl -List $Library
    foreach ($f in $targets) {
        Resolve-PnPFolder -SiteRelativePath "$root/$f" | Out-Null
        Write-Log "フォルダーを確保しました: $root/$f" OK
    }
    Write-Log "完了: $(@($targets).Count) 件" OK
}
finally { Disconnect-SPSite }
