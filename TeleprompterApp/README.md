# 提詞機 (Teleprompter) — 安裝指南（Windows + 免費 Apple ID）

流程：上載到 GitHub → 雲端 Mac 自動編譯出 IPA → 用 Sideloadly 裝上 iPhone。

## 一、編譯 IPA（只需做一次，之後改程式先需要重做）

1. 註冊 GitHub 帳戶，建立新 repository（建議選 **Public**）。
   - 原因：公開 repo 嘅 GitHub Actions 通常免費；私人 repo 嘅 macOS 分鐘數扣得快（免費額度會好快用完），請以 GitHub 官方計費說明為準。
   - 本專案冇任何密碼或私人資料，公開冇問題。
2. 把本資料夾入面**所有內容**（包括隱藏嘅 `.github` 資料夾）上載到 repo 嘅 `main` 分支。
   - 上載後請確認 repo 入面見到 `.github/workflows/build.yml` 同 `project.yml`。
3. 去 repo 嘅 **Actions** 分頁 → 選 **Build IPA** → **Run workflow**。（上載到 main 時亦會自動執行。）
4. 等約 5–10 分鐘。成功後，打開該次執行，下面 **Artifacts** 下載 `Teleprompter-ipa`，解壓得到 `Teleprompter.ipa`。
5. 如果失敗（紅色交叉）：下載 `build-log` artifact，把內容或錯誤訊息貼畀我，我會修正。

## 二、安裝到 iPhone（Sideloadly）

1. 到 Sideloadly 官網下載安裝，並按官網指示安裝所需嘅 iTunes（過往要求係 Apple 官網版，而唔係 Microsoft Store 版，請以 Sideloadly 官網最新說明為準）。
2. 用 USB 線連接 iPhone，iPhone 上按「信任此電腦」。
3. Sideloadly 入面：輸入 Apple ID → 拖入 `Teleprompter.ipa` → 按 Start。
   - 建議使用一個專用嘅免費 Apple ID，因為你要把 Apple ID 登入資料輸入第三方工具。
4. iPhone：**設定 → 隱私權與安全性 → 開發者模式** 開啟（可能要重新啟動）。如果未見到此選項，先完成一次安裝嘗試後再檢查。
5. iPhone：**設定 → 一般 → VPN 與裝置管理** → 點你嘅 Apple ID → **信任**。
6. 開啟「提詞機」，允許相機、麥克風、相片權限。

## 三、日常注意

- 免費 Apple ID 簽名每 **7 日**過期，過期後 app 打唔開，要用 Sideloadly 重新安裝一次。
- **重新安裝時唔好先刪除 app**，直接覆蓋安裝，稿件先會保留（稿件儲存喺 app 內部）。
- 免費帳戶同時最多 3 個側載 app。

## 功能對應

| 功能 | 位置 |
|---|---|
| 稿件管理 | `Views/ScriptLibraryView.swift`、`ScriptEditorView.swift` |
| 鏡頭及錄影 | `Camera/CameraManager.swift` |
| 提詞面板及捲動 | `Teleprompter/` |
| 設定面板 | `Views/TeleprompterSettingsView.swift` |
