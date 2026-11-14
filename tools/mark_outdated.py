"""Marks released versions as outdated for the in-game update check (aio_gui_fnc_updateCheck).

The game can only ask whether an address loads. So for every released version that a newer Workshop release replaced
there is a file updates/outdated/<version>.html in this repository, on the main branch; a build that finds its own
version there tells its player that a newer one is on Steam.

Run it right after a Workshop update, with the version(s) that were live before it, then commit and push:

    python tools/mark_outdated.py 0.7.22
    python tools/mark_outdated.py 0.7.22 0.7.23

Never mark the version that is live on the Workshop now: every player would be told to update with nothing to update to.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TARGET = ROOT / "updates" / "outdated"
VERSION_FILE = ROOT / "addons" / "main" / "script_version.hpp"


def current_version() -> str:
    text = VERSION_FILE.read_text(encoding="utf-8")
    parts = [re.search(r"#define\s+%s\s+(\d+)" % key, text).group(1) for key in ("MAJOR", "MINOR", "PATCH")]
    return ".".join(parts)


def main() -> int:
    versions = sys.argv[1:]

    if not versions:
        print(__doc__)
        return 1

    now = current_version()

    for version in versions:
        if not re.fullmatch(r"\d+(\.\d+)*", version):
            print("Not a version: %s" % version)
            return 1

        if version == now:
            print("%s is the version in the repository now - not marked." % version)
            return 1

    TARGET.mkdir(parents=True, exist_ok=True)

    for version in versions:
        path = TARGET / ("%s.html" % version)
        path.write_text("<html><body>Arma Inventory Overhaul %s is outdated.</body></html>\n" % version, encoding="utf-8")
        print("Marked %s: %s" % (version, path.relative_to(ROOT)))

    return 0


if __name__ == "__main__":
    sys.exit(main())
