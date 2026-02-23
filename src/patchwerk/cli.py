"""patchwerk CLI — distribute agent configuration files across repos."""

from __future__ import annotations

import argparse
import shutil
import sys
from importlib import resources
from pathlib import Path

# Paths overwritten on sync (user may customise others)
MANAGED_PATHS = frozenset({".agent-skills", ".agent-defs", ".mcp.json", "orchestration"})

# Relative posix prefixes to skip during template iteration (Windows junctions)
SKIP_PREFIXES = (".claude/agents/", ".claude/skills/")

# Allowlist for .claude/ items copied during stage (never touch junctions)
CLAUDE_ALLOWLIST = frozenset({"CLAUDE.md", "commands", "docs", "hooks"})

# Ordered list of items copied from repo root during stage
STAGE_SOURCES = ["AGENTS.md", ".mcp.json", ".claude", ".gemini", ".agent-skills", ".agent-defs", "orchestration"]


def _is_managed(rel: Path) -> bool:
    """True if rel is under a patchwerk-managed path."""
    top = rel.parts[0] if rel.parts else ""
    return top in MANAGED_PATHS


def _iter_template_files(templates_path: Path):
    """Yield (src_file, rel) for all files in templates_path, skipping junction paths."""
    for src_file in sorted(templates_path.rglob("*")):
        if not src_file.is_file():
            continue
        rel = src_file.relative_to(templates_path)
        rel_posix = rel.as_posix()
        if any(rel_posix.startswith(skip) for skip in SKIP_PREFIXES):
            continue
        yield src_file, rel


def _copy_file(src: Path, dst: Path, *, skip_existing: bool, check_only: bool) -> str:
    """Copy src to dst. Returns action: 'copy', 'skip', 'update', or 'up-to-date'."""
    if dst.exists():
        if skip_existing:
            return "skip"
        if dst.read_bytes() == src.read_bytes():
            return "up-to-date"
        if not check_only:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
        return "update"
    else:
        if not check_only:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
        return "copy"


def _run_copy(
    templates_path: Path,
    target: Path,
    *,
    skip_existing: bool,
    managed_only: bool,
    check_only: bool,
) -> bool:
    """Copy templates to target. Returns True if any file changed or would change."""
    any_change = False
    for src_file, rel in _iter_template_files(templates_path):
        if managed_only and not _is_managed(rel):
            continue
        dst = target / rel
        action = _copy_file(src_file, dst, skip_existing=skip_existing, check_only=check_only)
        if action in ("copy", "update"):
            any_change = True
        print(f"  {action:<12} {rel.as_posix()}")
    return any_change


def cmd_init(target: Path) -> None:
    """Copy all template files to target, skipping files that already exist."""
    pkg_ref = resources.files("patchwerk").joinpath("templates")
    with resources.as_file(pkg_ref) as templates_path:
        print(f"Initializing {target}")
        _run_copy(templates_path, target, skip_existing=True, managed_only=False, check_only=False)
    print("Done.")


def cmd_sync(target: Path, *, check_only: bool = False) -> None:
    """Overwrite managed paths in target with bundled template versions."""
    pkg_ref = resources.files("patchwerk").joinpath("templates")
    with resources.as_file(pkg_ref) as templates_path:
        verb = "Checking" if check_only else "Syncing"
        print(f"{verb} managed files in {target}")
        has_changes = _run_copy(
            templates_path,
            target,
            skip_existing=False,
            managed_only=True,
            check_only=check_only,
        )
    if check_only and not has_changes:
        print("All managed files are up to date.")
    elif not check_only:
        print("Done.")


def cmd_diff(target: Path) -> None:
    """Show what sync would change without modifying any files."""
    cmd_sync(target, check_only=True)


def _stage_claude(src_claude: Path, dst_claude: Path) -> None:
    """Copy allowlisted .claude/ items only — skips junctions entirely."""
    for name in CLAUDE_ALLOWLIST:
        src_item = src_claude / name
        if not src_item.exists():
            continue
        dst_item = dst_claude / name
        if src_item.is_dir():
            if dst_item.exists():
                shutil.rmtree(dst_item)
            shutil.copytree(src_item, dst_item)
        else:
            dst_claude.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src_item, dst_item)


def _stage_gemini(src_gemini: Path, dst_gemini: Path) -> None:
    """Copy GEMINI.md only — skips junctions entirely."""
    gemini_md = src_gemini / "GEMINI.md"
    if gemini_md.exists():
        dst_gemini.mkdir(parents=True, exist_ok=True)
        shutil.copy2(gemini_md, dst_gemini / "GEMINI.md")


def cmd_stage(repo_root: Path) -> None:
    """[Maintainer] Copy source files from repo_root into src/patchwerk/templates/."""
    templates_dir = Path(__file__).parent / "templates"
    templates_dir.mkdir(parents=True, exist_ok=True)
    print(f"Staging {repo_root} -> {templates_dir}")

    for name in STAGE_SOURCES:
        src = repo_root / name
        if not src.exists():
            print(f"  skip         {name} (not found)")
            continue
        dst = templates_dir / name

        if name == ".claude":
            dst.mkdir(parents=True, exist_ok=True)
            _stage_claude(src, dst)
            print(f"  staged       .claude/ (allowlisted: {', '.join(sorted(CLAUDE_ALLOWLIST))})")
        elif name == ".gemini":
            _stage_gemini(src, dst)
            print(f"  staged       .gemini/GEMINI.md")
        elif src.is_dir():
            if dst.exists():
                shutil.rmtree(dst)
            shutil.copytree(src, dst)
            print(f"  staged       {name}/")
        else:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            print(f"  staged       {name}")

    print("Done.")
    print("Next: git add src/patchwerk/templates/ && git commit -m 'chore: update templates'")


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="patchwerk",
        description="Distribute agent configuration files across repos.",
    )
    parser.add_argument(
        "--target",
        type=Path,
        default=Path.cwd(),
        metavar="DIR",
        help="Target repository directory (default: current directory)",
    )
    sub = parser.add_subparsers(dest="command", metavar="COMMAND")
    sub.required = True

    sub.add_parser("init", help="Copy all template files to target (skip existing)")
    sub.add_parser("sync", help="Overwrite managed paths (.agent-skills, .agent-defs, .mcp.json)")
    sub.add_parser("diff", help="Show what sync would change without modifying files")
    sub.add_parser("stage", help="[Maintainer] Copy repo files into templates/ for bundling")

    args = parser.parse_args()
    target = args.target.resolve()

    match args.command:
        case "init":
            cmd_init(target)
        case "sync":
            cmd_sync(target)
        case "diff":
            cmd_diff(target)
        case "stage":
            cmd_stage(target)
        case _:
            parser.print_help()
            sys.exit(1)


if __name__ == "__main__":
    main()
