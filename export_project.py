import os
from pathlib import Path

PROJECT_ROOT = Path(".")
OUTPUT_FILE = "project_context.txt"

# Что собирать
EXTENSIONS = [".gd", ".tscn", ".tres"]

# Что исключить
SKIP_DIRS = {".git", ".godot", ".import", "addons"}
SKIP_FILES = {"project_context.txt", "export_project.py"}

def export():
    lines = []
    lines.append("=" * 80)
    lines.append("СТРУКТУРА ПРОЕКТА")
    lines.append("=" * 80)
    
    # Дерево файлов
    tree = []
    for root, dirs, files in os.walk(PROJECT_ROOT):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        level = root.replace(str(PROJECT_ROOT), "").count(os.sep)
        indent = "  " * level
        tree.append(f"{indent}{os.path.basename(root)}/")
        sub_indent = "  " * (level + 1)
        for f in sorted(files):
            if f not in SKIP_FILES and Path(f).suffix in EXTENSIONS:
                tree.append(f"{sub_indent}{f}")
    lines.extend(tree)
    
    # Содержимое файлов
    lines.append("\n" + "=" * 80)
    lines.append("СОДЕРЖИМОЕ СКРИПТОВ")
    lines.append("=" * 80 + "\n")
    
    for root, dirs, files in os.walk(PROJECT_ROOT):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for f in sorted(files):
            if Path(f).suffix not in EXTENSIONS:
                continue
            if f in SKIP_FILES:
                continue
            full = os.path.join(root, f)
            try:
                content = Path(full).read_text(encoding="utf-8")
            except:
                content = "[не удалось прочитать]"
            lines.append(f"--- {full} ---")
            lines.append(content)
            lines.append("")
    
    Path(OUTPUT_FILE).write_text("\n".join(lines), encoding="utf-8")
    print(f"Экспортировано в {OUTPUT_FILE} ({len(lines)} строк)")

if __name__ == "__main__":
    export()