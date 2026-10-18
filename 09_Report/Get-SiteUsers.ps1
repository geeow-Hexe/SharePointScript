<#
.SYNOPSIS
    サイトのユーザー一覧と SharePoint グループのメンバー一覧を CSV に出力します。
.DESCRIPTION
    出力: Users_<timestamp>.csv (サイトユーザー情報リスト) と GroupMembers_<timestamp>.csv (グループ別メンバー)
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\Get-SiteUsers.ps1
#>
[CmdletBinding()]
param(
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPSite -Url $SiteUrl
try {
    $users = Get-PnPUser | ForEach-Object {
        [pscustomobject]@{
            Title         = $_.Title
            Email         = $_.Email
            LoginName     = $_.LoginName
            PrincipalType = $_.PrincipalType
            IsSiteAdmin   = $_.IsSiteAdmin
        }
    }
    $usersPath = Get-SPOutputPath -FileName "Users.csv" -WithTimestamp
    $users | Sort-Object Title | Export-Csv -Path $usersPath -NoTypeInformation -Encoding utf8BOM
    Write-Log "ユーザー一覧: $(@($users).Count) 件 -> $usersPath" OK

    $members = foreach ($g in Get-PnPGroup) {
        foreach ($m in (Get-PnPGroupMember -Group $g)) {
            [pscustomobject]@{
                Group         = $g.Title
                Title         = $m.Title
                Email         = $m.Email
                LoginName     = $m.LoginName
                PrincipalType = $m.PrincipalType
            }
        }
    }
    $membersPath = Get-SPOutputPath -FileName "GroupMembers.csv" -WithTimestamp
    $members | Export-Csv -Path $membersPath -NoTypeInformation -Encoding utf8BOM
    Write-Log "グループ メンバー一覧: $(@($members).Count) 件 -> $membersPath" OK
}
finally { Disconnect-SPSite }
