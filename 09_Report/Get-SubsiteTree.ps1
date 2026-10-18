<#
.SYNOPSIS
    サイト コレクション配下のサブサイトを再帰的に一覧表示 / CSV 出力します。
.PARAMETER OutPath
    出力先 CSV。省略時は画面表示のみ。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Get-SubsiteTree.ps1 -OutPath .\subsites.csv
#>
[CmdletBinding()]
param(
    [string]$OutPath,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPSite -Url $SiteUrl
try {
    $root = Get-PnPWeb -Includes Created, WebTemplate, Configuration, LastItemUserModifiedDate
    $subs = Get-PnPSubWeb -Recurse -Includes Created, WebTemplate, Configuration, LastItemUserModifiedDate

    $rows = @($root) + @($subs) | ForEach-Object {
        [pscustomobject]@{
            Title        = $_.Title
            Url          = $_.Url
            Template     = "$($_.WebTemplate)#$($_.Configuration)"
            Created      = $_.Created.ToLocalTime()
            LastModified = $_.LastItemUserModifiedDate.ToLocalTime()
        }
    }
    if ($OutPath) {
        $rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding utf8BOM
        Write-Log "出力完了: $(@($rows).Count) サイト -> $OutPath" OK
    }
    else {
        $rows | Format-Table -AutoSize
    }
}
finally { Disconnect-SPSite }
