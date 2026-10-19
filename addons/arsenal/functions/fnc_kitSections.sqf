#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The kits that lie in the panel's containers as sections of the column (fnc_layout), each with the grid
 * the kit has (einv_compat_efak_fnc_arsenalSections): filled there as a container is. Folded to their
 * captions at first and unfolded by a click on the tab - except the kits of the type in focus in ACE's
 * list (fnc_focusedKit), which start open. The state is kept in GVAR(folded) while ACE's window is open,
 * under "kit_" + the lowercase class, or "kitfocus_" + that for a kit in focus (so a kit opened by hand
 * does not turn into a folded one when the picked row changes); the "fold" hook finds it in GVAR(foldKeys).
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 * 1: The containers to look in - the worn ones and the staging space <ARRAY of OBJECTs>
 *
 * Return Value:
 * Sections, ready to be drawn by einv_gui_fnc_drawColumn <ARRAY of HASHMAPs>
 *
 * Example:
 * [_display, [uniformContainer player]] call einv_arsenal_fnc_kitSections;
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]], ["_holders", [], [[]]]];

if (isNil QEFUNC(compat_efak,arsenalSections)) exitWith {[]};

private _focus = [_display] call FUNC(focusedKit);

GVAR(focusKit) = _focus;

([_holders] call EFUNC(compat_efak,arsenalSections)) apply {
    private _section = _x;
    private _kit = _section get "kit";
    private _focused = _focus isNotEqualTo "" && {((([_kit] call EFUNC(items,kitOf)) param [0, ""]) isEqualTo _focus)};
    private _key = (["kit_", "kitfocus_"] select _focused) + toLowerANSI _kit;

    _section set ["foldKey", _key];
    _section set ["folded", (_key in GVAR(folded)) isNotEqualTo !_focused];
    _section set ["box", false];
    _section set ["side", "own"];

    GVAR(foldKeys) pushBack [_key, _key];

    _section
}
