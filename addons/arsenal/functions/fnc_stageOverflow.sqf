#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Moves what lies in the soldier's uniform, vest or backpack with no cell - after another container was
 * picked in ACE's list, or when the window opens on gear that does not fit - first into another worn
 * container that has a free spot for it (a loadout never sees our cells, so a thing that did not fit one
 * container may well fit the next), and only what fits none into the staging space (fnc_staging), so that
 * nothing is lost and the player sees it and puts it where he wants. Whatever the staging space has no room
 * for stays what it was, a red tile (fnc_findOverflow asks about it on closing). Nothing is moved while a
 * loadout is being set (GVAR(loadoutFrame)): its things are still being added and placed; the pass is asked
 * for again.
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
 * [player] call aio_arsenal_fnc_stageOverflow;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit || {!local _unit} || {is3DEN}) exitWith {0};

// A loadout was just set: its containers are still being filled (fnc_topUpLoadout) and placed, so nothing
// is judged yet.
if (diag_frameNo <= GVAR(loadoutFrame)) exitWith {
    [] call FUNC(settle);

    0
};

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
private _stagedCount = 0;

{
    private _container = _x get "container";
    private _entries = ([_container, [_container] call EFUNC(storage,getContents)] call EFUNC(storage,getLayout)) getOrDefault ["overflow", []];

    for "_i" from 1 to (count _entries + 2) do {
        private _left = ([_container, [_container] call EFUNC(storage,getContents)] call EFUNC(storage,getLayout)) getOrDefault ["overflow", []];

        if (_left isEqualTo []) exitWith {};

        private _entry = _left select 0;
        private _class = _entry getOrDefault ["class", ""];
        private _before = [_container, _class] call EFUNC(storage,countClass);
        private _done = false;

        // The other worn containers first, in order, then the staging space.
        {
            private _target = _x;

            if (isNull _target || {_target isEqualTo _container}) then {continue};

            if (_target isEqualTo _staging) then {
                // Rows for it first: the staging space only grows when it is drawn.
                [_staging, 0] call FUNC(growStaging);
            };

            private _targetBefore = [_target, _class] call EFUNC(storage,countClass);

            if (([_container, _target, _entry, -1, [], _unit] call EFUNC(storage,moveEntry)) isNotEqualTo "") then {continue};

            private _after = [_container, _class] call EFUNC(storage,countClass);

            if (_after >= _before) then {continue};

            _moved = _moved + (_before - _after);
            _done = true;

            if (_target isEqualTo _staging) then {
                _stagedCount = _stagedCount + (_before - _after);
            };

            if (_container isEqualTo _open) then {
                [_class, _before, _after] call FUNC(tellAce);
            };

            if (_target isEqualTo _open) then {
                [_class, _targetBefore, [_target, _class] call EFUNC(storage,countClass)] call FUNC(tellAce);
            };

            break;
        } forEach ((_sections apply {_x get "container"}) + [_staging]);

        if (!_done) exitWith {};
    };
} forEach _sections;

if (_moved > 0) then {
    ["move", "", objNull, false] call EFUNC(gui,playSound);
};

if (_stagedCount > 0) then {
    [format [LLSTRING(Hint_Staged), _stagedCount], "accent"] call EFUNC(gui,showHint);
};

_moved
