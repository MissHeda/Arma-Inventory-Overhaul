#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Makes the highlight of one more of the player's own equipment slots ahead of time (fnc_glowSlot), kept
 * hidden, so that lifting an item makes no controls when it lights the slots that take it
 * (fnc_showTargets). Called by fnc_onFrame on a frame with nothing held and no menu open: one slot per
 * call, in the order the slots were drawn, some fifteen controls each; uiNamespace glowNext remembers how far it
 * got (a build starts over) and a part drawn again (fnc_redrawPart) adds slots at the end, which come in
 * their turn. Slots of other units (a body's, lit up for a worn item dragged off the player's own) are not
 * made ahead; they are made when that drag asks for them.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call aio_gui_fnc_warmTargets;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

private _slots = uiNamespace getVariable [QGVAR(slots), []];
private _count = count _slots;
private _index = uiNamespace getVariable [QGVAR(glowNext), 0];

if (_index >= _count) exitWith {};

// The next slot of the player's own that a tile can be dropped on (as fnc_showTargets finds them).
while {_index < _count} do {
    (_slots select _index) params [["_rect", []], "", "", "", "", ["_slot", ""], ["_owner", objNull], ["_hotbar", -1]];

    if (_slot isNotEqualTo "" && {_rect isNotEqualTo []} && {_hotbar < 0} && {_owner isEqualTo GVAR(unit)}) exitWith {};

    _index = _index + 1;
};

if (_index < _count) then {
    {_x ctrlShow false} forEach ([_display, _index] call FUNC(glowSlot));
};

uiNamespace setVariable [QGVAR(glowNext), _index + 1];
