<#
.SYNOPSIS
    サイトの権限割り当て (サイト / 固有権限を持つリスト / グループ メンバー) を CSV に出力します。
.PARAMETER IncludeLists
    固有の権限を持つリスト / ライブラリも出力します。
.PARAMETER IncludeGroupMembers
    各 SharePoint グループのメンバーも出力します。
.PARAMETER OutPath
    出力先 CSV。省略時は Output フォルダーにタイムスタンプ付きで出力します。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Export-PermissionReport.ps1 -IncludeLists -IncludeGroupMembers
#>
[CmdletBinding()]
param(
    [switch]$IncludeLists,
    [switch]$IncludeGroupMembers,
    [string]$OutPath,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

function Get-RoleAssignmentRows {
    param([string]$Scope, [string]$Title, [string]$Url, $RoleAssignments)
    foreach ($ra in $RoleAssignments) {
        Get-PnPProperty -ClientObject $ra -Property Member, RoleDefinitionBindings | Out-Null
        $roles = ($ra.RoleDefinitionBindings | Where-Object { $_.RoleTypeKind -ne 'Guest' } | ForEach-Object Name) -join '; '
        if (-not $roles) { continue }   # 制限付きアクセスのみは除外
        [pscustomobject]@{
            Scope         = $Scope
            Title         = $Title
            Url           = $Url
            Principal     = $ra.Member.Title
            LoginName     = $ra.Member.LoginName
            PrincipalType = $ra.Member.PrincipalType
            Roles         = $roles
        }
    }
}

Connect-SPSite -Url $SiteUrl
try {
    $rows = [System.Collections.Generic.List[object]]::new()

    $web = Get-PnPWeb -Includes RoleAssignments
    Write-Log "サイトの権限を取得中: $($web.Title)"
    Get-RoleAssignmentRows -Scope 'Site' -Title $web.Title -Url $web.Url -RoleAssignments $web.RoleAssignments | ForEach-Object { $rows.Add($_) }

    if ($IncludeLists) {
        $lists = Get-PnPList -Includes HasUniqueRoleAssignments, RoleAssignments, RootFolder |
                 Where-Object { -not $_.Hidden -and $_.HasUniqueRoleAssignments }
        foreach ($l in $lists) {
            Write-Log "固有権限リスト: $($l.Title)"
            Get-RoleAssignmentRows -Scope 'List' -Title $l.Title -Url $l.RootFolder.ServerRelativeUrl -RoleAssignments $l.RoleAssignments | ForEach-Object { $rows.Add($_) }
        }
    }

    if ($IncludeGroupMembers) {
        foreach ($g in Get-PnPGroup) {
            foreach ($m in (Get-PnPGroupMember -Group $g)) {
                $rows.Add([pscustomobject]@{
                    Scope         = 'GroupMember'
                    Title         = $g.Title
                    Url           = $web.Url
                    Principal     = $m.Title
                    LoginName     = $m.LoginName
                    PrincipalType = $m.PrincipalType
                    Roles         = ''
                })
            }
        }
    }

    if (-not $OutPath) { $OutPath = Get-SPOutputPath -FileName "PermissionReport.csv" -WithTimestamp }
    $rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding utf8BOM
    Write-Log "出力完了: $($rows.Count) 行 -> $OutPath" OK
}
finally { Disconnect-SPSite }
