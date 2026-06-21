# わんソナ 開発ログ・引き継ぎ指示書

## 環境
- Codespaces: shiny-capybara
- Flutter 3.44.0 / Android専用 / Mac不所持
- 起動コマンド：
  export ANDROID_HOME=/workspaces/wannsona/android-sdk && export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:/workspaces/wannsona/flutter/bin && cd /workspaces/wannsona/wannsona_app

## 完成済みファイル一覧
- lib/main.dart（ホーム画面・天気・路面温度・ボトムナビ・オンボーディング・Drawer）
- lib/weather_service.dart（OpenWeatherMap API）
- lib/road_temp_calculator.dart（路面温度推定）
- lib/dog_profile_screen.dart（プロフィール画面）
- lib/breed_data.dart（犬種データベース）
- lib/breed_select_screen.dart（犬種選択画面）
- lib/my_dog_record_screen.dart（うちの子記録画面）

## 完成済み機能
- ホーム画面UI
- 天気API（OpenWeatherMap・金古町）
- 路面温度計算
- アドバイス表示
- オリジナルアイコン
- ボトムナビ5タブ（HOME/お散歩/うちの子記録/コミュニティ/思い出）
- うちの子記録画面MVP（今日の記録・体調メモ・ChoiceChip・SharedPreferences保存）
- 初回起動オンボーディング（名前・犬種リスト選択・体重・誕生日）
- ハンバーガーメニューMVP（ユーザー情報エリア・12項目・注意事項ダイアログ）
- 犬種表示カタカナ化（aliases[0]を使用）
- 犬種DB修正（ドーベルマン・秋田犬・ポメラニアン・ゴールデンドゥードル等）
- ScaffoldKey実装済み（_scaffoldKey）

## 最新APK
wannsona_apk_v16.apk（ビルド成功・動作確認待ち）

## 次回やること（優先順）
1. ハンバーガーメニューのタップ動作確認
   - v16でScaffoldKeyを追加済み
   - インストールして動作確認

2. アプリアイコン変更
   - えみりが画像を用意済み
   - flutter_launcher_iconsパッケージ使用
   - pubspec.yamlに設定追加
   - flutter pub run flutter_launcher_icons実行

3. サモエド・ビーグル・ポインター等の犬種表示確認
   - v16で修正済みのはず

4. プロフィールデータ→安全指数への反映
   - BreedRiskをホームの安全指数に掛け合わせる

5. ハンバーガーメニュー各項目の実装
   - 地域・天気設定・通知設定・お気に入りスポット等

6. お散歩タブ実装（index=1）

## タブ構成
- index=0: HOME
- index=1: お散歩（coming soon）
- index=2: うちの子記録（MyDogRecordScreen）
- index=3: コミュニティ（coming soon）
- index=4: 思い出（coming soon）

## 重要な実装メモ
- Drawer：_buildDrawer()メソッド、ScaffoldKey：_scaffoldKey
- オンボーディング：_showOnboardingDialog()
- 犬種選択：BreedSelectScreen→Breed型返却→aliases[0]をカタカナ表示に使用
- breed_data.dartのaliases[]が空の場合はkana（ひらがな）にフォールバック
- Pythonでファイル編集時、日本語を含む長い文字列はヒアドキュメント内で改行しないこと
- main.dartのbody：三項演算子でタブ切り替え

## 設計方針
- 医療診断ではなく注意喚起として表示
- SNS化しない・承認欲求バトルにしない
- MVP：無料＋広告、月額480円プレミアム想定
- Android専用でPlay公開を目標
