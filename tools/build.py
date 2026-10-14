#!/usr/bin/env python3
"""Builds invite/index.html and join/index.html from tools/ and pins the CSP to
the exact inline <style>/<script> bytes (SHA-256), so nothing else can run.
Run after editing anything in tools/:   python3 tools/build.py
"""
import base64, hashlib, pathlib

root = pathlib.Path(__file__).resolve().parent.parent
tools = root / "tools"
template = (tools / "page.template.html").read_text()
style = (tools / "style.css").read_text().strip()

def sha(text):
    return base64.b64encode(hashlib.sha256(text.encode()).digest()).decode()

for name, scheme_path in (("invite", "invite"), ("join", "join")):
    script = (tools / f"script.{name}.js").read_text().strip()
    html = (template
            .replace("@@STYLE_HASH@@", sha(style)).replace("@@SCRIPT_HASH@@", sha(script))
            .replace("@@STYLE@@", style).replace("@@SCRIPT@@", script)
            .replace("@@SCHEME_PATH@@", scheme_path))
    (root / name / "index.html").write_text(html)
    print(f"built {name}/index.html")
