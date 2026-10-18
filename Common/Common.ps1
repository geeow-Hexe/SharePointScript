<#
.SYNOPSIS
    全スクリプト共通の設定読み込みと共通関数。
.DESCRIPTION
    各スクリプトの先頭で次のようにドットソースして使用します。

        . (Join-Path $PSScriptRoot "..\Common\Common.ps1")

    設定は Config\Settings.ps1 (存在すれば続けて Settings.local.ps1) から読み込まれ、
    $SPConfig として参照できます。
#>
#Requires -Version 7.2

$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------------------------
# 設定読み込み
# ------------------------------------------------------------------------------
$RepoRoot  = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ConfigDir = Join-Path $RepoRoot "Config"

. (Join-Path $ConfigDir "Settings.ps1")
$localSettings = Join-Path $ConfigDir "Settings.local.ps1"
if (Test-Path $localSettings) { . $localSettings }

if (-not $SPConfig.AdminUrl)  { $SPConfig.AdminUrl  = "https://$($SPConfig.TenantName)-admin.sharepoint.com" }
if (-not $SPConfig.Tenant)    { $SPConfig.Tenant    = "$($SPConfig.TenantName).onmicrosoft.com" }
if (-not $SPConfig.OutputDir) { $SPConfig.OutputDir = Join-Path $RepoRoot "Output" }

# ------------------------------------------------------------------------------
# ログ
# ------------------------------------------------------------------------------
function Write-Log {
    <# 色付きのタイムスタンプ付きログを出力します。 #>
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO', 'OK', 'WARN', 'ERROR')][string]$Level = 'INFO'
    )
    $color = switch ($Level) {
        'OK'    { 'Green' }
        'WARN'  { 'Yellow' }
        'ERROR' { 'Red' }
        default { 'Cyan' }
    }
    Write-Host ("[{0}] [{1,-5}] {2}" -f (Get-Date -Format 'HH:mm:ss'), $Level, $Message) -ForegroundColor $color
}

# ------------------------------------------------------------------------------
# 前提チェック
# ------------------------------------------------------------------------------
function Assert-PnPModule {
    <# PnP.PowerShell がインストール済みであることを確認し、読み込みます。 #>
    if (Get-Module -Name PnP.PowerShell) { return }
    if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
        throw "PnP.PowerShell がインストールされていません。次を実行してください:`n  Install-Module PnP.PowerShell -Scope CurrentUser"
    }
    Import-Module PnP.PowerShell
}

function Assert-SPConfig {
    <# Config\Settings.ps1 が編集済みであることを確認します。 #>
    if (-not $SPConfig.AppId -or $SPConfig.AppId -match '^0{8}-0{4}-0{4}-0{4}-0{12}$') {
        throw "Config\Settings.ps1 の AppId が未設定です。Entra ID のアプリ登録 ID を設定してください。"
    }
    if (-not $SPConfig.TenantName -or $SPConfig.TenantName -eq 'contoso') {
        Write-Log "TenantName が既定値 (contoso) のままです。Config\Settings.ps1 を確認してください。" WARN
    }
}

# ------------------------------------------------------------------------------
# 接続 / 切断
# ------------------------------------------------------------------------------
function Connect-SPSite {
    <#
    .SYNOPSIS
        Config の認証設定を使って SharePoint サイトに接続します。
    .PARAMETER Url
        接続先サイト URL。省略時は $SPConfig.SiteUrl。
    #>
    [CmdletBinding()]
    param([string]$Url)

    Assert-PnPModule
    Assert-SPConfig
    if ([string]::IsNullOrWhiteSpace($Url)) { $Url = $SPConfig.SiteUrl }

    $p = @{ Url = $Url; ClientId = $SPConfig.AppId }
    switch ($SPConfig.AuthMode) {
        'Interactive' { $p.Interactive = $true }
        'DeviceLogin' { $p.DeviceLogin = $true }
        'Certificate' {
            if (-not (Test-Path $SPConfig.CertificatePath)) { throw "証明書が見つかりません: $($SPConfig.CertificatePath)" }
            $p.Tenant          = $SPConfig.Tenant
            $p.CertificatePath = $SPConfig.CertificatePath
            if ($SPConfig.CertificatePassword) {
                $p.CertificatePassword = ConvertTo-SecureString $SPConfig.CertificatePassword -AsPlainText -Force
            }
        }
        'Thumbprint' {
            $p.Tenant     = $SPConfig.Tenant
            $p.Thumbprint = $SPConfig.CertificateThumbprint
        }
        default { throw "未対応の AuthMode です: $($SPConfig.AuthMode)" }
    }

    Write-Log "接続中: $Url  (認証: $($SPConfig.AuthMode))"
    Connect-PnPOnline @p
    Write-Log "接続完了: $Url" OK
}

function Connect-SPAdmin {
    <# SharePoint 管理センターに接続します (テナント管理系コマンド用)。 #>
    Connect-SPSite -Url $SPConfig.AdminUrl
}

function Disconnect-SPSite {
    <# 接続を切断します (未接続でもエラーにしません)。 #>
    try { Disconnect-PnPOnline -ErrorAction SilentlyContinue } catch { }
}

# ------------------------------------------------------------------------------
# ユーティリティ
# ------------------------------------------------------------------------------
function Get-SPOutputPath {
    <#
    .SYNOPSIS
        出力フォルダ ($SPConfig.OutputDir) 配下のファイルパスを返します (フォルダは自動作成)。
    .PARAMETER WithTimestamp
        ファイル名に yyyyMMdd_HHmmss を付与します。
    #>
    param(
        [Parameter(Mandatory)][string]$FileName,
        [switch]$WithTimestamp
    )
    if (-not (Test-Path $SPConfig.OutputDir)) { New-Item -ItemType Directory -Path $SPConfig.OutputDir | Out-Null }
    if ($WithTimestamp) {
        $FileName = "{0}_{1}{2}" -f [IO.Path]::GetFileNameWithoutExtension($FileName),
                                   (Get-Date -Format 'yyyyMMdd_HHmmss'),
                                   [IO.Path]::GetExtension($FileName)
    }
    return (Join-Path $SPConfig.OutputDir $FileName)
}

function Convert-SPBool {
    <# CSV などの文字列 ("1", "true", "yes", "はい", "○") を bool に変換します。 #>
    param($Value)
    if ($null -eq $Value) { return $false }
    return ($Value.ToString().Trim() -match '^(1|true|yes|y|はい|○)$')
}

function Get-SPRoleName {
    <#
    .SYNOPSIS
        論理ロール名 (Edit など) を、接続中サイトに実在する権限レベル表示名に解決します。
    .DESCRIPTION
        $SPConfig.RoleNames の名前 → 英語名 の順で Get-PnPRoleDefinition と照合します。
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet('FullControl', 'Design', 'Edit', 'Contribute', 'Read')]
        [string]$Role
    )
    $english = @{ FullControl = 'Full Control'; Design = 'Design'; Edit = 'Edit'; Contribute = 'Contribute'; Read = 'Read' }
    $defs = Get-PnPRoleDefinition
    foreach ($candidate in @($SPConfig.RoleNames[$Role], $english[$Role])) {
        if ($candidate -and ($defs | Where-Object Name -eq $candidate)) { return $candidate }
    }
    $available = ($defs | ForEach-Object Name) -join ', '
    throw "ロール '$Role' に対応する権限レベルが見つかりません。Config\Settings.ps1 の RoleNames を確認してください。利用可能: $available"
}

function Set-SPRegionalSettings {
    <#
    .SYNOPSIS
        接続中サイトのタイムゾーンとロケールを設定します。
    .PARAMETER TimeZoneId
        SharePoint のタイムゾーン ID。省略時は $SPConfig.TimeZoneId (20 = 東京)。
    .PARAMETER LocaleId
        ロケール ID。省略時は $SPConfig.Lcid (1041 = 日本語)。
    #>
    param(
        [int]$TimeZoneId = $SPConfig.TimeZoneId,
        [int]$LocaleId   = $SPConfig.Lcid
    )
    $web = Get-PnPWeb -Includes RegionalSettings, RegionalSettings.TimeZones
    $tz  = $web.RegionalSettings.TimeZones | Where-Object Id -eq $TimeZoneId
    if (-not $tz) { throw "タイムゾーン ID $TimeZoneId が見つかりません。" }

    $web.RegionalSettings.TimeZone = $tz
    $web.RegionalSettings.LocaleId = $LocaleId
    $web.RegionalSettings.Update()
    $web.Update()
    Invoke-PnPQuery
    Write-Log "地域設定を適用しました: TimeZone=$($tz.Description), Locale=$LocaleId" OK
}

function Get-SPSiteRelativeUrl {
    <# サーバー相対 URL (/sites/xxx/Shared Documents/a) をサイト相対 URL (Shared Documents/a) に変換します。 #>
    param([Parameter(Mandatory)][string]$ServerRelativeUrl)
    $web    = Get-PnPWeb
    $webUrl = $web.ServerRelativeUrl.TrimEnd('/')
    if ($webUrl -and $ServerRelativeUrl.StartsWith($webUrl, [StringComparison]::OrdinalIgnoreCase)) {
        return $ServerRelativeUrl.Substring($webUrl.Length).TrimStart('/')
    }
    return $ServerRelativeUrl.TrimStart('/')
}

function Get-SPListRootFolderUrl {
    <# リスト / ライブラリのルートフォルダーをサイト相対 URL で返します (例: Shared Documents)。 #>
    param([Parameter(Mandatory)]$List)
    $l = Get-PnPList -Identity $List -Includes RootFolder
    if (-not $l) { throw "リストが見つかりません: $List" }
    return (Get-SPSiteRelativeUrl -ServerRelativeUrl $l.RootFolder.ServerRelativeUrl)
}

function Add-SPFieldFromDefinition {
    <#
    .SYNOPSIS
        CSV 1 行分の定義から列 (フィールド) を作成します。リスト列・サイト列の両方に対応。
    .DESCRIPTION
        定義オブジェクトのプロパティ:
          DisplayName      表示名 (日本語可)
          InternalName     内部名 (半角英数字推奨)
          Type             Text / Note / Number / Currency / DateTime / Boolean / Choice / MultiChoice /
                           User / UserMulti / URL / Lookup / LookupMulti
          Required         必須 (1 / true / はい)
          Choices          Choice / MultiChoice の選択肢を ; 区切りで
          DefaultValue     既定値
          AddToDefaultView 既定ビューに追加 (リスト列のみ)
          LookupList       Lookup の参照先リスト名
          LookupField      Lookup の表示列 (既定: Title)
          Group            サイト列グループ名 (サイト列のみ)
    .PARAMETER List
        指定時はリスト列、省略時はサイト列として作成します。
    #>
    param(
        [Parameter(Mandatory)]$Definition,
        [string]$List
    )
    $d = $Definition
    $type      = $d.Type.Trim()
    $required  = Convert-SPBool $d.Required
    $addToView = Convert-SPBool $d.AddToDefaultView
    $target    = if ($List) { "リスト '$List'" } else { "サイト列" }

    $existing = if ($List) { Get-PnPField -List $List -Identity $d.InternalName -ErrorAction SilentlyContinue }
                else       { Get-PnPField -Identity $d.InternalName -ErrorAction SilentlyContinue }
    if ($existing) {
        Write-Log "スキップ (既存): $target / $($d.InternalName)" WARN
        return $existing
    }

    $xmlTypes = @('Lookup', 'LookupMulti', 'UserMulti')
    if ($type -in $xmlTypes) {
        # Add-PnPField で指定できない属性は XML で作成
        $esc  = { param($s) [System.Security.SecurityElement]::Escape([string]$s) }
        $attr = @(
            "Type=`"$type`""
            "DisplayName=`"$(& $esc $d.DisplayName)`""
            "Name=`"$($d.InternalName)`""
            "StaticName=`"$($d.InternalName)`""
            "Required=`"$(if ($required) { 'TRUE' } else { 'FALSE' })`""
        )
        if ($type -like 'Lookup*') {
            if (-not $d.LookupList) { throw "$($d.InternalName): Lookup 列には LookupList が必要です。" }
            $lookupList = Get-PnPList -Identity $d.LookupList
            if (-not $lookupList) { throw "$($d.InternalName): 参照先リストが見つかりません: $($d.LookupList)" }
            $showField = if ($d.LookupField) { $d.LookupField } else { 'Title' }
            $attr += "List=`"{$($lookupList.Id)}`""
            $attr += "ShowField=`"$showField`""
        }
        if ($type -eq 'UserMulti') { $attr += 'UserSelectionMode="PeopleOnly"' }
        if ($type -in 'LookupMulti', 'UserMulti') { $attr += 'Mult="TRUE"' }
        if (-not $List -and $d.Group) { $attr += "Group=`"$(& $esc $d.Group)`"" }

        $xml = "<Field $($attr -join ' ') />"
        $p = @{ FieldXml = $xml }
        if ($List) { $p.List = $List; if ($addToView) { $p.AddToDefaultView = $true } }
        $field = Add-PnPFieldFromXml @p
    }
    else {
        $p = @{ DisplayName = $d.DisplayName; InternalName = $d.InternalName; Type = $type }
        if ($List) {
            $p.List = $List
            if ($addToView) { $p.AddToDefaultView = $true }
        }
        elseif ($d.Group) { $p.Group = $d.Group }
        if ($required) { $p.Required = $true }
        if ($type -in 'Choice', 'MultiChoice') {
            if (-not $d.Choices) { throw "$($d.InternalName): Choice 列には Choices が必要です。" }
            $p.Choices = @($d.Choices -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        }
        $field = Add-PnPField @p

        if ($d.DefaultValue) {
            $sp = @{ Identity = $field.Id; Values = @{ DefaultValue = $d.DefaultValue } }
            if ($List) { $sp.List = $List }
            Set-PnPField @sp | Out-Null
        }
    }
    Write-Log "列を作成しました: $target / $($d.DisplayName) [$($d.InternalName)] ($type)" OK
    return $field
}
