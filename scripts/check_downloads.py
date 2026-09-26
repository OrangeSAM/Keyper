#!/usr/bin/env python3
"""
Keyper GitHub Releases Download Stats Checker
Usage: python3 scripts/check_downloads.py
"""

import json
import sys
import urllib.request

REPO = "OrangeSAM/Keyper"
API_URL = f"https://api.github.com/repos/{REPO}/releases"

def get_stats():
    print(f"\n📊 正在查询 GitHub 仓库 [{REPO}] 的实时下载统计...\n" + "=" * 55)
    req = urllib.request.Request(API_URL, headers={"User-Agent": "KeyperStats/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            releases = json.loads(response.read().decode())
    except Exception as e:
        print(f"❌ 获取失败: {e}")
        sys.exit(1)

    if not releases:
        print("未发现任何 Release 发布记录。")
        return

    total_downloads = 0
    total_dmg = 0
    total_pkg = 0

    for r in releases:
        tag = r.get("tag_name", "Unknown")
        name = r.get("name", tag)
        created_at = r.get("created_at", "")[:10]
        published_at = r.get("published_at", "")[:10]
        assets = r.get("assets", [])
        
        release_total = sum(a.get("download_count", 0) for a in assets)
        total_downloads += release_total

        print(f"\n📦 版本: {tag} ({name}) · 发布日期: {published_at or created_at}")
        print(f"   版本累计下载: {release_total} 次")
        print("   资源清单:")
        for a in assets:
            a_name = a.get("name")
            cnt = a.get("download_count", 0)
            size_mb = round(a.get("size", 0) / (1024 * 1024), 2)
            if a_name.endswith(".dmg"):
                total_dmg += cnt
            elif a_name.endswith(".pkg"):
                total_pkg += cnt
            print(f"     • {a_name:<25} {size_mb:>6} MB  -> {cnt:>5} 次下载")

    print("\n" + "=" * 55)
    print(f"🎉 【Keyper 全版本累计总下载量】: {total_downloads} 次")
    print(f"   - DMG 镜像安装包下载: {total_dmg} 次")
    print(f"   - PKG 安装引导包下载: {total_pkg} 次")
    print("=" * 55 + "\n")

if __name__ == "__main__":
    get_stats()
