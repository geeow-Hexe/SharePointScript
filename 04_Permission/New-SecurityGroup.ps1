<#
.SYNOPSIS
    SharePoint グループを作成し、権限レベルとメンバーを設定します。
.DESCRIPTION
    権限レベルは Config\Settings.ps1 の RoleNames で定義した表示名に解決されます。
.PARAMETER GroupName
    グループ名。
.PARAMETER Description
    グループの説明。
.PARAMETER Role
    サイトに対する権限レベル (FullControl / Design / Edit / Contribute / Read)。
.PARAMETER Members
    追加するメンバーのメール アドレス / ログイン名。
.PARAMETER Owner
    グループの所有者 (ユーザーまたはグループ名)。省略時は作成者。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    .\New-SecurityGroup.ps1 -GroupName "総務部 編集者" -Role Edit -Members "taro@contoso.com","hanako@contoso.com"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$GroupName,
    [string]$Description = "",
    [ValidateSet('FullControl', 'Design', 'Edit', 'Contribute', 'Read')][string]$Role = 'Read',
    [string[]]$Members,
    [string]$Owner,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

Connect-SPSite -Url $SiteUrl
try {
    $group = Get-PnPGroup -Identity $GroupName -ErrorAction SilentlyContinue
    if ($group) {
        Write-Log "グループは既に存在します (設定のみ更新): $GroupName" WARN
    }
    else {
        $p = @{ Title = $GroupName; Description = $Description }
        if ($Owner) { $p.Owner = $Owner }
        $group = New-PnPGroup @p
        Write-Log "グループを作成しました: $GroupName" OK
    }

    $roleName = Get-SPRoleName -Role $Role
    Set-PnPGroupPermissions -Identity $GroupName -AddRole $roleName
    Write-Log "権限を付与しました: $GroupName -> $roleName" OK

    foreach ($m in $Members) {
        Add-PnPGroupMember -Group $GroupName -LoginName $m | Out-Null
        Write-Log "メンバーを追加しました: $m"
    }
    $group
}
finally { Disconnect-SPSite }
