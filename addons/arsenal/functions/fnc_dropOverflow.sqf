#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes out of a unit's uniform, vest and backpack everything that lies on no cell (fnc_findOverflow): entry
 * after entry through the storage (aio_storage_fnc_removeEntry), the layout read again after each, as taking
 * a weapon out puts its siblings back as new objects. What leaves is the same as what "Remove" in the panel's
 * menu takes out (fnc_remove), and ACE hears of it the same way (fnc_tellAce) while its window is still open,
 * which keeps its counts, load bar and greyed rows right.
 *
 * Only for a unit that is local here, as ACE's own buttons work. A container that will not give up an entry
 * is left as it is and the rest goes on; at most as many turns as there were entries, and two more.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * What was taken out, class -> count <HASHMAP>
 *
 * Example:
 * [player] call aio_arsenal_fnc_dropOverflow;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

private _gone = createHashMap;

if (isNull _unit || {!local _unit}) exitWith {_gone};

{
    private _container = _x get "container";
    private _entries = ([_container, [_container] call EFUNC(storage,getContents)] call EFUNC(storage,getLayout)) getOrDefault ["overflow", []];

    for "_i" from 1 to (count _entries + 2) do {
        private _layout = [_container, [_container] call EFUNC(storage,getContents)] call EFUNC(storage,getLayout);
        private _left = _layout getOrDefault ["overflow", []];

        if (_left isEqualTo []) exitWith {};

        private _entry = _left select 0;
        private _class = _entry getOrDefault ["class", ""];
        private _before = [_container, _class] call EFUNC(storage,countClass);

        if (([_container, _entry, -1] call EFUNC(storage,removeEntry)) isEqualTo []) exitWith {};

        private _after = [_container, _class] call EFUNC(storage,countClass);

        _gone set [_class, (_gone getOrDefault [_class, 0]) + ((_before - _after) max 1)];

        [_class, _before, _after] call FUNC(tellAce);
    };
} forEach ([_unit] call EFUNC(storage,getSections));

// Kits taken away for good: their instances back to that mod's pool (aio_compat_efak_fnc_arsenalFree).
if (count _gone > 0 && {!isNil QEFUNC(compat_efak,arsenalFree)}) then {
    [keys _gone, [uniformContainer _unit, vestContainer _unit, backpackContainer _unit, GVAR(staging)]] call EFUNC(compat_efak,arsenalFree);
};

// One sound for all of it, the one of giving back.
if (count _gone > 0) then {
    ["giveBack", (keys _gone) select 0, objNull, false] call EFUNC(gui,playSound);
};

_gone
