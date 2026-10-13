#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A click on the panel that did not become a drag (the "click" hook). The inventory would equip on a
 * double click or Alt, and move a tile into another container with Ctrl - all of it past ACE, whose list
 * and counts would not follow. Here such clicks do nothing: ACE's own slots and lists put things on, and
 * the panel only arranges and takes out.
 *
 * Arguments:
 * 0: Kind, "single" or "double" <STRING>
 * 1: What was clicked (see einv_gui_fnc_onMouseButton) <HASHMAP>
 * 2: Shift <BOOL>
 * 3: Ctrl <BOOL>
 * 4: Alt <BOOL>
 *
 * Return Value:
 * Handled - the engine does nothing more with it <BOOL>
 *
 * Example:
 * ["double", _target, false, false, false] call einv_arsenal_fnc_onClick;
 *
 * Public: No
 */

params [["_kind", "single", [""]], "", ["_shift", false, [false]], ["_ctrl", false, [false]], ["_alt", false, [false]]];

_kind isEqualTo "double" || {_ctrl} || {_alt}
