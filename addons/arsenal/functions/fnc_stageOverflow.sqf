#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Moves what lies in the soldier's uniform, vest or backpack with no cell - after another container was
 * picked in ACE's list, or when the window opens on gear that does not fit - into the staging space
 * (fnc_staging), so that nothing is lost and the player sees it and puts it where he wants. Whatever the
 * staging space has no room for stays what it was, a red tile (fnc_findOverflow asks about it on closing).
 * The staging space is made here when there is none, also while the panel is folded. ACE is told of what left
 * the open container (fnc_tellAce).
 *
 * Arguments:
 * 0: The soldier, ACE Arsenal's center <OBJECT>
 *
 * Return Value:
 * How many items were moved <NUMBER>
 *
 * Example:
 * [player] call einv_arsenal_fnc_stageOverflow;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit || {!local _unit} || {is3DEN}) exitWith {0};

// Looked at first: the staging space is made only when something has to go there.
private _sections = [_unit] call EFUNC(storage,getSections);
private _any = _sections findIf {
    private _container = _x get "container";

    (([_container, [_container] call EFUNC(storage,getContents), false] call EFUNC(storage,getLayout)) getOrDefault ["overflow", []]) isNotEqualTo []
};

if (_any < 0) exitWith {0};

private _staging = [] call FUNC(staging);

if (isNull _staging) exitWith {0};

(call FUNC(selected)) params ["", "_open"];

private _moved = 0;

{
    private _container = _x get "container";
    private _entries = ([_container, [_container] call EFUNC(storage,getContents)] call EFUNC(storage,getLayout)) getOrDefault ["overflow", []];

    for "_i" from 1 to (count _entries + 2) do {
        private _left = ([_container, [_container] call EFUNC(storage,getContents)] call EFUNC(storage,getLayout)) getOrDefault ["overflow", []];

        if (_left isEqualTo []) exitWith {};

        private _entry = _left select 0;
        private _class = _entry getOrDefault ["class", ""];
        private _before = [_container, _class] call EFUNC(storage,countClass);

        // Rows for it first: the staging space only grows when it is drawn.
        [_staging, 0] call FUNC(growStaging);

        if (([_container, _staging, _entry, -1, [], _unit] call EFUNC(storage,moveEntry)) isNotEqualTo "") exitWith {};

        private _after = [_container, _class] call EFUNC(storage,countClass);

        if (_after >= _before) exitWith {};

        _moved = _moved + (_before - _after);

        if (_container isEqualTo _open) then {
            [_class, _before, _after] call FUNC(tellAce);
        };
    };
} forEach _sections;

if (_moved > 0) then {
    ["move", "", objNull, false] call EFUNC(gui,playSound);
    [format [LLSTRING(Hint_Staged), _moved], "accent"] call EFUNC(gui,showHint);
};

_moved
