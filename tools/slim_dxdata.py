#!/usr/bin/env python3
"""把 dxrating 上游的 dxdata.json 精簡成 app 內建曲庫。

用法：
    curl -sL -o dxdata.json \
      https://raw.githubusercontent.com/gekichumai/dxrating/main/packages/dxdata/dxdata.json
    python3 tools/slim_dxdata.py dxdata.json assets/dxdata_slim.json
"""

import json
import sys

DIFF = {'basic': 0, 'advanced': 1, 'expert': 2, 'master': 3, 'remaster': 4}


def clean(o):
    """去掉空值，省檔案大小。

    'g' 是 region bitmask，5（日服 + 海外版都有）才省略，其他值一律保留，
    因為 0 代表「已刪除曲」，是有意義的資訊。
    """
    if isinstance(o, dict):
        out = {}
        for k, v in o.items():
            if k == 'g':
                if v != 5:
                    out[k] = v
            elif v is not None and v != [] and v != '':
                out[k] = clean(v)
        return out
    if isinstance(o, list):
        return [clean(x) for x in o]
    return o


def song_key(song):
    """比對用的身分：曲名 + 曲繪檔名 + 整組譜面。

    只看曲名會把同名的不同曲（兩首 Link）混在一起；加上譜面清單是因為
    宴會場曲目在上游是一張譜面一個條目，同名同曲繪、只有等級不同
    （例如「[宴]Wonderland Wars オープニング」有 5 個條目），
    不比譜面就會被誤判成 4 首被刪掉。
    """
    return (
        song['n'],
        song.get('i', ''),
        tuple(sorted(sheet_key(sh) for sh in song.get('s', []))),
    )


def sheet_key_of(song):
    """整個條目的譜面身分集合。"""
    return {sheet_key(sh) for sh in song.get('s', [])}


def sheet_key(sh):
    """單張譜面的身分：類型 + 宴會場標記 + 難度。

    刻意不含等級字串：dxdata 會定期修正定數（例如「8」改成「8+」），
    那只是改版修正，不是譜面被刪掉，拿等級當身分會誤判成大量刪除。
    """
    return (sh['t'], sh.get('k') or '', sh.get('d'))


def load_previous(dst):
    """讀回上一次產生的精簡檔，用來補回上游刪掉的曲目與譜面。

    上游（dxrating）會直接把「已刪除」的曲目整個抽掉，只留著的檔案
    就會連帶消失，使用者的待打清單也就查不到那首歌了。這裡把舊檔
    當成底稿：上游沒有的，保留資料但把地區標記壓成 0，讓 app 用既有的
    「已刪除」標示顯示，而不是整首不見。
    """
    try:
        with open(dst, encoding='utf-8') as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def main(src, dst):
    with open(src, encoding='utf-8') as f:
        data = json.load(f)

    previous = load_previous(dst)

    order = {v['version']: i for i, v in enumerate(data['versions'])}
    out = []

    for song in data['songs']:
        sheets = []
        for sh in song['sheets']:
            diff = sh['difficulty']
            di = DIFF.get(diff, 5)  # 5 = 宴會場
            regions = sh.get('regions') or {}
            sheets.append({
                't': sh['type'],                       # dx / std / utage / utage2p
                'd': di,
                'k': diff if di == 5 else None,        # 宴會場標記，例如【協】
                'l': sh.get('level') or '',            # 官方等級 13+
                'v': sh.get('internalLevelValue'),     # 定數 13.7
                'r': sh.get('version') or '',          # 正式版本名
                'designer': (sh.get('noteDesigner') or '').strip() if sh.get('noteDesigner') != '-' else '',
                'q': sh.get('releaseDate') or '',      # 譜面上線日期
                'n': sh.get('noteCounts') or {},       # 譜面物件統計
                # 實裝狀態 bitmask：1=日服 4=海外版。0 表示已刪除。
                #
                # 刻意不採用 dxdata 的 cn 欄位：它明顯陳舊且不準。
                # 反證一：ツユ 全曲在 2024-07-24（舞萌DX 2024 的 1.41-B）
                #         已隨日服一起移除，dxdata 裡卻仍有四首標 cn=true。
                # 反證二：宴會場 100 張譜面 cn 全為 false，但國服實際打得到。
                # 由於國服不存在獨佔曲，日服刪掉的國服必然也沒有，
                # 所以只用 jp 判斷「已刪除」就足夠且可靠。
                'g': (1 if regions.get('jp') else 0)
                     | (4 if regions.get('intl') else 0),
            })

        versions = [s['r'] for s in sheets if s['r'] in order]
        debut = min(versions, key=lambda x: order[x]) if versions else ''

        out.append({
            'n': song['title'],
            'a': song.get('artist') or '',
            'b': song.get('bpm'),
            'i': song.get('imageName') or '',
            'c': song.get('category') or '',
            'y': song.get('searchAcronyms') or [],
            'v0': debut,
            's': sheets,
        })

    # 補回上游已移除的曲目與譜面：一律標成已刪除（g=0）。
    #
    # 上游（dxrating）刪掉曲目時是整個條目抽掉，只留著的檔案就會連帶
    # 消失，使用者的待打清單也就查不到那首歌。這裡把舊檔當底稿補回來，
    # 讓 app 用既有的「已刪除」標示呈現，而不是整首不見。
    #
    # 配對方式：先依（曲名 + 曲繪檔名）分組（相同的不一定同一首，例如
    # 兩首 Link；宴會場更是同名同曲繪、一張譜面一個條目），再挑「譜面
    # 有重疊且還沒被認領」的條目。這樣曲師字串被上游改寫（「箱部なる」
    # →「箱部 なる」、プロセカ 系列排序變動）也不會被誤判成刪除。
    kept_songs, kept_sheets = [], []
    if previous:
        pools = {}
        for now in out:
            pools.setdefault((now['n'], now.get('i', '')), []).append(now)
        claimed = set()

        for old in previous['songs']:
            old_sheets = {sheet_key(sh) for sh in old.get('s', [])}
            target = None
            for cand in pools.get((old['n'], old.get('i', '')), []):
                if id(cand) in claimed:
                    continue
                if sheet_key_of(cand) & old_sheets:
                    target = cand
                    break
            if target is None:
                # 整首被上游拿掉：留著，全部譜面標成已刪除。
                for sh in old.get('s', []):
                    sh['g'] = 0
                out.append(old)
                kept_songs.append(old['n'])
                continue
            claimed.add(id(target))
            # 這首還在，但某張譜面被拿掉了：保留並標成已刪除。
            have = sheet_key_of(target)
            for sh in old.get('s', []):
                if sheet_key(sh) not in have:
                    sh['g'] = 0
                    target['s'].append(sh)
                    kept_sheets.append(f"{old['n']} / {sh['t']} {sh['d']}")

    result = {'u': data['updateTime'][:10], 'songs': clean(out)}
    with open(dst, 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, separators=(',', ':'))

    if kept_songs:
        print(f'上游已移除，保留 {len(kept_songs)} 首並標成已刪除：')
        for name in kept_songs:
            print('  -', name)
    if kept_sheets:
        print(f'上游已移除，保留 {len(kept_sheets)} 張譜面並標成已刪除：')
        for name in kept_sheets:
            print('  -', name)

    print(f'{len(out)} songs -> {dst}')


if __name__ == '__main__':
    args = sys.argv[1:]
    main(args[0] if args else 'dxdata.json',
         args[1] if len(args) > 1 else 'assets/dxdata_slim.json')
