<#
.SYNOPSIS
    サイト内のリスト / ライブラリ一覧 (件数 / 最終更新 / バージョン管理 / 固有権限など) を CSV に出力します。
.PARAMETER IncludeHidden
    非表示リストも含めます。
.PARAMETER OutPath
    出力先 CSV。省略時は Output フォルダーにタイムスタンプ付きで出力します。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Get-SiteListInventory.ps1
#>
[CmdletBinding()]
param(
    [switch]$IncludeHidden,
    [string]$OutPath,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPSite -Url $SiteUrl
try {
    $lists = Get-PnPList -Includes ItemCount, Created, LastItemUserModifiedDate, EnableVersioning, EnableMinorVersions,
                                   HasUniqueRoleAssignments, ContentTypesEnabled, RootFolder, BaseTemplate, BaseType
    if (-not $IncludeHidden) { $lists = $lists | Where-Object { -not $_.Hidden } }

    $rows = $lists | ForEach-Object {
        [pscustomobject]@{
            Title               = $_.Title
            Url                 = $_.RootFolder.ServerRelativeUrl
            BaseType            = $_.BaseType
            BaseTemplate        = $_.BaseTemplate
            ItemCount           = $_.ItemCount
            Created             = $_.Created.ToLocalTime()
            LastModified        = $_.LastItemUserModifiedDate.ToLocalTime()
            Versioning          = $_.EnableVersioning
            MinorVersions       = $_.EnableMinorVersions
            ContentTypesEnabled = $_.ContentTypesEnabled
            UniquePermissions   = $_.HasUniqueRoleAssignments
            Hidden              = $_.Hidden
        }
    }
    if (-not $OutPath) { $OutPath = Get-SPOutputPath -FileName "ListInventory.csv" -WithTimestamp }
    $rows | Sort-Object Title | Export-Csv -Path $OutPath -NoTypeInformation -Encoding utf8BOM
    Write-Log "出力完了: $(@($rows).Count) リスト -> $OutPath" OK
}
finally { Disconnect-SPSite }
