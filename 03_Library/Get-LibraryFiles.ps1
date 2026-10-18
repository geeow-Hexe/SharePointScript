<#
.SYNOPSIS
    ライブラリ (またはその中のフォルダー) のファイルをローカルに一括ダウンロードします。
.DESCRIPTION
    -Recurse 指定時はサブフォルダー構成を維持してダウンロードします。
.PARAMETER Library
    対象ライブラリ名。
.PARAMETER Folder
    ライブラリ内のフォルダー (例: "総務/規程")。省略時はルート。
.PARAMETER LocalPath
    保存先ローカル フォルダー (自動作成)。
.PARAMETER Recurse
    サブフォルダーも対象にします。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Get-LibraryFiles.ps1 -Library "ドキュメント" -Folder "総務" -LocalPath "C:\Backup\総務" -Recurse
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Library,
    [string]$Folder = '',
    [Parameter(Mandatory)][string]$LocalPath,
    [switch]$Recurse,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

if (-not (Test-Path $LocalPath)) { New-Item -ItemType Directory -Path $LocalPath | Out-Null }
$LocalPath = (Resolve-Path $LocalPath).Path

Connect-SPSite -Url $SiteUrl
try {
    $root = Get-SPListRootFolderUrl -List $Library
    $src  = if ($Folder) { "$root/$($Folder.Trim('/').Replace('\', '/'))" } else { $root }
    $web  = Get-PnPWeb
    $srcServerUrl = "$($web.ServerRelativeUrl.TrimEnd('/'))/$src"

    $files = @(Get-PnPFolderItem -FolderSiteRelativeUrl $src -ItemType File -Recursive:$Recurse)
    if ($files.Count -eq 0) { Write-Log "ファイルがありません: $src" WARN; return }

    $i = 0
    foreach ($f in $files) {
        $i++
        $rel    = $f.ServerRelativeUrl.Substring($srcServerUrl.Length).TrimStart('/')
        $relDir = Split-Path $rel -Parent
        $dest   = if ($relDir) { Join-Path $LocalPath $relDir } else { $LocalPath }
        if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }

        Get-PnPFile -Url $f.ServerRelativeUrl -Path $dest -FileName $f.Name -AsFile -Force
        Write-Log "[$i/$($files.Count)] $rel"
    }
    Write-Log "ダウンロード完了: $($files.Count) 件 -> $LocalPath" OK
}
finally { Disconnect-SPSite }
