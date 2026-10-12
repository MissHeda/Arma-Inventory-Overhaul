#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the window's right-click menu on a tile offers about the hotbar: "Take off the hotbar (6)" when
 * its class is on a slot, else "Put on the hotbar (5)" - on the first free slot - when the item may go
 * there from where it lies and a slot is free. Nothing otherwise; the hint after a refused key press or
 * drag says why.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: Where the tile lies, as fnc_canBindFrom takes it <ARRAY>
 *
 * Return Value:
 * Choices as the context menu takes them, [text, arguments, code] <ARRAY>
 *
 * Example:
 * ["ACE_elasticBandage", ["grid", _grid]] call einv_hotbar_fnc_menuChoices;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_from", [], [[]]]];

if (_class isEqualTo "" || {!(call FUNC(isActive))}) exitWith {[]};

// A slot's key, or its number while the key is not set.
private _fnc_key = {
    params ["_index"];

    private _key = [_index] call FUNC(keyName);

    [_key, str (_index + 1)] select (_key isEqualTo "")
};

private _bound = GVAR(slots) findIf {_x == _class};

if (_bound >= 0) exitWith {
    [[format [LLSTRING(Menu_Unbind), [_bound] call _fnc_key], [_bound], {_this call FUNC(unbind)}]]
};

private _free = call FUNC(firstFree);

if (_free < 0 || {!(([_class, _from] call FUNC(canBindFrom)) select 0)}) exitWith {[]};

[[format [LLSTRING(Menu_Bind), [_free] call _fnc_key], [_free, _class, _from], {_this call FUNC(bind)}]]
