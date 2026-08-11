# DXList

給 maimai でらっくす 用的待打歌曲清單，採用 Material You 風格。

## 功能

- 離線搜尋曲名、曲師、縮寫，選擇 DX / STD / 宴會場譜面後加入清單。
- 每首歌保留曲繪、曲師、正式版本、等級、定數、BPM 和譜面物件統計。
- 點擊歌曲區塊開啟歌曲詳情頁，顯示模糊曲繪背景、譜面一覽、定數、BPM 和 Tap / Hold / Slide / Touch / Break 統計。
- 長按歌曲區塊標記已打完，支援復原。
- 曲繪高斯模糊背景保留，會依主色亮度自動選黑字或白字。
- Re:MASTER 難度使用純白圓點，亮背景上自動加淡描邊。
- App 名稱為 `DXList`，Android applicationId 為 `derakuma.dxlist`。
- 使用 `geometric_icon111.svg` 作為 Android launcher icon；CI 會轉成 PNG 並生成自適應圖標及 Android 13+ 主題圖標。

## 取得 APK

GitHub Actions 會自動編譯 arm64 release APK，完成後從 Actions 的 `DXList-apk` artifact 下載 `DXList.apk`。

如果 workflow 需要手動更新，`ci/build.yml` 是和 `.github/workflows/build.yml` 相同的備份。

## 資料來源

內建 dxrating 的精簡曲庫，資料以 `tools/slim_dxdata.py` 從上游 `dxdata.json` 生成。曲繪取自 dxrating CDN。
