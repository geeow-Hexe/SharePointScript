<#
.SYNOPSIS
    リスト / ライブラリの権限継承の制御と、グループ / ユーザーへの権限付与・削除を行います。
.PARAMETER List
    対象リスト名。
.PARAMETER BreakInheritance
    親からの権限継承を解除します。
.PARAMETER CopyRoleAssignments
    継承解除時に親の権限をコピーします (省略時は空の状態から開始)。
.PARAMETER ResetInheritance
    権限継承を元に戻します (固有の権限を破棄)。
.PARAMETER Principal
    権限を付与 / 削除する対象 (グループ名、またはユーザーのメール アドレス)。
.PARAMETER PrincipalType
    Principal の種類 (Group / User)。
.PARAMETER AddRole
    付与する権限レベル (FullControl / Design / Edit / Contribute / Read)。
.PARAMETER RemoveRole
    削除する権限レベル。
.PARAMETER SiteUrl
    対象サイト URL。省略時は Config\Settings.ps1 の SiteUrl。
.EXAMPLE
    # 継承を解除し (親の権限はコピーしない)、グループに編集権限を付与
    .\Set-ListPermission.ps1 -List "人事評価" -BreakInheritance -Principal "人事部 編集者" -PrincipalType Group -AddRole Edit
.EXAMPLE
    .\Set-ListPermission.ps1 -List "人事評価" -ResetInheritance
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$List,
    [switch]$BreakInheritance,
    [switch]$CopyRoleAssignments,
    [switch]$ResetInheritance,
    [string]$Principal,
    [ValidateSet('Group', 'User')][string]$PrincipalType = 'Group',
    [ValidateSet('FullControl', 'Design', 'Edit', 'Contribute', 'Read')][string]$AddRole,
    [ValidateSet('FullControl', 'Design', 'Edit', 'Contribute', 'Read')][string]$RemoveRole,
    [string]$SiteUrl
)
. (Join-Path $PSScriptRoot "..\Common\Common.ps1")

if ($BreakInheritance -and $ResetInheritance) { throw "-BreakInheritance と -ResetInheritance は同時に指定できません。" }
if ($Principal -and -not ($AddRole -or $RemoveRole)) { throw "-Principal を指定する場合は -AddRole または -RemoveRole も指定してください。" }

Connect-SPSite -Url $SiteUrl
try {
    if (-not (Get-PnPList -Identity $List -ErrorAction SilentlyContinue)) { throw "リストが見つかりません: $List" }

    if ($ResetInheritance) {
        Set-PnPList -Identity $List -ResetRoleInheritance | Out-Null
        Write-Log "権限継承を元に戻しました: $List" OK
    }
    if ($BreakInheritance) {
        Set-PnPList -Identity $List -BreakRoleInheritance -CopyRoleAssignments:$CopyRoleAssignments -ClearSubscopes | Out-Null
        Write-Log "権限継承を解除しました: $List (親の権限コピー: $CopyRoleAssignments)" OK
    }

    if ($Principal) {
        $p = @{ Identity = $List }
        if ($PrincipalType -eq 'Group') { $p.Group = $Principal } else { $p.User = $Principal }
        if ($AddRole)    { $p.AddRole    = Get-SPRoleName -Role $AddRole }
        if ($RemoveRole) { $p.RemoveRole = Get-SPRoleName -Role $RemoveRole }
        Set-PnPListPermission @p
        Write-Log "権限を更新しました: $List / $Principal (追加: $($p.AddRole) 削除: $($p.RemoveRole))" OK
    }
}
finally { Disconnect-SPSite }
