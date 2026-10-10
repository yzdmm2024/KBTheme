#!/usr/bin/env python3
"""LocSim 解锁码生成器 (与 dylib 算法完全一致)"""
import argparse
import hashlib
import sys

# 与 dylib 完全相同的字符集
CHARSET = "23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz"


def gen_code(device_udid):
    """SHA256(UDID) -> 15位解锁码 (社区标准方案)"""
    digest = hashlib.sha256(device_udid.encode("utf-8")).digest()
    code = ""
    for i in range(15):
        idx = (digest[i * 2 % len(digest)] << 8) | digest[(i * 2 + 1) % len(digest)]
        code += CHARSET[idx % len(CHARSET)]
    return code


def main():
    ap = argparse.ArgumentParser(description="LocSim 解锁码生成器")
    ap.add_argument("devid", nargs="?", help="设备的 UDID")
    args = ap.parse_args()

    if not args.devid:
        ap.error("请输入设备 UDID")

    code = gen_code(args.devid)
    print("=" * 60)
    print("  UDID    :", args.devid)
    print("  解锁码  :", code)
    print("=" * 60)


if __name__ == "__main__":
    main()