# DXList

為遊戲 maimai でらっくす 使用的待打歌曲清單，採用 Material You 風格。

## 功能

- 離線搜尋曲名、曲師、縮寫，選擇 DX / STD / 宴會場譜面後加入清單。
- 每首歌擁有曲繪、曲師、正式版本、等級、定數、BPM 和譜面物件統計。
- 點擊歌曲區塊開啟歌曲詳情頁，顯示模糊曲繪背景、譜面一覽、定數、BPM 和 Tap / Hold / Slide / Touch / Break 統計。
- 長按歌曲區塊標記已打完，支援復原。
- 曲繪高斯模糊背景，會依主色亮度自動選黑字或白字。

## 資料來源

內建 dxrating 的精簡曲庫，資料以 `tools/slim_dxdata.py` 從上游 `dxdata.json` 生成。曲繪取自 dxrating CDN。
