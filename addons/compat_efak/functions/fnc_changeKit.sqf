#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes a kit with so many of an item more or fewer, read in the same frame it is written: the kit is
 * Enhanced First Aid Kits' global table, and every write sends the whole of it - whoever writes last
 * wins, so nothing is kept from an earlier look. Through that mod's one writer,
 * efak_core_fnc_setContents, which tells every machine. Called only by the kit ops, on the machine where
 * the kit's root is local (fnc_takeFromKit, fnc_putIntoKit, fnc_removeIfEmpty): every write of one kit
 * through the window happens there, one after the other - two machines reading the same contents and
 * each writing its own change would lose one.
 *
 * Opened magazines keep their rounds in the kit: those that went in are noted, those that came out
 * struck off - full ones are never listed. The same as that mod's own adjustCharges, done here: that
 * one is not public.
 *
 * An empty magazine is turned away: the kit cannot note a magazine of no rounds, and one it does not
 * note comes back out full. The window checks that before anything is sent (fnc_canDrop); this is the
 * last word, for what changed in between. What came out of a kit (fnc_takeRounds) never has fewer than
 * one round.
 *
 * Arguments:
 * 0: Kit class <STRING>
 * 1: Item class <STRING>
 * 2: How many more - fewer when below 0 <NUMBER>
 * 3: The rounds of each magazine that went in or came out <ARRAY> (default: [])
 *
 * Return Value:
 * Written - false when the kit holds fewer than are to come out, or an empty magazine was to go in
 * <BOOL>
 *
 * Example:
 * ["efak_IFAK_7", "ACE_painkillers", -1, [7]] call einv_compat_efak_fnc_changeKit;
 *
 * Public: No
 */

params [["_kit", "", [""]], ["_class", "", [""]], ["_delta", 0, [0]], ["_rounds", [], [[]]]];

if (_kit isEqualTo "" || {_class isEqualTo ""} || {_delta == 0}) exitWith {false};

private _contents = [_kit] call EFAKFUNC(core,getContents);
private _charges = [_kit] call EFAKFUNC(core,getCharges);
private _size = [_class] call EFAKFUNC(core,getMagazineSize);

if (_delta > 0) exitWith {
    if (_size > 1 && {(_rounds findIf {_x < 1}) >= 0}) exitWith {false};

    // The kit merges it with what it holds of the class already (efak_core_fnc_normalizeContents).
    _contents pushBack [_class, _delta];

    if (_size > 1) then {
        {
            if (_x >= 1 && {_x < _size}) then {
                _charges pushBack [_class, floor _x];
            };
        } forEach _rounds;
    };

    [_kit, _contents, _charges] call EFAKFUNC(core,setContents);
    true
};

private _index = _contents findIf {(_x select 0) == _class};
private _left = if (_index < 0) then {-1} else {((_contents select _index) select 1) + _delta};

if (_left < 0) exitWith {false};

if (_left > 0) then {
    (_contents select _index) set [1, _left];
} else {
    _contents deleteAt _index;
};

if (_size > 1) then {
    {
        private _out = _x;

        if (_out < _size) then {
            private _opened = _charges findIf {(_x select 0) == _class && {(_x select 1) == _out}};

            if (_opened >= 0) then {
                _charges deleteAt _opened;
            };
        };
    } forEach _rounds;
};

[_kit, _contents, _charges] call EFAKFUNC(core,setContents);

true
