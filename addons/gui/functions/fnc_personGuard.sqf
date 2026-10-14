#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The rule for a living person's gear, checked on the machine that runs each op (einv_storage_guards):
 * on a root that is a living person the server's settings (fnc_canTouchPerson) - "worn" for takeOff and
 * putOn, "items" for every other op, with the person's top container the op's holder lies in - and the
 * requester still near (fnc_personInReach, lenient). Any other root: no objection. Settlement skips
 * guards: the system puts things back.
 *
 * A person changing their own gear, a viewer's report that places and cargo disagree (op
 * "normalize", which persists what everyone already sees) and the move of a surplus the grid has no room
 * for on to the person's next container (op "migrate", einv_storage_fnc_opMigrate: nothing leaves the
 * person's own containers) are never refused. Rearranging and sorting their containers changes what
 * everyone sees of them: that is "items" as well. A uniform, vest or backpack the mission locked
 * (lockInventory) does not come off either.
 *
 * The top container is the uniform, vest or backpack itself or the one it lies in, a few deep - found
 * the way the machine that runs the op sees the cargo, never by the window's list of what it opened. A
 * kit ("kit:..." holder, einv_compat_efak) by its class in that cargo, else by its type's own "verify";
 * found in none of them - a kit packed in a kit -, the person's rule for no container decides.
 *
 * Arguments:
 * 0: Op <STRING>
 * 1: Its args <ARRAY>
 * 2: Requester <OBJECT>
 * 3: Root <OBJECT>
 *
 * Return Value:
 * "" when allowed, else why not - "LookOnly" or "Failed" <STRING>
 *
 * Example:
 * ["take", [backpackContainer _person, _entryArray, 1], player, _person] call einv_gui_fnc_personGuard;
 *
 * Public: No
 */

params [
    ["_op", "", [""]],
    ["_args", [], [[]]],
    ["_requester", objNull, [objNull]],
    ["_root", objNull, [objNull]]
];

if (isNull _root || {!(_root isKindOf "CAManBase")} || {!alive _root} || {_root isEqualTo _requester}) exitWith {""};

if (_op in ["normalize", "migrate"]) exitWith {""};

private _tops = [uniformContainer _root, vestContainer _root, backpackContainer _root] select {!isNull _x};

// The person's top container a holder lies in, objNull for none found.
private _fnc_top = {
    params ["_holder"];

    private _top = objNull;

    if (_holder isEqualType objNull) then {
        if (isNull _holder) exitWith {};

        {
            private _candidate = _x;
            private _level = [_candidate];

            for "_depth" from 0 to 3 do {
                if (_holder in _level) exitWith {_top = _candidate};

                private _next = [];

                {_next append ((everyContainer _x) apply {_x select 1})} forEach _level;

                _level = _next;
            };

            if (!isNull _top) exitWith {};
        } forEach _tops;
    } else {
        private _colon = _holder find ":";

        if (_colon < 1) exitWith {};

        private _class = _holder select [_colon + 1];

        {
            private _candidate = _x;
            private _level = [_candidate];

            for "_depth" from 0 to 3 do {
                if (_level findIf {(itemCargo _x) findIf {_x == _class} >= 0} >= 0) exitWith {_top = _candidate};

                private _next = [];

                {_next append ((everyContainer _x) apply {_x select 1})} forEach _level;

                _level = _next;
            };

            if (!isNull _top) exitWith {};
        } forEach _tops;

        if (!isNull _top) exitWith {};

        private _verify = (EGVAR(storage,holderTypes) getOrDefault [_holder select [0, _colon], createHashMap]) getOrDefault ["verify", {false}];
        private _index = _tops findIf {([_holder, _x] call _verify) isEqualTo true};

        if (_index >= 0) then {
            _top = _tops select _index;
        };
    };

    _top
};

private _why = "";

if (_op in ["takeOff", "putOn"]) then {
    if !([_root, "worn"] call FUNC(canTouchPerson)) exitWith {
        _why = "LookOnly";
    };

    private _inside = ([_root, _args param [1, ""]] call EFUNC(storage,getSlot)) getOrDefault ["container", objNull];

    if (_op isEqualTo "takeOff" && {!isNull _inside} && {lockedInventory _inside}) then {
        _why = "LookOnly";
    };
} else {
    // The holders the op names: both sides of a move within the person, else the first.
    private _holders = [[_args param [0, objNull]], [_args param [0, objNull], _args param [1, objNull]]] select (_op in ["move", "kitMove"]);

    _holders = _holders select {_x isEqualType "" || {_x isEqualType objNull && {!isNull _x} && {!(_x isKindOf "CAManBase")}}};

    if (_holders isEqualTo []) exitWith {
        if !([_root, "items", objNull] call FUNC(canTouchPerson)) then {
            _why = "LookOnly";
        };
    };

    {
        if !([_root, "items", [_x] call _fnc_top] call FUNC(canTouchPerson)) exitWith {
            _why = "LookOnly";
        };
    } forEach _holders;
};

if (_why isNotEqualTo "") exitWith {_why};

// Still near - more leniently than the player's window asks it: positions reach this machine late.
if !([_requester, _root] call FUNC(personInReach)) exitWith {"Failed"};

""
