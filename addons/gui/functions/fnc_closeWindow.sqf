#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Closes a kit's window - its cross, Escape on the topmost one (fnc_onKeyDown), a double click on the
 * kit's tile or Close in its context menu (einv_compat_efak_fnc_toggle). The kit is closed in
 * einv_compat_efak (fnc_close there, which plays the sound of the medic bag closing); where its window stood is forgotten, so opened again it comes up
 * beside its tile. Only the windows are drawn again (fnc_drawWindows) - kits open inside it, found only
 * through it, close with it - and nothing in the columns moves.
 *
 * Arguments:
 * 0: The kit's key, "kit:" + its lowercase class <STRING>
 *
 * Return Value:
 * Its window was open <BOOL>
 *
 * Example:
 * ["kit:efak_ifak_7"] call einv_gui_fnc_closeWindow;
 *
 * Public: No
 */

disableSerialization;

params [["_key", "", [""]]];

if (_key isEqualTo "") exitWith {false};

private _index = GVAR(windowOrder) find _key;

if (!isNil QEFUNC(compat_efak,close)) then {
    [_key] call EFUNC(compat_efak,close);
};

if (_index >= 0) then {
    GVAR(windowOrder) deleteAt _index;
};

GVAR(windowPos) deleteAt _key;
GVAR(windowAnchor) deleteAt _key;
GVAR(windowScroll) deleteAt _key;
GVAR(windowFresh) = GVAR(windowFresh) - [_key];

if ((GVAR(windowMove) param [0, ""]) isEqualTo _key) then {
    GVAR(windowMove) = [];
};

// The windows are drawn once for a run of clicks (fnc_windowsSoon).
[] call FUNC(windowsSoon);

_index >= 0
