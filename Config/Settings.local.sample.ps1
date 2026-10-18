<#
    個人環境用の設定上書きサンプル
    このファイルを「Settings.local.ps1」という名前でコピーして編集してください。
    Settings.local.ps1 は .gitignore により Git 管理対象外です。
    Settings.ps1 の後に読み込まれるため、必要なキーだけ上書きすれば OK です。
#>
$SPConfig.AppId      = "11111111-2222-3333-4444-555555555555"
$SPConfig.SiteUrl    = "https://mytenant.sharepoint.com/sites/dev"
$SPConfig.TenantName = "mytenant"
# $SPConfig.AuthMode  = "DeviceLogin"
