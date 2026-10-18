<#
.SYNOPSIS
    ライブラリ内の全ファイル一覧 (パス / サイズ / バージョン / 更新者など) を CSV に出力します。
.PARAMETER Library
    対象ライブラリ名。
.PARAMETER OutPath
    出力先 CSV。省略時は Output フォルダーにタイムスタンプ付きで出力します。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Export-FileInventory.ps1 -Library "ドキュメント"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Library,
    [string]$OutPath,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPSite -Url $SiteUrl
try {
    $items = Get-PnPListItem -List $Library -PageSize 2000 -Fields FileLeafRef, FileRef, FSObjType, File_x0020_Size, Modified, Created, Editor, Author, _UIVersionString
    $rows = foreach ($item in $items) {
        $v = $item.FieldValues
        if ([int]$v.FSObjType -ne 0) { continue }
        [pscustomobject]@{
            Name       = $v.FileLeafRef
            Path       = $v.FileRef
            SizeKB     = [math]::Round([double]$v.File_x0020_Size / 1KB, 1)
            Version    = $v._UIVersionString
            Created    = $v.Created.ToLocalTime()
            CreatedBy  = $v.Author.LookupValue
            Modified   = $v.Modified.ToLocalTime()
            ModifiedBy = $v.Editor.LookupValue
        }
    }
    if (-not $OutPath) { $OutPath = Get-SPOutputPath -FileName "FileInventory_$Library.csv" -WithTimestamp }
    $rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding utf8BOM
    Write-Log "出力完了: $(@($rows).Count) ファイル -> $OutPath" OK
}
finally { Disconnect-SPSite }
