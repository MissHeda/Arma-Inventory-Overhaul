"""Lists code of the mod that nothing uses any more.

Run from anywhere:  python -I tools/find_dead_code.py

Three reports, all read-only (nothing is changed or deleted):

  1. Functions - every addons/*/functions/fnc_*.sqf whose name is used nowhere but in its own file and in
     the XEH_PREP line that compiles it. "Used" means FUNC(name), EFUNC(addon,name), QFUNC / QEFUNC /
     QQFUNC / DFUNC / DEFUNC, or the literal einv_<addon>_fnc_<name>, in code with the comments left out
     (a name that only a comment or a document mentions is not used). Functions marked "Public: Yes" in
     their header are listed apart: other mods or missions may call them. Also: PREP lines without a file,
     and files no PREP line compiles.
  2. Variables - every GVAR defined in an addon's XEH_preInit.sqf that nothing else reads: no other mention
     at all, or only assignments to it.
  3. Defines - every #define in the addons that nothing uses (looked at again after the unused ones are
     taken away, since one may be used by another unused define only).

The search is by text, so a name put together at run time ("einv_" + _x) would escape it: look at the
list before deleting.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ADDONS = ROOT / "addons"

CODE_SUFFIXES = (".sqf", ".hpp", ".cpp", ".ext", ".sqm")
DOC_FILES = [ROOT / "README.md", ROOT / "CHANGELOG.md"] + sorted((ROOT / "docs").rglob("*.md"))

# Names a define or variable has for something outside the project (CBA's and HEMTT's own includes read
# these), so no use inside the project is expected.
EXTERNAL_DEFINES = {
    "COMPONENT", "COMPONENT_BEAUTIFIED", "COMPONENT_NAME", "MAINPREFIX", "PREFIX", "MAJOR", "MINOR", "PATCH",
    "VERSION", "VERSION_STR", "VERSION_AR", "VERSION_CONFIG", "REQUIRED_VERSION", "DEBUG_SYNCHRONOUS",
}


def read(path):
    return path.read_text(encoding="utf-8", errors="replace")


def strip_comments(text):
    """The text with // and /* */ comments blanked out, strings left as they are ("" is a quote inside one)."""
    out = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c in "\"'":
            j = i + 1
            while j < n:
                if text[j] == c:
                    if j + 1 < n and text[j + 1] == c:
                        j += 2
                        continue
                    break
                j += 1
            out.append(text[i : j + 1])
            i = j + 1
        elif text.startswith("//", i):
            j = text.find("\n", i)
            j = n if j < 0 else j
            i = j
        elif text.startswith("/*", i):
            j = text.find("*/", i + 2)
            j = n if j < 0 else j + 2
            out.append("\n" * text.count("\n", i, j))
            i = j
        else:
            out.append(c)
            i += 1
    return "".join(out)


def addon_of(path):
    rel = path.relative_to(ADDONS).parts
    return rel[0]


# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------

addons = sorted(p.name for p in ADDONS.iterdir() if p.is_dir())

code = {}  # path -> text without comments
for path in sorted(ADDONS.rglob("*")):
    if path.is_file() and path.suffix in CODE_SUFFIXES:
        code[path] = strip_comments(read(path))
for extra in sorted((ROOT / "tools").glob("*.sqf")) + sorted((ROOT / ".hemtt").rglob("*")):
    if extra.is_file() and extra.suffix in CODE_SUFFIXES:
        code[extra] = strip_comments(read(extra))

docs = {path: read(path) for path in DOC_FILES if path.exists()}

# ---------------------------------------------------------------------------
# 1. Functions
# ---------------------------------------------------------------------------

addon_alt = "|".join(sorted(addons, key=len, reverse=True))
FUNC_RE = re.compile(r"(?<![A-Za-z0-9_])(?:QQ|Q)?D?(E)?FUNC\(([^()]*)\)")
LIT_FUNC_RE = re.compile(r"(?<![A-Za-z0-9_])einv_(%s)_fnc_([A-Za-z0-9_]+)" % addon_alt, re.I)
PREP_RE = re.compile(r"^\s*PREP\((\w+)\)\s*;", re.M)


def function_refs(text, own_addon):
    """The (addon, name) pairs a text uses, lowercase."""
    refs = set()
    for m in FUNC_RE.finditer(text):
        args = [a.strip() for a in m.group(2).split(",")]
        if m.group(1):
            if len(args) == 2:
                refs.add((args[0].lower(), args[1].lower()))
        elif len(args) == 1:
            refs.add((own_addon.lower(), args[0].lower()))
    for m in LIT_FUNC_RE.finditer(text):
        refs.add((m.group(1).lower(), m.group(2).lower()))
    return refs


functions = {}  # (addon, name) -> path
for path in sorted(ADDONS.glob("*/functions/fnc_*.sqf")):
    if path.name.endswith(".inc.sqf"):
        continue
    functions[(addon_of(path).lower(), path.stem[4:].lower())] = path

prepped = {}  # (addon, name) -> PREP file
for path in sorted(ADDONS.glob("*/XEH_PREP*.hpp")):
    for m in PREP_RE.finditer(strip_comments(read(path))):
        prepped[(addon_of(path).lower(), m.group(1).lower())] = path

refs_of = {}  # code file -> the functions it uses
for path, text in code.items():
    own = addon_of(path) if ADDONS in path.parents else ""
    refs_of[path] = {ref for ref in function_refs(text, own) if ref in functions and path != functions[ref]}


def is_public(path):
    return re.search(r"^\s*\*\s*Public:\s*Yes", read(path), re.M) is not None


# A function is dead when no live file uses it. A private function that is dead stops counting as a user
# in turn, so a chain of helpers only a dead function called comes out too.
dead_private = set()
while True:
    used = set()
    for path, refs in refs_of.items():
        if path in {functions[key] for key in dead_private}:
            continue
        used |= refs
    newly = {key for key in functions if key not in used and key not in dead_private and not is_public(functions[key])}
    if not newly:
        break
    dead_private |= newly
used_by = {key: key in used for key in functions}

doc_refs = {key: [] for key in functions}
for path, text in docs.items():
    for key in functions:
        name = key[1]
        if re.search(r"(?<![A-Za-z0-9_])(einv_%s_)?fnc_%s(?![A-Za-z0-9_])" % (re.escape(key[0]), re.escape(name)), text, re.I):
            doc_refs[key].append(path.relative_to(ROOT).as_posix())


def rel(path):
    return path.relative_to(ROOT).as_posix()


dead_private = sorted(dead_private)
dead_public = sorted(key for key in functions if not used_by[key] and is_public(functions[key]) and key not in dead_private)

print("=== 1. Functions ===")
print("%d functions, %d PREP lines" % (len(functions), len(prepped)))
print()
print("Dead, Public: No (%d):" % len(dead_private))
for key in dead_private:
    docs_in = ", ".join(doc_refs[key]) or "-"
    print("  einv_%s_fnc_%s    %s    docs: %s" % (key[0], functions[key].stem[4:], rel(functions[key]), docs_in))
print()
print("Dead, Public: Yes - kept, other mods may call them (%d):" % len(dead_public))
for key in dead_public:
    print("  einv_%s_fnc_%s    %s" % (key[0], functions[key].stem[4:], rel(functions[key])))
print()
print("PREP lines without a file:")
for key in sorted(set(prepped) - set(functions)):
    print("  %s: PREP(%s)" % (rel(prepped[key]), key[1]))
print("Function files without a PREP line:")
for key in sorted(set(functions) - set(prepped)):
    print("  %s" % rel(functions[key]))

# ---------------------------------------------------------------------------
# 2. Variables
# ---------------------------------------------------------------------------

GVAR_RE = re.compile(r"(?<![A-Za-z0-9_])(?:QQ|Q)?(E)?GVAR\(([^()]*)\)")
LIT_GVAR_RE = re.compile(r"(?<![A-Za-z0-9_])einv_(%s)_([A-Za-z0-9_]+)" % addon_alt, re.I)
ASSIGN_AFTER = re.compile(r"\s*=(?!=)")
SET_BEFORE = re.compile(r"(?:missionNamespace|uiNamespace|profileNamespace|parsingNamespace)\s+setVariable\s*\[\s*$", re.I)


def gvar_mentions(text, own_addon):
    """(addon, name, is_assignment, position) for every mention of a variable of ours in a text."""
    result = []
    for m in GVAR_RE.finditer(text):
        args = [a.strip() for a in m.group(2).split(",")]
        if m.group(1):
            if len(args) != 2:
                continue
            addon, name = args
        else:
            addon, name = own_addon, args[0]
        is_set = bool(ASSIGN_AFTER.match(text, m.end())) or bool(SET_BEFORE.search(text[max(0, m.start() - 60) : m.start()]))
        result.append((addon.lower(), name.lower(), is_set, m.start()))
    for m in LIT_GVAR_RE.finditer(text):
        if m.group(2).lower().startswith("fnc_"):
            continue
        result.append((m.group(1).lower(), m.group(2).lower(), False, m.start()))
    return result


defined = {}  # (addon, name) -> preInit path
for path in sorted(ADDONS.glob("*/XEH_preInit.sqf")):
    own = addon_of(path)
    for addon, name, is_set, pos in gvar_mentions(code[path], own):
        if is_set and addon == own.lower():
            defined.setdefault((addon, name), path)

mentions = {key: [] for key in defined}  # key -> [(path, is_assignment)]
for path, text in code.items():
    own = addon_of(path) if ADDONS in path.parents else ""
    for addon, name, is_set, pos in gvar_mentions(text, own):
        if (addon, name) in mentions:
            mentions[(addon, name)].append((path, is_set))

print()
print("=== 2. Variables defined in an XEH_preInit.sqf ===")
print("%d defined" % len(defined))
unread, write_only = [], []
for key in sorted(defined):
    # The defining statement is one mention of its own; a second one in the same file may still be a read.
    others = [m for m in mentions[key]]
    reads = [m for m in others if not m[1]]
    if len(others) <= 1:
        unread.append(key)
    elif not reads:
        write_only.append(key)
print("Mentioned only where it is defined (%d):" % len(unread))
for key in unread:
    print("  einv_%s_%s    %s" % (key[0], key[1], rel(defined[key])))
print("Only ever assigned, never read (%d):" % len(write_only))
for key in write_only:
    where = sorted({rel(p) for p, _ in mentions[key]})
    print("  einv_%s_%s    %s" % (key[0], key[1], ", ".join(where)))

# ---------------------------------------------------------------------------
# 3. Defines
# ---------------------------------------------------------------------------

DEFINE_RE = re.compile(r"^[ \t]*#define[ \t]+([A-Za-z_][A-Za-z0-9_]*)", re.M)
defines = []  # (name, path)
for path, text in code.items():
    if ADDONS in path.parents:
        for m in DEFINE_RE.finditer(text):
            defines.append((m.group(1), path))

all_text = {path: text for path, text in code.items()}
unused = []
alive = list(defines)
while True:
    gone = []
    for name, path in alive:
        if name in EXTERNAL_DEFINES:
            continue
        pattern = re.compile(r"(?<![A-Za-z0-9_])%s(?![A-Za-z0-9_])" % re.escape(name))
        count = 0
        for p, text in all_text.items():
            count += len(pattern.findall(text))
        # The definition itself, and an #undef of it, are mentions that are no use.
        total_defs = sum(1 for n, pth in defines if n == name)
        undefs = sum(len(re.findall(r"^[ \t]*#undef[ \t]+%s\b" % re.escape(name), t, re.M)) for t in all_text.values())
        if count - total_defs - undefs <= 0:
            gone.append((name, path))
    if not gone:
        break
    unused.extend(gone)
    gone_set = set(gone)
    alive = [d for d in alive if d not in gone_set]
    for name, path in gone:
        pattern = re.compile(r"^[ \t]*#define[ \t]+%s\b.*(?:\\\n.*)*" % re.escape(name), re.M)
        all_text[path] = pattern.sub("", all_text[path])
    defines = [d for d in defines if d not in gone_set]

print()
print("=== 3. Defines ===")
print("%d defines, %d unused:" % (len(alive) + len(unused), len(unused)))
for name, path in sorted(unused, key=lambda d: (rel(d[1]), d[0])):
    print("  %s    %s" % (name, rel(path)))
