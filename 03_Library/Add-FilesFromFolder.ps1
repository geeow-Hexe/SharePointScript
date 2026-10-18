<#
.SYNOPSIS
    ローカル フォルダー内のファイルをライブラリに一括アップロードします。
.DESCRIPTION
    -Recurse 指定時はサブフォルダー構成を維持したままアップロードします。同名ファイルは上書きされます。
.PARAMETER LocalPath
    アップロード元のローカル フォルダー。
.PARAMETER Library
    アップロード先ライブラリ名。
.PARAMETER TargetFolder
    ライブラリ内の格納先フォルダー (例: "総務/規程")。省略時はルート。
.PARAMETER Recurse
    サブフォルダーも対象にします。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Add-FilesFromFolder.ps1 -LocalPath "C:\Upload" -Library "ドキュメント" -TargetFolder "総務/規程" -Recurse
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$LocalPath,
    [Parameter(Mandatory)][string]$Library,
    [string]$TargetFolder = '',
    [switch]$Recurse,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

if (-not (Test-Path $LocalPath -PathType Container)) { throw "フォルダーが見つかりません: $LocalPath" }
$localRoot = (Resolve-Path $LocalPath).Path
$files = @(Get-ChildItem -Path $localRoot -File -Recurse:$Recurse)
if ($files.Count -eq 0) { Write-Log "アップロード対象のファイルがありません。" WARN; return }

Connect-SPSite -Url $SiteUrl
try {
    $root = Get-SPListRootFolderUrl -List $Library
    $base = if ($TargetFolder) { "$root/$($TargetFolder.Trim('/').Replace('\', '/'))" } else { $root }
    Resolve-PnPFolder -SiteRelativePath $base | Out-Null

    $ensured = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    [void]$ensured.Add($base)
    $i = 0
    foreach ($file in $files) {
        $i++
        $rel = [IO.Path]::GetRelativePath($localRoot, $file.DirectoryName).Replace('\', '/')
        $target = if ($rel -eq '.') { $base } else { "$base/$rel" }
        if ($ensured.Add($target)) { Resolve-PnPFolder -SiteRelativePath $target | Out-Null }

        Add-PnPFile -Path $file.FullName -Folder $target | Out-Null
        Write-Log "[$i/$($files.Count)] $($file.Name) -> $target"
    }
    Write-Log "アップロード完了: $($files.Count) 件" OK
}
finally { Disconnect-SPSite }
