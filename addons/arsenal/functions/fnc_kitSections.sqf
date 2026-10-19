#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The kits of the type in focus in ACE's left list (fnc_focusedKit) that lie in the panel's containers, each as a
 * section with its grid (einv_compat_efak_fnc_arsenalSections): filled there as a container is. Other kits get
 * no section. Open by default; a fold by hand is kept in GVAR(folded) while ACE's window is open, under
 * "kitfocus_" + the lowercase class (the "fold" hook finds it in GVAR(foldKeys)).
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

private _focus = GVAR(focusKit);

if (_focus isEqualTo "") exitWith {[]};

(([_holders] call EFUNC(compat_efak,arsenalSections)) select {
    ((([(_x get "kit")] call EFUNC(items,kitOf)) param [0, ""]) isEqualTo _focus)
}) apply {
    private _section = _x;
    private _key = "kitfocus_" + toLowerANSI (_section get "kit");

    _section set ["foldKey", _key];
    _section set ["folded", _key in GVAR(folded)];
    _section set ["box", false];
    _section set ["side", "own"];

    GVAR(foldKeys) pushBack [_key, _key];

    _section
}
