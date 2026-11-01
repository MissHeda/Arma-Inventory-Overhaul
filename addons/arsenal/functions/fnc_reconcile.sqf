#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Follows up an add of ACE to the open uniform, vest or backpack: what the container holds now against
 * what it held at the last look (GVAR(snapshot)). The storage lays the new things out first-fit, as any
 * change from outside (aio_storage_fnc_getLayout); what finds no free cells is "overflow" - of that,
 * exactly as many as were just added of its class are taken back out (aio_storage_fnc_removeEntry, a
 * magazine by its rounds), ACE's list is put right (fnc_syncAce), the message says what room to make
 * (fnc_sayNoRoom), and ACE is told (fnc_tellAce). Nothing else is ever taken out: what lay there before keeps its place, as its records
 * were written down at the last look (fnc_snapshot).
 *
 * A container that is not the one looked at last - just swapped - is only looked at now. Then what it holds
 * is noted for the next add.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 *
 * Return Value:
 * Something was taken back out <BOOL>
 *
 * Example:
 * [_display] call aio_arsenal_fnc_reconcile;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

(call FUNC(selected)) params ["_id", "_container"];
GVAR(snapshot) params ["_known", "_before"];

private _center = (call FUNC(center));
private _undone = createHashMap;
private _refused = "";

if (!isNull _container && {_known isEqualTo _container} && {local _center}) then {
    private _now = [_container] call FUNC(countAll);
    private _gained = createHashMap;

    {
        private _more = _y - (_before getOrDefault [_x, 0]);

        if (_more > 0) then {
            _gained set [_x, _more];
        };
    } forEach _now;

    if (count _gained == 0) exitWith {};

    private _layout = [_container, [_container] call EFUNC(storage,getContents)] call EFUNC(storage,getLayout);

    {
        private _class = _x getOrDefault ["class", ""];
        private _key = toLowerANSI _class;
        private _left = _gained getOrDefault [_key, 0];

        if (_left <= 0) then {continue};

        private _stack = _x getOrDefault ["count", 1];
        private _take = _stack min _left;
        private _payload = [_container, _x, [_take, -1] select (_take >= _stack)] call EFUNC(storage,removeEntry);

        if (_payload isEqualTo []) then {continue};

        // What really left: a magazine is one, items as many as the payload says.
        private _out = switch (_payload select 0) do {
            case "magazine": {count (_payload param [2, [], [[]]])};
            case "item": {_payload param [2, 1, [0]]};
            default {1};
        };

        _gained set [_key, _left - _out];

        if !(_class in _undone) then {
            _undone set [_class, (_now getOrDefault [_key, 0])];
        };

        if (_refused isEqualTo "") then {
            _refused = _class;
        };
    } forEach (_layout getOrDefault ["overflow", []]);
};

[] call FUNC(snapshot);

if (_refused isEqualTo "") exitWith {false};

// ACE wrote its counts before it raised the event: put right at once, not only a frame later.
[_display] call FUNC(syncAce);
[_display, _id, _refused] call FUNC(sayNoRoom);

// Noted already, so the follow-up of ACE's event finds nothing more to take out.
{
    [_x, _y, [_container, _x] call EFUNC(storage,countClass)] call FUNC(tellAce);
} forEach _undone;

true
