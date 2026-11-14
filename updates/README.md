# Update check

The game asks this folder whether a newer Arma Inventory Overhaul is on the Workshop (`aio_gui_fnc_updateCheck`). A
script can only tell whether an address loads, so the answer is a file being there or not:

- `outdated/<version>.html` exists: that version was replaced by a newer Workshop release. A build with that version
  shows its player the red "Update available" warning once per game.
- No such file: nothing newer is known.

After a Workshop update, mark the version(s) that were live before it and push:

```
python tools/mark_outdated.py 0.7.22
```

Never mark the version that is live on the Workshop now. `outdated/0.0.0.html` is only there to test the check.
