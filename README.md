# SharePoint Script Collection (PnP PowerShell)

SharePoint Online のサイト構築・運用でよく使う作業を **PnP PowerShell** でスクリプト化したものです。
アプリケーション ID やサイト URL などの環境依存の値は `Config/Settings.ps1` に集約しており、
各スクリプトはそこから設定を読み込んで動作します。

## 前提条件

| 項目 | 内容 |
|------|------|
| PowerShell | 7.4 以上 (`pwsh`)。Windows PowerShell 5.1 は非対応 |
| モジュール | [PnP.PowerShell](https://pnp.github.io/powershell/) 2.x 以上 |
| 権限 | 対象サイトの所有者権限。テナント管理系スクリプト (`Connect-SPAdmin` を使うもの) は SharePoint 管理者 |

```powershell
# モジュールのインストール
Install-Module PnP.PowerShell -Scope CurrentUser
```

## セットアップ

### 1. Entra ID にアプリを登録する

PnP PowerShell 2.x 以降は自前のアプリ登録が必要です。次のコマンドで対話的に作成できます (Entra ID の管理者権限が必要)。

```powershell
Register-PnPEntraIDAppForInteractiveLogin -ApplicationName "PnP PowerShell Scripts" -Tenant contoso.onmicrosoft.com -Interactive
```

表示される **ClientId** を控えてください。既存のアプリ登録を使う場合は、委任アクセス許可に
`SharePoint > AllSites.FullControl` と `Microsoft Graph > Sites.FullControl.All`、
サイト削除 (`Remove-Site.ps1`) を使う場合は `Group.ReadWrite.All` を追加しておきます。

### 2. `Config/Settings.ps1` を編集する

```powershell
$Global:SPConfig = @{
    AppId      = "11111111-2222-3333-4444-555555555555"   # 手順 1 の ClientId
    SiteUrl    = "https://contoso.sharepoint.com/sites/sample"
    TenantName = "contoso"
    AuthMode   = "Interactive"   # Interactive / DeviceLogin / Certificate / Thumbprint
    ...
}
```

個人環境ごとに値を変えたい場合は `Config/Settings.local.sample.ps1` を
`Config/Settings.local.ps1` という名前でコピーし、上書きしたいキーだけ記述してください (Git 管理対象外)。

### 3. 実行する

```powershell
cd 01_Site
.\Get-SiteInfo.ps1                                   # Settings.ps1 の SiteUrl に接続
.\Get-SiteInfo.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/other"   # 個別指定
Get-Help .\New-CommunicationSite.ps1 -Full           # 各スクリプトのヘルプ
```

ほとんどのスクリプトは `-SiteUrl` で対象サイトを個別指定できます。省略時は `Settings.ps1` の `SiteUrl` が使われます。

## フォルダー構成

```
SharePointScript/
├── Config/
│   ├── Settings.ps1                 ★ 環境設定 (ここだけ編集)
│   └── Settings.local.sample.ps1    個人用上書き設定のサンプル
├── Common/
│   ├── Common.ps1                   共通関数 (接続 / ログ / CSV 出力 / 列作成 など)
│   └── Script-Template.ps1          新規スクリプトの雛形
├── 01_Site/            サイトの作成・設定
├── 02_List/            リストの作成・列・ビュー・データ入出力
├── 03_Library/         ドキュメント ライブラリ・フォルダー・ファイル
├── 04_Permission/      グループ・権限・権限レポート
├── 05_Page/            モダン ページ・Web パーツ
├── 06_Navigation/      ナビゲーション
├── 07_ContentType/     サイト列・コンテンツ タイプ
├── 08_Provisioning/    PnP プロビジョニング テンプレート
├── 09_Report/          棚卸し・レポート
├── 10_Maintenance/     ごみ箱・テナント レベル設定
└── Output/             レポートの出力先 (Git 管理対象外)
```

## スクリプト一覧

### 01_Site : サイト

| スクリプト | 内容 |
|-----------|------|
| `New-CommunicationSite.ps1` | コミュニケーション サイトを作成し、タイムゾーン / ロケールを設定 |
| `New-TeamSite.ps1` | チーム サイトを作成 (M365 グループ連携 / 非連携) |
| `Get-SiteInfo.ps1` | サイトの基本情報 (テンプレート、地域設定、容量、管理者など) を表示 |
| `Set-SiteSettings.ps1` | タイトル / 説明 / ロゴ / 地域設定を変更 |
| `Set-HubSiteAssociation.ps1` | ハブ サイトの登録と関連付け / 解除 |
| `Remove-Site.ps1` | サイトを削除 (確認あり、`-WhatIf` 対応) |

### 02_List : リスト

| スクリプト | 内容 |
|-----------|------|
| `New-List.ps1` | リストを作成 (内部 URL は英数字、表示名は日本語の運用を想定) |
| `Add-ListFields.ps1` | CSV 定義から列を一括追加 (`Samples/Fields.sample.csv`) |
| `Add-ListView.ps1` | ビューを追加 (CAML クエリ対応) |
| `Set-ListSettings.ps1` | バージョン管理 / 添付 / フォルダー / コンテンツ タイプなどの設定変更 |
| `Import-ListItemsFromCsv.ps1` | CSV からアイテムを一括登録 (`Samples/Items.sample.csv`) |
| `Export-ListItemsToCsv.ps1` | アイテムを CSV に出力 (ユーザー / 参照列は表示値に変換) |

### 03_Library : ドキュメント ライブラリ

| スクリプト | 内容 |
|-----------|------|
| `New-DocumentLibrary.ps1` | ライブラリを作成 (バージョン設定込み) |
| `New-FolderStructure.ps1` | フォルダー構成を一括作成 (`Samples/Folders.sample.txt`) |
| `Add-FilesFromFolder.ps1` | ローカル フォルダーを階層ごとアップロード |
| `Get-LibraryFiles.ps1` | ライブラリ / フォルダーを階層ごとダウンロード |
| `Export-FileInventory.ps1` | ファイル一覧 (サイズ / バージョン / 更新者) を CSV 出力 |

### 04_Permission : 権限

| スクリプト | 内容 |
|-----------|------|
| `New-SecurityGroup.ps1` | SharePoint グループを作成し、権限レベルとメンバーを設定 |
| `Add-GroupMembers.ps1` | グループ メンバーを一括追加 / 削除 (`Samples/Members.sample.csv`) |
| `Set-ListPermission.ps1` | リストの継承解除 / 復元、グループ・ユーザーへの権限付与 |
| `Set-SiteCollectionAdmin.ps1` | サイト コレクション管理者の追加 / 削除 / 一覧 |
| `Export-PermissionReport.ps1` | サイト / 固有権限リスト / グループ メンバーの権限レポート |

### 05_Page : ページ

| スクリプト | 内容 |
|-----------|------|
| `New-ModernPage.ps1` | モダン ページを作成・発行 (テキスト / ニュース / ホーム設定) |
| `Add-PageWebPart.ps1` | 標準 Web パーツ (リスト、クイック リンクなど) を追加 |
| `Set-HomePage.ps1` | ホーム ページを変更 |

### 06_Navigation : ナビゲーション

| スクリプト | 内容 |
|-----------|------|
| `Set-Navigation.ps1` | CSV 定義からクイック起動 / 上部ナビを構築 (`Samples/Navigation.sample.csv`) |
| `Export-Navigation.ps1` | 現在のナビゲーションを CSV 出力 (Set-Navigation の入力形式) |
| `Set-NavigationSettings.ps1` | メガメニュー / 水平ナビ / ヘッダー / フッターの表示設定 |

### 07_ContentType : サイト列・コンテンツ タイプ

| スクリプト | 内容 |
|-----------|------|
| `New-SiteColumns.ps1` | CSV 定義からサイト列を一括作成 (`Samples/SiteColumns.sample.csv`) |
| `New-ContentType.ps1` | コンテンツ タイプを作成し、サイト列を関連付け |
| `Add-ContentTypeToList.ps1` | リストにコンテンツ タイプを追加 / 既定化 / 不要なものを削除 |

### 08_Provisioning : プロビジョニング

| スクリプト | 内容 |
|-----------|------|
| `Export-SiteTemplate.ps1` | サイト構成を PnP テンプレートとして書き出し |
| `Invoke-SiteTemplate.ps1` | PnP テンプレートを別サイトに適用 |

### 09_Report : レポート

| スクリプト | 内容 |
|-----------|------|
| `Get-TenantSiteList.ps1` | テナント内の全サイト一覧 (容量 / 共有設定など) ※管理者 |
| `Get-SiteListInventory.ps1` | サイト内のリスト / ライブラリ一覧 |
| `Get-SiteUsers.ps1` | サイト ユーザー一覧とグループ メンバー一覧 |
| `Get-SubsiteTree.ps1` | サブサイトの一覧 |

### 10_Maintenance : 保守

| スクリプト | 内容 |
|-----------|------|
| `Get-RecycleBinItems.ps1` | ごみ箱アイテムの一覧 (削除者 / 日時で絞り込み) |
| `Restore-RecycleBinItems.ps1` | ごみ箱アイテムを条件指定で一括復元 (`-WhatIf` 対応) |
| `Set-TenantSiteProperties.ps1` | ロック状態 / 共有設定 / カスタム スクリプト / 容量 ※管理者 |

## 典型的なサイト構築の流れ

```powershell
# 1. サイト作成
.\01_Site\New-CommunicationSite.ps1 -Title "総務部ポータル" -Url "https://contoso.sharepoint.com/sites/soumu"

# 以降は対象サイトを -SiteUrl で指定するか、Settings.ps1 の SiteUrl を変更
$site = "https://contoso.sharepoint.com/sites/soumu"

# 2. サイト列・コンテンツ タイプ
.\07_ContentType\New-SiteColumns.ps1 -DefinitionPath .\07_ContentType\Samples\SiteColumns.sample.csv -SiteUrl $site
.\07_ContentType\New-ContentType.ps1 -Name "申請書" -ParentContentType 0x0101 -Fields Department,ApprovalStatus -SiteUrl $site

# 3. リスト / ライブラリ
.\02_List\New-List.ps1 -Title "申請一覧" -InternalName "Requests" -OnQuickLaunch -EnableVersioning -SiteUrl $site
.\02_List\Add-ListFields.ps1 -List "申請一覧" -DefinitionPath .\02_List\Samples\Fields.sample.csv -SiteUrl $site
.\03_Library\New-DocumentLibrary.ps1 -Title "規程集" -InternalName "Rules" -OnQuickLaunch -SiteUrl $site
.\03_Library\New-FolderStructure.ps1 -Library "規程集" -DefinitionPath .\03_Library\Samples\Folders.sample.txt -SiteUrl $site

# 4. 権限
.\04_Permission\New-SecurityGroup.ps1 -GroupName "総務部 編集者" -Role Edit -Members "taro@contoso.com" -SiteUrl $site

# 5. ページとナビゲーション
.\05_Page\New-ModernPage.ps1 -Name "Welcome" -Title "ようこそ" -Text "<h2>総務部ポータル</h2>" -SetAsHomePage -SiteUrl $site
.\06_Navigation\Set-Navigation.ps1 -DefinitionPath .\06_Navigation\Samples\Navigation.sample.csv -ClearExisting -SiteUrl $site

# 6. 構成をテンプレート化して別サイトへ
.\08_Provisioning\Export-SiteTemplate.ps1 -Handlers Lists,Fields,ContentTypes,Navigation -SiteUrl $site
```

## 共通関数 (Common/Common.ps1)

新しいスクリプトを書くときは `Common/Script-Template.ps1` をコピーしてください。主な関数:

| 関数 | 内容 |
|------|------|
| `Connect-SPSite [-Url]` | Settings の認証方式でサイトに接続 (省略時は `SiteUrl`) |
| `Connect-SPAdmin` | SharePoint 管理センターに接続 |
| `Disconnect-SPSite` | 切断 (finally で使用) |
| `Write-Log <msg> [INFO/OK/WARN/ERROR]` | 色付きログ |
| `Get-SPOutputPath <file> [-WithTimestamp]` | `Output/` 配下の出力パスを生成 |
| `Get-SPRoleName <Edit など>` | Settings の `RoleNames` を実在する権限レベル名に解決 |
| `Set-SPRegionalSettings` | タイムゾーン / ロケールを Settings の値に設定 |
| `Get-SPListRootFolderUrl <list>` | リストのルート フォルダーをサイト相対 URL で取得 |
| `Add-SPFieldFromDefinition` | CSV 1 行の定義から列を作成 (リスト列 / サイト列) |

## 注意事項

- **権限レベル名はサイトの言語に依存します。** 英語サイトの場合は `Settings.ps1` の `RoleNames` を
  `Full Control` / `Edit` / `Contribute` / `Read` に変更してください (見つからない場合は英語名で自動リトライします)。
- CSV は **UTF-8 (BOM 付き)** を想定しています。Excel の「CSV UTF-8」で保存すれば OK です。
  Shift-JIS の CSV は `-Encoding shift_jis` を指定してください。
- `Connect-SPAdmin` を使うスクリプト (サイト作成 / 削除 / ハブ / テナント一覧 / テナント設定) は
  SharePoint 管理者ロールが必要です。
- 無人実行 (タスク スケジューラ / Azure Automation) では `AuthMode = "Certificate"` または `"Thumbprint"` を使い、
  アプリ登録にアプリケーション アクセス許可 (`Sites.FullControl.All`) を付与してください。
