#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Preprocessor for the WeChat tweak cross-compile.
#
# jobs:
#   1. %ctor {  ->  __attribute__((constructor)) void _ctor(void) {
#   2. MERGE adjacent Objective-C string literals  @"..."  (separated only by
#      whitespace, possibly across lines) into a single @"..." literal. This is
#      required because after step 3 each @"..." becomes a
#      [NSString stringWithUTF8String:...] *expression*, and C/ObjC only lets you
#      concatenate adjacent STRING LITERALS, not arbitrary expressions. Without
#      merging, multi-line concatenations like
#          NSString *s = @"a"  @"b"  @"c";
#      would turn into `s = [..:@"a"] [..:@"b"] [..:@"c"];` -> syntax error.
#   3. Convert ONLY non-ASCII Objective-C string literals into
#      [NSString stringWithUTF8String:"<octal-escaped UTF-8>"]
#      because this Windows clang cannot emit Chinese inside @"..." literals
#      (it silently drops them -> nil -> stringWithFormat:nil / dictionary
#      insert-nil crashes). ASCII-only literals are left untouched.
#
# We use OCTAL \ooo escapes (not \xHH): C's \x is greedy and swallows all
# following hex digits, so a Chinese byte immediately followed by an ASCII digit
# (e.g. "\xe8\xbf\x911" == "最近1") becomes an invalid 3-digit \x911 escape.
# Octal stops after 3 digits and can never absorb the next character.
import re, sys

LIT_RE = re.compile(r'@"((?:[^"\\]|\\.)*)"')

def decode_c_escapes(s):
    out = []
    i = 0
    n = len(s)
    while i < n:
        c = s[i]
        if c == '\\' and i + 1 < n:
            e = s[i + 1]
            mp = {'n': '\n', 't': '\t', 'r': '\r', '\\': '\\', '"': '"', "'": "'"}
            if e in mp:
                out.append(mp[e]); i += 2; continue
            if e == 'x' and i + 3 < n:
                try:
                    out.append(chr(int(s[i + 2:i + 4], 16))); i += 4; continue
                except Exception:
                    pass
            out.append('\\'); i += 1; continue
        out.append(c); i += 1
    return ''.join(out)

def to_cstr(logical):
    b = logical.encode('utf-8')
    parts = []
    for byte in b:
        if 0x20 <= byte <= 0x7e and byte not in (0x5c, 0x22):
            parts.append(chr(byte))
        else:
            parts.append('\\%03o' % byte)
    return '"' + ''.join(parts) + '"'

def repl(m):
    logical = decode_c_escapes(m.group(1))
    if any(ord(ch) > 127 for ch in logical):
        return '[NSString stringWithUTF8String:' + to_cstr(logical) + ']'
    return m.group(0)

def merge_adjacent(src):
    # Merge runs of @"..." literals separated only by whitespace into one literal.
    out = []
    i = 0
    n = len(src)
    while i < n:
        m = LIT_RE.match(src, i)
        if not m:
            out.append(src[i]); i += 1; continue
        start = i
        end = m.end()
        raw_inners = [m.group(1)]
        j = end
        while j < n:
            k = j
            while k < n and src[k] in ' \t\r\n':
                k += 1
            if k >= n:
                break
            m2 = LIT_RE.match(src, k)
            if m2:
                raw_inners.append(m2.group(1))
                j = m2.end()
                end = j
            else:
                break
        if len(raw_inners) > 1:
            out.append('@"' + ''.join(raw_inners) + '"')
            i = end
        else:
            out.append(src[start:end])
            i = end
    return ''.join(out)

def process(src):
    src = re.sub(r'%ctor\s*\{', '__attribute__((constructor)) void _ctor(void) {', src)
    src = merge_adjacent(src)
    src = LIT_RE.sub(repl, src)
    return src

if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.stderr.write("usage: preprocess.py <in> <out>\n")
        sys.exit(2)
    with open(sys.argv[1], 'r', encoding='utf-8') as f:
        src = f.read()
    out = process(src)
    with open(sys.argv[2], 'w', encoding='utf-8') as f:
        f.write(out)
    sys.stderr.write("preprocess: %s -> %s (%d bytes)\n" % (sys.argv[1], sys.argv[2], len(out)))
