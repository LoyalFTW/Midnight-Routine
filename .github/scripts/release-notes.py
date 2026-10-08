import argparse
import os
import subprocess
from pathlib import Path


def git(*args):
    return subprocess.check_output(["git", *args], text=True, encoding="utf-8").strip()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("folder", choices=["Routine", "RoutineData"])
    args = parser.parse_args()
    tag = os.environ["GITHUB_REF_NAME"]
    prefix = "dv*" if args.folder == "RoutineData" else "v*"
    previous = subprocess.run(
        ["git", "describe", "--tags", "--match", prefix, "--abbrev=0", f"{tag}^"],
        capture_output=True, text=True,
    )
    previous_tag = previous.stdout.strip() if previous.returncode == 0 else ""
    revision_range = f"{previous_tag}..{tag}" if previous_tag else tag
    messages = git("log", "--format=%B%x00", revision_range, "--", args.folder)
    server = os.environ.get("GITHUB_SERVER_URL", "https://github.com")
    repository_url = f'{server}/{os.environ["GITHUB_REPOSITORY"]}'
    changes_url = (
        f"{repository_url}/compare/{previous_tag}...{tag}"
        if previous_tag else f"{repository_url}/commits/{tag}/{args.folder}"
    )
    title = "Midnight Routine" if args.folder == "Routine" else "RoutineData"
    lines = [f"# {title}", "", f"## {tag}", f"[Full Changelog]({changes_url})", ""]
    for message in messages.split("\0"):
        message_lines = message.strip().splitlines()
        if message_lines:
            lines.append(f"- {message_lines[0]}")
            lines.extend(f"    {line}" if line else "" for line in message_lines[1:])
    destination = Path(os.environ["RUNNER_TEMP"]) / f"{args.folder}-release-notes"
    destination.mkdir(parents=True, exist_ok=True)
    notes = destination / "CHANGELOG.md"
    notes.write_text("\n".join(lines) + "\n", encoding="utf-8")
    notes_path = Path(os.path.relpath(notes, Path(args.folder).resolve())).as_posix()
    metadata = destination / ".pkgmeta"
    original = (Path(args.folder) / ".pkgmeta").read_text(encoding="utf-8")
    metadata.write_text(
        original.rstrip() + f'\n\nmanual-changelog:\n  filename: "{notes_path}"\n  markup-type: markdown\n',
        encoding="utf-8",
    )
    with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as output:
        output.write(f"RELEASE_PKGMETA={metadata.as_posix()}\n")


if __name__ == "__main__":
    main()
