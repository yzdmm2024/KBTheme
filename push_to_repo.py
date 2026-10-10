#!/usr/env python3
# -*- coding: utf-8 -*-
"""push_to_repo.py — 把指定 deb 发布到越狱源 yzdmm2024/repo（Git Data API）。
用法: python push_to_repo.py <path-to.deb> [提交说明]
会自动: 解析 control -> 替换/新增 Packages 条目 -> 重算 Packages/Packages.gz/Packages.bz2/Release -> 上传 deb 与索引。
前置: 已装 gh CLI 并登录 (gh auth login)，且对 yzdmm2024/repo 有写权限。
"""
import argparse, base64, os, subprocess, gzip, bz2, hashlib, tempfile, re, sys, json
from email.utils import formatdate

REPO = "yzdmm2024/repo"
REPO_ID = None

def gh(args, payload=None, raw=False):
    global REPO_ID
    cmd = ["gh", "api"]
    if raw:
        cmd += ["-H", "Accept: application/vnd.github.raw"]
    if isinstance(args, str):
        args = [args]
    cmd += list(args)
    if payload is not None:
        fd, p = tempfile.mkstemp(suffix=".json")
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(payload, f)
        try:
            r = subprocess.run(cmd + ["--input", p], capture_output=True, text=True)
        finally:
            os.remove(p)
    else:
        r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError("API失败: %s\n%s" % (r.stdout[:800], r.stderr[:800]))
    return r.stdout

def repo_id():
    global REPO_ID
    if not REPO_ID:
        REPO_ID = json.loads(gh("repos/%s" % REPO))["id"]
    return REPO_ID

def get_raw(path):
    # 用 repo id 避免 slug 307 重定向（POST/PUT 不跟随）
    return gh("repositories/%s/contents/%s?ref=main" % (repo_id(), path), raw=True)

def get_sha(path):
    return json.loads(gh("repositories/%s/contents/%s?ref=main" % (repo_id(), path)))["sha"]

def put_file(path, data, msg, sha=None):
    payload = {"message": msg, "content": base64.b64encode(data).decode()}
    if sha: payload["sha"] = sha
    gh("repositories/%s/contents/%s" % (repo_id(), path), payload=payload)

def del_file(path, sha, msg):
    gh("repositories/%s/contents/%s" % (repo_id(), path), payload={"message": msg, "sha": sha})

def parse_control(data):
    import io, tarfile
    if data[:8] != b"!<arch>\n":
        raise ValueError("不是合法 deb 文件")
    p = 8
    def read_member(buf, off):
        name = buf[off:off+16].rstrip(b" /").decode("latin1")
        size = int(buf[off+48:off+58])
        data_off = off + 60
        return name, buf[data_off:data_off+size], data_off+size+(size % 2)
    m1, _, p = read_member(data, p)
    m2, ctgz, p = read_member(data, p)
    if m2 == "control.tar.gz/":
        buf = io.BytesIO(ctgz)
        with tarfile.open(fileobj=buf, mode="r:gz") as tar:
            ctrl = tar.extractfile("./control").read().decode("utf-8", errors="replace")
    else:
        raise RuntimeError("找不到 control.tar.gz，成员是 %s" % m2)
    pkg = re.search(r"(?m)^Package:\s*(\S+)", ctrl)
    ver = re.search(r"(?m)^Version:\s*(\S+)", ctrl)
    return (pkg.group(1) if pkg else None), (ver.group(1) if ver else None)

def find_old(pkgs_text, pkg_name):
    m = re.search(rf"(?ms)^Package:\s*{re.escape(pkg_name)}\n(.*?)(?=^Package:|\Z)", pkgs_text)
    if not m: return None, None
    fn = re.search(r"(?m)^Filename:\s*(.+)$", m.group(1))
    vn = re.search(r"(?m)^Version:\s*(.+)$", m.group(1))
    return (fn.group(1).strip() if fn else None), (vn.group(1).strip() if vn else None)

def build_new_stanza(pkgs_text, pkg_name, new_ver, filename, size, md5, sha1, sha256):
    m = re.search(rf"(?ms)^Package:\s*{re.escape(pkg_name)}\n(.*?)(?=^Package:|\Z)", pkgs_text)
    if not m:
        return None
    block = m.group(0)
    block = re.sub(r"(?m)^Version:\s*.+$", "Version: %s" % new_ver, block, count=1)
    block = re.sub(r"(?m)^Filename:\s*.+$", "Filename: %s" % filename, block, count=1)
    block = re.sub(r"(?m)^Size:\s*.+$", "Size: %d" % size, block, count=1)
    block = re.sub(r"(?m)^MD5sum:\s*.+$", "MD5sum: %s" % md5, block, count=1)
    block = re.sub(r"(?m)^SHA1:\s*.+$", "SHA1: %s" % sha1, block, count=1)
    block = re.sub(r"(?m)^SHA256:\s*.+$", "SHA256: %s" % sha256, block, count=1)
    return pkgs_text[:m.start()] + block + pkgs_text[m.end():]

def build_release(pkgs_bytes, gz, bz2, old_release):
    head = old_release.split("MD5Sum:")[0]
    head = "\n".join(l for l in head.splitlines() if not l.startswith("Date:"))
    head = head.rstrip() + "\n"
    date = formatdate(usegmt=True)
    files = {"Packages": pkgs_bytes, "Packages.gz": gz, "Packages.bz2": bz2}
    def block(algo):
        out = []
        for fn, b in files.items():
            h = (hashlib.md5(b).hexdigest() if algo == "MD5Sum"
                 else hashlib.sha1(b).hexdigest() if algo == "SHA1"
                 else hashlib.sha256(b).hexdigest())
            out.append(" %s %d %s" % (h, len(b), fn))
        return "%s:\n" % algo + "\n".join(out) + "\n"
    return head + "Date: %s\n\n" % date + block("MD5Sum") + "\n" + block("SHA1") + "\n" + block("SHA256") + "\n"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("deb", help="新 deb 路径")
    ap.add_argument("msg", nargs="?", default=None)
    args = ap.parse_args()
    if not os.path.isfile(args.deb):
        print("[!] 找不到文件:", args.deb); sys.exit(1)
    data = open(args.deb, "rb").read()
    pkg_name, new_ver = parse_control(data)
    if not pkg_name:
        print("[!] 无法解析 Package 字段"); sys.exit(1)
    filename = os.path.basename(args.deb)
    size = len(data)
    md5 = hashlib.md5(data).hexdigest()
    sha1 = hashlib.sha1(data).hexdigest()
    sha256 = hashlib.sha256(data).hexdigest()
    print("[*] Package: %s" % pkg_name)
    print("[*] New Version: %s" % new_ver)

    print("[1/5] 读取远端 Packages / Release ...")
    pkgs_text = get_raw("Packages")
    old_release = get_raw("Release")
    old_filename, old_version = find_old(pkgs_text, pkg_name)
    print("    远端当前: %s (v%s)" % (old_filename, old_version))

    print("[2/5] 更新 Packages ...")
    new_pkgs = build_new_stanza(pkgs_text, pkg_name, new_ver, "debs/%s" % filename, size, md5, sha1, sha256)
    if new_pkgs is None:
        stanza = ("Package: %s\nVersion: %s\nFilename: debs/%s\nSize: %d\nMD5sum: %s\nSHA1: %s\nSHA256: %s\n\n"
                  % (pkg_name, new_ver, filename, size, md5, sha1, sha256))
        new_pkgs = pkgs_text.rstrip() + "\n\n" + stanza
        print("    (首次发布，追加新 stanza)")
    pkgs_bytes = new_pkgs.encode("utf-8")
    gz = gzip.compress(pkgs_bytes, 9)
    bz2d = bz2.compress(pkgs_bytes, 9)

    print("[3/5] 更新 Release ...")
    new_release = build_release(pkgs_bytes, gz, bz2d, old_release)

    print("[4/5] 上传新 deb -> debs/%s" % filename)
    put_file("debs/%s" % filename, data, "%s %s" % (pkg_name, new_ver))

    print("[5/5] 回写 Packages/Packages.gz/Packages.bz2/Release")
    put_file("Packages", pkgs_bytes, "更新 Packages (%s %s)" % (pkg_name, new_ver), sha=get_sha("Packages"))
    put_file("Packages.gz", gz, "更新 Packages.gz (%s %s)" % (pkg_name, new_ver), sha=get_sha("Packages.gz"))
    put_file("Packages.bz2", bz2d, "更新 Packages.bz2 (%s %s)" % (pkg_name, new_ver), sha=get_sha("Packages.bz2"))
    put_file("Release", new_release.encode("utf-8"), "更新 Release (%s %s)" % (pkg_name, new_ver), sha=get_sha("Release"))

    # 清理同包旧 deb（避免 debs/ 越堆越多、regen 又加回来）
    try:
        listing = json.loads(gh("repositories/%s/contents/debs?ref=main" % repo_id()))
        for ent in listing:
            n = ent.get("name", "")
            if n.startswith(pkg_name + "_") and n != filename:
                try:
                    del_file("debs/%s" % n, ent["sha"], "移除旧版 %s" % n)
                    print("[+] 删除旧版: %s" % n)
                except Exception as e:
                    print("[!] 删旧失败: %s" % e)
    except Exception as e:
        print("[!] 列 debs/ 失败，跳过清理: %s" % e)

    print("\n✅ DONE! 源更新完毕: https://yzdmm2024.github.io/repo/")

if __name__ == "__main__":
    main()
