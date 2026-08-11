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


def main(src, dst):
    with open(src, encoding='utf-8') as f:
        data = json.load(f)

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
            'i': song.get('imageName') or '',
            'c': song.get('category') or '',
            'y': song.get('searchAcronyms') or [],
            'v0': debut,
            's': sheets,
        })

    result = {'u': data['updateTime'][:10], 'songs': clean(out)}
    with open(dst, 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, separators=(',', ':'))

    print(f'{len(out)} songs -> {dst}')


if __name__ == '__main__':
    args = sys.argv[1:]
    main(args[0] if args else 'dxdata.json',
         args[1] if len(args) > 1 else 'assets/dxdata_slim.json')
