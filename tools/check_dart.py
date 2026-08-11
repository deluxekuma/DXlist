#!/usr/bin/env python3
"""Dart 原始碼的簡易靜態檢查。

這裡沒有 Flutter SDK（磁碟不夠裝），跑不了 flutter analyze，
所以用這支腳本抓兩類最容易犯又最致命的錯：

1. 括號配對錯誤 —— 用堆疊逐字比對，會抓到 `Align(...}` 這種
   「總數平衡但配對錯」的情形。單純數數量抓不到。
2. 缺 import —— 用到別的檔案定義的類別或函式卻忘了 import。

抓不到的：型別不符、參數名錯字、API 版本問題。那些只有
flutter analyze 才知道。

用法：
    python3 tools/check_dart.py lib
"""

import re
import os
import sys

PAIRS = {'(': ')', '[': ']', '{': '}'}
CLOSERS = {v: k for k, v in PAIRS.items()}


def strip_code(src):
    """把註解與字串內容抹成空白，保留換行以維持行號。

    抹掉而不是刪掉，是為了讓後面回報的行號跟原始檔對得上。
    """
    out = []
    i = 0
    n = len(src)
    while i < n:
        ch = src[i]

        # 單行註解
        if src.startswith('//', i):
            while i < n and src[i] != '\n':
                out.append(' ')
                i += 1
            continue

        # 區塊註解
        if src.startswith('/*', i):
            while i < n and not src.startswith('*/', i):
                out.append('\n' if src[i] == '\n' else ' ')
                i += 1
            out.append('  ')
            i += 2
            continue

        # 字串（含 raw、三引號）
        if ch in '"\'':
            raw = i > 0 and src[i - 1] == 'r'
            triple = src.startswith(ch * 3, i)
            quote = ch * 3 if triple else ch
            out.append(' ' * len(quote))
            i += len(quote)
            while i < n:
                if not raw and src[i] == '\\':
                    out.append('  ')
                    i += 2
                    continue
                if src.startswith(quote, i):
                    out.append(' ' * len(quote))
                    i += len(quote)
                    break
                out.append('\n' if src[i] == '\n' else ' ')
                i += 1
            continue

        out.append(ch)
        i += 1

    return ''.join(out)


def check_brackets(path, code):
    """用堆疊檢查括號配對。回傳錯誤訊息列表。"""
    errors = []
    stack = []
    line = 1

    for ch in code:
        if ch == '\n':
            line += 1
        elif ch in PAIRS:
            stack.append((ch, line))
        elif ch in CLOSERS:
            if not stack:
                errors.append(f'{path}:{line} 多出一個 {ch}')
            else:
                opener, opened_at = stack.pop()
                if PAIRS[opener] != ch:
                    errors.append(
                        f'{path}:{line} 這裡是 {ch}，'
                        f'但第 {opened_at} 行開的是 {opener}，'
                        f'應該用 {PAIRS[opener]}')

    for opener, opened_at in stack:
        errors.append(f'{path}:{opened_at} 的 {opener} 沒有收尾')

    return errors


KEYWORDS = {
    'return', 'if', 'for', 'while', 'switch', 'await', 'yield',
    'throw', 'new', 'const', 'final', 'var', 'void', 'else', 'case',
}


def public_symbols(code):
    """抓出這個檔案對外提供的頂層名字。

    只認第 0 欄開始的宣告。頂層宣告一定不縮排，這樣就不會把
    方法內部的 `return SizedBox(...)` 誤判成本檔定義的符號。
    """
    names = set()

    for m in re.finditer(
            r'^(?:abstract\s+|sealed\s+|mixin\s+|final\s+)*'
            r'(?:class|enum|extension|typedef)\s+(\w+)',
            code, re.M):
        names.add(m.group(1))

    # 頂層 const / final 變數
    for m in re.finditer(r'^(?:const|final)\s+[\w<>,\s?]+\s+(\w+)\s*=',
                         code, re.M):
        names.add(m.group(1))

    # 頂層函式：不縮排、有回傳型別、接著 => 或 {
    for m in re.finditer(
            r'^([\w<>,?]+(?:\s*<[^>]*>)?)\s+(\w+)\s*\([^;]*?\)\s*(?:=>|\{)',
            code, re.M):
        ret, name = m.group(1), m.group(2)
        if ret not in KEYWORDS and name not in KEYWORDS:
            names.add(name)

    return {n for n in names if not n.startswith('_')}


def check_imports(root, files, codes, sources):
    """檢查每個檔案用到的跨檔案符號有沒有 import 進來。"""
    errors = []

    # 每個檔案提供哪些符號
    provides = {f: public_symbols(codes[f]) for f in files}

    for f in files:
        code = codes[f]
        body = re.sub(r'^\s*import\s+[^;]+;', '', code, flags=re.M)

        # import 路徑要從原始碼撈，因為 codes 裡的字串已經被抹白了
        imported = set()
        for m in re.finditer(r"import\s+'([^']+)'", sources[f]):
            p = m.group(1)
            if p.startswith(('dart:', 'package:')):
                continue
            resolved = os.path.normpath(
                os.path.join(os.path.dirname(f), p))
            imported.add(resolved)

        own = provides[f]
        used = set(re.findall(r'\b([A-Z]\w+)\b', body))
        used |= set(re.findall(
            r'\b(difficultyOf|levelDisplay|levelPrecise|versionShort)\b',
            body))

        for sym in used:
            if sym in own:
                continue
            # 這個符號是哪個檔案提供的
            owners = [o for o in files if sym in provides[o] and o != f]
            if owners and not any(o in imported for o in owners):
                errors.append(
                    f'{f} 用了 {sym} 但沒 import '
                    f'（定義在 {owners[0]}）')

    return errors


def main(root):
    files = []
    for dirpath, _, filenames in os.walk(root):
        for name in sorted(filenames):
            if name.endswith('.dart'):
                files.append(os.path.join(dirpath, name))

    if not files:
        print(f'{root} 底下沒有 .dart 檔')
        return 1

    codes = {}
    sources = {}
    errors = []

    for f in files:
        with open(f, encoding='utf-8') as fh:
            src = fh.read()
        sources[f] = src
        code = strip_code(src)
        codes[f] = code
        errors.extend(check_brackets(f, code))

    errors.extend(check_imports(root, files, codes, sources))

    if errors:
        print(f'發現 {len(errors)} 個問題：')
        for e in errors:
            print(f'  {e}')
        return 1

    print(f'{len(files)} 個檔案，括號配對與 import 都沒問題')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else 'lib'))
