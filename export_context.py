#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
export_context.py — экспорт контекста Godot-проекта в project_context.txt.

Использование:
    python export_context.py                      # если скрипт лежит в корне проекта
    python export_context.py F:/development/click-defence   # из любого места

Файл project_context.txt потом прикрепляется к диалогу с ИИ-ассистентом.
"""

import subprocess
import sys
from pathlib import Path

# Корень проекта: аргумент командной строки или папка, где лежит скрипт
ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parent
OUT_FILE = ROOT / "project_context.txt"

# Текстовые расширения, которые попадают в контекст
INCLUDE_EXT = {".gd", ".tscn", ".tres", ".godot", ".md", ".cfg"}
# Файлы без расширения / спец-имена, которые тоже нужны
INCLUDE_NAMES = {"LICENSE", ".gitignore", ".editorconfig", ".gitattributes"}

# Папки, которые пропускаем целиком
SKIP_DIRS = {".git", ".godot", "export", "exports", "__pycache__", ".vscode", ".idea"}
# Файлы, которые пропускаем (генерируемое и сам скрипт)
SKIP_NAMES = {"project_context.txt", "export_context.py"}

MAX_FILE_BYTES = 300_000   # не читать файлы больше этого размера

# Порядок секций отчёта
SECTION_ORDER = [".godot", ".gd", ".tscn", ".tres", ".md", ".cfg"]
SECTION_TITLES = {
    ".godot": "НАСТРОЙКИ ПРОЕКТА (project.godot)",
    ".gd": "СКРИПТЫ (.gd)",
    ".tscn": "СЦЕНЫ (.tscn)",
    ".tres": "РЕСУРСЫ-ДАННЫЕ (.tres)",
    ".md": "ДОКУМЕНТАЦИЯ",
    ".cfg": "НАСТРОЙКИ ЭКСПОРТА",
}


def collect_files() -> list:
    """Все текстовые файлы проекта, кроме служебных папок и генерируемого."""
    result = []
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        rel = path.relative_to(ROOT)
        if any(part in SKIP_DIRS for part in rel.parts):
            continue
        if path.name in SKIP_NAMES:
            continue
        if path.suffix in INCLUDE_EXT or path.name in INCLUDE_NAMES:
            result.append(path)
    return result


def build_tree() -> str:
    """Структура проекта: папки и файлы с размерами."""
    lines = []

    def walk(directory: Path, prefix: str) -> None:
        entries = sorted(
            (p for p in directory.iterdir()
             if p.name not in SKIP_DIRS and p.name not in SKIP_NAMES),
            key=lambda p: (p.is_file(), p.name.lower()),
        )
        for entry in entries:
            if entry.is_dir():
                lines.append(prefix + entry.name + "/")
                walk(entry, prefix + "    ")
            else:
                size_kb = entry.stat().st_size / 1024
                lines.append(prefix + entry.name + "  (" + format(size_kb, ".1f") + " KB)")

    walk(ROOT, "")
    return "\n".join(lines)


def git_snapshot() -> str:
    """Последние коммиты и статус репозитория (если git доступен)."""
    try:
        log = subprocess.run(
            ["git", "log", "--oneline", "-15"],
            cwd=ROOT, capture_output=True, text=True, timeout=10,
        ).stdout.strip()
        status = subprocess.run(
            ["git", "status", "--short"],
            cwd=ROOT, capture_output=True, text=True, timeout=10,
        ).stdout.strip()
        return "Последние коммиты:\n" + log + "\n\nНезакоммиченные изменения:\n" + (status or "(чисто)")
    except Exception:
        return "(git недоступен)"


def file_block(path: Path) -> str:
    """Один файл в отчёте: заголовок + содержимое."""
    rel = path.relative_to(ROOT).as_posix()
    if path.stat().st_size > MAX_FILE_BYTES:
        return "\n----- ФАЙЛ: " + rel + " : ПРОПУЩЕН (слишком большой) -----"
    text = path.read_text(encoding="utf-8", errors="replace")
    return "\n----- ФАЙЛ: " + rel + " -----\n" + text.rstrip()


def main() -> None:
    files = collect_files()
    blocks = []

    blocks.append("=" * 80)
    blocks.append("СТРУКТУРА ПРОЕКТА")
    blocks.append("=" * 80)
    blocks.append(build_tree())

    blocks.append("")
    blocks.append("=" * 80)
    blocks.append("СОСТОЯНИЕ GIT")
    blocks.append("=" * 80)
    blocks.append(git_snapshot())

    for ext in SECTION_ORDER:
        group = sorted(f for f in files if f.suffix == ext)
        if not group:
            continue
        blocks.append("")
        blocks.append("=" * 80)
        blocks.append(SECTION_TITLES[ext])
        blocks.append("=" * 80)
        for path in group:
            blocks.append(file_block(path))

    # Файлы, взятые по имени (LICENSE, .gitignore и т.п.)
    named = sorted(f for f in files if f.suffix not in INCLUDE_EXT)
    if named:
        blocks.append("")
        blocks.append("=" * 80)
        blocks.append("ПРОЧИЕ ФАЙЛЫ (LICENSE, .gitignore)")
        blocks.append("=" * 80)
        for path in named:
            blocks.append(file_block(path))

    OUT_FILE.write_text("\n".join(blocks) + "\n", encoding="utf-8")
    total_kb = OUT_FILE.stat().st_size / 1024
    print("Готово:", OUT_FILE.name, "(" + format(total_kb, ".1f") + " KB), файлов в контексте:", len(files))


if __name__ == "__main__":
    main()