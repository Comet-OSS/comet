#!/usr/bin/env python3
"""
Convert Roblox-style require(script.X) paths to file-based require("./X") paths.

Usage:
    python convert_paths.py <src_directory>
Flags:
    --dry-run
    --no-self-alias
    --lua-to-luau
"""

import re
import sys
import argparse
from pathlib import Path

def is_init_file(filepath: Path) -> bool:
    return filepath.stem == "init"


def resolve_script_chain(expr: str, aliases: dict) -> str | None:
    """
    Resolve an expression to a normalised "script[.Parent...][.Module...]" string.
    Returns None if the expression doesn't trace back to script.
    """
    expr = expr.strip()
    if expr == "script" or expr.startswith("script."):
        return expr
    dot = expr.find(".")
    varname = expr[:dot] if dot != -1 else expr
    rest = expr[dot:] if dot != -1 else ""
    if varname in aliases:
        return aliases[varname] + rest
    return None


def chain_to_path(chain: str, is_init: bool, use_self_alias: bool) -> str | None:
    """
    Convert a normalised script chain to a relative file path string.

    Regular file offset: script.Parent = same dir, so subtract 1 from parent count.
    Init file offset:    script = same dir, no subtraction needed.
    """
    rest = chain[len("script"):]
    if not rest:
        return None

    parts = rest.lstrip(".").split(".")
    parent_count = 0
    while parts and parts[0] == "Parent":
        parent_count += 1
        parts.pop(0)

    if not parts:
        return None

    module_path = "/".join(parts)

    if is_init:
        if parent_count == 0:
            prefix = "@self/" if use_self_alias else "./"
            return prefix + module_path
        else:
            return "../" * parent_count + module_path
    else:
        effective = parent_count - 1
        if effective <= 0:
            return "./" + module_path
        else:
            return "../" * effective + module_path


def extract_aliases(content: str) -> dict:
    """
    Find all  local X = script.Parent...  and chained aliases in the file.
    Returns {varname: "script.Parent.Parent..."} map.
    """
    aliases: dict = {}

    for m in re.finditer(
        r'^\s*local\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(script(?:\.[A-Za-z_][A-Za-z0-9_]*)*)',
        content, re.MULTILINE
    ):
        aliases[m.group(1)] = m.group(2)

    chained = re.compile(
        r'^\s*local\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*)',
        re.MULTILINE
    )
    for _ in range(10):
        changed = False
        for m in chained.finditer(content):
            varname = m.group(1)
            if varname in aliases:
                continue
            rhs = m.group(0).split("=", 1)[1].strip()
            rhs = re.split(r'\s*--', rhs)[0].strip()
            resolved = resolve_script_chain(rhs, aliases)
            if resolved is not None:
                aliases[varname] = resolved
                changed = True
        if not changed:
            break

    return aliases


def process_file(filepath: Path, dry_run: bool, use_self_alias: bool, lua_to_luau: bool) -> tuple:
    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception as e:
        print(f"  [ERROR] {filepath}: {e}")
        return 0, [], filepath

    original = content
    changes: list = []
    count = 0
    is_init = is_init_file(filepath)
    aliases = extract_aliases(content)

    def replacer(m: re.Match) -> str:
        nonlocal count
        old = m.group(0)
        chain = resolve_script_chain(m.group(1), aliases)
        if chain is None:
            return old
        rel = chain_to_path(chain, is_init, use_self_alias)
        if rel is None:
            return old
        new = f'require("{rel}")'
        if new != old:
            count += 1
            changes.append(f"    {old}  ->  {new}")
        return new

    new_content = re.sub(
        r'require\s*\(\s*([A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*)\s*\)',
        replacer, content
    )

    for varname, chain in aliases.items():
        if not chain.startswith("script"):
            continue
        decl_re = re.compile(
            r'^\s*local\s+' + re.escape(varname) + r'\s*=\s*' + re.escape(chain) + r'[^\n]*\n?',
            re.MULTILINE
        )
        all_uses = len(re.findall(r'\b' + re.escape(varname) + r'\b', new_content))
        decl_uses = len(re.findall(
            r'^\s*local\s+' + re.escape(varname) + r'\s*=', new_content, re.MULTILINE
        ))
        if all_uses - decl_uses == 0:
            before = new_content
            new_content = decl_re.sub("", new_content)
            if new_content != before:
                changes.append(f"    [removed unused alias] local {varname} = {chain}")

    # Determine the output path
    target = filepath.with_suffix(".luau") if (lua_to_luau and filepath.suffix == ".lua") else filepath

    if not dry_run:
        # Write if content changed OR if we're renaming to .luau
        if new_content != original or target != filepath:
            try:
                target.write_text(new_content, encoding="utf-8")
            except Exception as e:
                print(f"  [ERROR] writing {target}: {e}")
        if target != filepath:
            try:
                filepath.unlink()
            except Exception as e:
                print(f"  [ERROR] deleting {filepath}: {e}")
            changes.append(f"    [renamed to .luau] {filepath.name} -> {target.name}")
    else:
        if target != filepath:
            changes.append(f"    [would rename to .luau] {filepath.name} -> {target.name}")

    return count, changes, target


def main():
    parser = argparse.ArgumentParser(description="Convert Roblox script.X requires to file path requires.")
    parser.add_argument("src", help="Source directory to process")
    parser.add_argument("--dry-run", action="store_true", help="Preview changes without writing files")
    parser.add_argument("--no-self-alias", action="store_true", help="Don't use @self for init.luau siblings")
    parser.add_argument("--lua-to-luau", action="store_true", help="Write modified .lua files to .luau instead of overwriting the original .lua")
    args = parser.parse_args()

    src = Path(args.src)
    if not src.is_dir():
        print(f"Error: '{src}' is not a directory.")
        sys.exit(1)

    if args.dry_run:
        print("=== DRY RUN - no files will be modified ===\n")

    total_files = 0
    total_changes = 0

    for luau_file in sorted(src.rglob("*")):
        if luau_file.suffix not in (".lua", ".luau"):
            continue
        count, changes, written_path = process_file(luau_file, args.dry_run, not args.no_self_alias, args.lua_to_luau)
        if changes:
            total_files += 1
            total_changes += count
            rel = written_path.relative_to(src)
            init_tag = " [init]" if is_init_file(written_path) else ""
            print(f"  {rel}{init_tag}  ({count} change{'s' if count != 1 else ''})")
            for c in changes:
                print(c)
            print()

    print(
        f"{'Would modify' if args.dry_run else 'Modified'} "
        f"{total_files} file(s) with {total_changes} total replacement(s)."
    )
    if args.dry_run:
        print("Run without --dry-run to apply changes.")


if __name__ == "__main__":
    main()