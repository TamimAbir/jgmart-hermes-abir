#!/usr/bin/env python3
"""
JG Mart — Auto-Deploy Script
=============================
One-command deploy of web apps to Vercel or Netlify.

USAGE:
    python auto_deploy.py --dashboard --vercel    # Deploy dashboard to Vercel
    python auto_deploy.py --catalog --netlify     # Deploy catalog to Netlify
    python auto_deploy.py --all --vercel          # Deploy everything to Vercel
    python auto_deploy.py --list                  # Show what can be deployed
    python auto_deploy.py --setup                 # Install deploy tools
"""

import os
import sys
import subprocess
import shutil
import json
from pathlib import Path

# Repo root: src/scripts/automation -> ../../..
BASE_DIR = Path(__file__).resolve().parent.parent.parent.parent

APPS = {
    "dashboard": {
        "dir": BASE_DIR / "src" / "web" / "dashboard",
        "files": ["index.html", "README.txt"],
        "description": "KPI / ops dashboard (HTML + localStorage paths)",
    },
    "catalog": {
        "dir": BASE_DIR / "src" / "web" / "catalog",
        "files": [
            "index.html",
            "catalog_data.json",
            "manifest.json",
            "order_intake.html",
        ],
        "description": "Customer catalog + order intake (WhatsApp handoff)",
    },
    "admin": {
        "dir": BASE_DIR / "src" / "web" / "admin-new",
        "files": ["index.html"],
        "description": "Supabase-backed admin panel",
    },
}


def check_vercel():
    return shutil.which("vercel") is not None


def check_netlify():
    return shutil.which("netlify") is not None


def list_apps():
    print("\n📦 JG Mart — Deployable Applications\n")
    for name, info in APPS.items():
        exists = info["dir"].is_dir()
        mark = "✓" if exists else "✗ missing"
        print(f"  {name}: [{mark}]")
        print(f"    📁 {info['dir'].relative_to(BASE_DIR)}/")
        print(f"    ℹ️  {info['description']}\n")


def setup_tools():
    print("🔧 Installing deploy tools...\n")

    if not check_vercel():
        print("  Installing Vercel CLI via npm...")
        subprocess.run(["npm", "install", "-g", "vercel"], check=False)

    if not check_netlify():
        print("  Installing Netlify CLI...")
        subprocess.run(["npm", "install", "-g", "netlify-cli"], check=False)

    print("\n  ✅ Setup complete!")
    print("  NOTE: Run `vercel login` or `netlify login` once.")


def deploy_vercel(app_name):
    info = APPS.get(app_name)
    if not info:
        print(f"❌ Unknown app: {app_name}")
        return 1

    app_dir = info["dir"]
    if not app_dir.is_dir():
        print(f"❌ Directory not found: {app_dir}")
        return 1

    print(f"\n{'='*60}")
    print(f"🚀 Deploying {app_name} to Vercel...")
    print(f"   Path: {app_dir}")
    print(f"{'='*60}\n")

    if not check_vercel():
        print("❌ Vercel CLI not found. Run: python auto_deploy.py --setup")
        return 1

    vercel_json = {
        "version": 2,
        "builds": [{"src": "**/*", "use": "@vercel/static"}],
        "routes": [{"src": "/(.*)", "dest": "/$1"}],
    }

    vpath = app_dir / "vercel.json"
    wrote_temp = False
    if not vpath.exists():
        with open(vpath, "w", encoding="utf-8") as f:
            json.dump(vercel_json, f, indent=2)
        wrote_temp = True

    result = subprocess.run(
        ["vercel", "--prod", "--yes"],
        cwd=str(app_dir),
    )

    if wrote_temp:
        vpath.unlink(missing_ok=True)

    if result.returncode == 0:
        print(f"\n✅ {app_name} deployed to Vercel successfully!")
    else:
        print(f"\n❌ Deployment failed (code {result.returncode})")
    return result.returncode


def deploy_netlify(app_name):
    info = APPS.get(app_name)
    if not info:
        print(f"❌ Unknown app: {app_name}")
        return 1

    app_dir = info["dir"]
    if not app_dir.is_dir():
        print(f"❌ Directory not found: {app_dir}")
        return 1

    print(f"\n{'='*60}")
    print(f"🚀 Deploying {app_name} to Netlify...")
    print(f"   Path: {app_dir}")
    print(f"{'='*60}\n")

    if not check_netlify():
        print("❌ Netlify CLI not found.")
        print("   Run: npm install -g netlify-cli && netlify login")
        return 1

    result = subprocess.run(
        ["netlify", "deploy", "--prod", "--dir", str(app_dir)],
    )

    if result.returncode == 0:
        print(f"\n✅ {app_name} deployed to Netlify successfully!")
    else:
        print(f"\n❌ Deployment failed (code {result.returncode})")
    return result.returncode


def main():
    if len(sys.argv) < 2:
        print("JG Mart — Auto-Deploy Tool\n")
        print("Usage:")
        print("  python auto_deploy.py --list")
        print("  python auto_deploy.py --setup")
        print("  python auto_deploy.py --catalog --vercel")
        print("  python auto_deploy.py --dashboard --netlify")
        print("  python auto_deploy.py --admin --vercel")
        print("  python auto_deploy.py --all --vercel")
        sys.exit(1)

    args = sys.argv[1:]
    target = None
    platform = None

    if "--setup" in args:
        setup_tools()
        return

    if "--list" in args:
        list_apps()
        return

    if "--dashboard" in args:
        target = "dashboard"
    elif "--catalog" in args:
        target = "catalog"
    elif "--admin" in args:
        target = "admin"
    elif "--all" in args:
        target = "all"

    if "--vercel" in args:
        platform = "vercel"
    elif "--netlify" in args:
        platform = "netlify"

    if not target or not platform:
        print("❌ Specify both app (--dashboard/--catalog/--admin/--all)")
        print("   and platform (--vercel/--netlify)")
        sys.exit(1)

    deploy_fn = deploy_vercel if platform == "vercel" else deploy_netlify

    if target == "all":
        code = 0
        for app in APPS:
            c = deploy_fn(app)
            if c != 0:
                code = c
        sys.exit(code)
    else:
        sys.exit(deploy_fn(target))


if __name__ == "__main__":
    main()
