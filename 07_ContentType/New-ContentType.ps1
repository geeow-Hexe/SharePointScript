<#
.SYNOPSIS
    サイト コンテンツ タイプを作成し、サイト列を関連付けます。
.PARAMETER Name
    コンテンツ タイプ名。
.PARAMETER Group
    コンテンツ タイプ グループ名。
.PARAMETER ParentContentType
    親コンテンツ タイプの名前または ID (既定: 0x01 = アイテム。ドキュメントは 0x0101)。
.PARAMETER Description
    説明。
.PARAMETER Fields
    関連付けるサイト列の内部名。
.PARAMETER RequiredFields
    必須にするサイト列の内部名 (Fields にも含めてください)。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\New-ContentType.ps1 -Name "申請書" -Group "社内コンテンツ タイプ" -ParentContentType 0x0101 -Fields "Department","ApprovalStatus" -RequiredFields "Department"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Name,
    [string]$Group = "カスタム コンテンツ タイプ",
    [string]$ParentContentType = "0x01",
    [string]$Description = "",
    [string[]]$Fields,
    [string[]]$RequiredFields,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPSite -Url $SiteUrl
try {
    $ct = Get-PnPContentType -Identity $Name -ErrorAction SilentlyContinue
    if ($ct) {
        Write-Log "コンテンツ タイプは既に存在します (列の関連付けのみ実施): $Name" WARN
    }
    else {
        $parent = Get-PnPContentType -Identity $ParentContentType -ErrorAction SilentlyContinue
        if (-not $parent) { throw "親コンテンツ タイプが見つかりません: $ParentContentType" }
        $ct = Add-PnPContentType -Name $Name -Group $Group -Description $Description -ParentContentType $parent
        Write-Log "コンテンツ タイプを作成しました: $Name (ID=$($ct.Id)) 親=$($parent.Name)" OK
    }

    foreach ($f in $Fields) {
        if (-not (Get-PnPField -Identity $f -ErrorAction SilentlyContinue)) { Write-Log "サイト列が見つかりません: $f" WARN; continue }
        $required = ($RequiredFields -contains $f)
        Add-PnPFieldToContentType -Field $f -ContentType $ct -Required:$required
        Write-Log "列を関連付けました: $f (必須: $required)" OK
    }
    $ct
}
finally { Disconnect-SPSite }
