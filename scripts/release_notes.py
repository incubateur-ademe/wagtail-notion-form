"""Dates the [Unreleased] entries of CHANGELOG.md as a release and prints them, for
`just release`: `python scripts/release_notes.py 0.2.0 > notes.md`."""

import datetime
import pathlib
import sys

version = sys.argv[1]
changelog = pathlib.Path(__file__).parent.parent / "CHANGELOG.md"
text = changelog.read_text()
head, marker, rest = text.partition("## [Unreleased]\n")
if not marker:
    sys.exit("CHANGELOG.md has no '## [Unreleased]' section.")
next_release = rest.find("\n## [")
entries = rest[: len(rest) if next_release == -1 else next_release]
notes = entries.split("<!-- TEMPLATE")[0].strip()
if not notes:
    sys.exit("Nothing under [Unreleased] in CHANGELOG.md: describe the release first.")
today = datetime.date.today().isoformat()
changelog.write_text(f"{head}{marker}\n## [{version}] - {today}\n\n{rest.lstrip()}")
print(notes)
