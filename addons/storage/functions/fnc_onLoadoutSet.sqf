#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A loadout was set (CBA_fnc_setLoadout, event CBA_loadoutSet): when it carries "einv_layout"
 * (fnc_onLoadoutGet), the places it names are written to the unit's uniform, vest and backpack, so
 * everything lies on the cell it was saved on. A record matches a plain item by its key at once, and an
 * instance of a radio or kit, a magazine with other rounds, a backpack with an id of its own, in the second
 * pass of the layout (fnc_getLayout): by what kind of item it is (fnc_layoutKey). Records whose items did
 * not come with the loadout - verification blanked them - match nothing and drop out at the next layout.
 *
 * The event runs where the loadout was set, which is not necessarily where the unit is local. Local: the
 * places are written here (fnc_writePlaces). Otherwise they go to the unit's machine in an event
 * (einv_storage_loadoutPlaces, fnc_onLoadoutPlaces), which writes them a frame later, when the loadout's
 * containers have arrived there.
 *
 * What came over the network or from a profile is not trusted: only well-formed records are kept. A
 * loadout without the key, or of another version, changes nothing - its things lie where the layout puts
 * them first. Any loadout, with the key or without, also notes its unit for the surplus check
 * (fnc_queueMigrate): what it holds beyond the grid moves on to the next container with room.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: The loadout, as getUnitLoadout gives it <ARRAY>
 * 2: Extended info <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, getUnitLoadout player, _extended] call einv_storage_fnc_onLoadoutSet;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_loadout", [], [[]]], ["_extended", createHashMap, [createHashMap]]];

if (isNull _unit) exitWith {};

// Whatever the loadout brought beyond the grid - a loadout ignores our cells, with or without places in it -
// moves on to the unit's next container with room (fnc_opMigrate), a moment after the places below are in.
// The unit's own machine looks: told by an event when the loadout was set somewhere else.
if (!is3DEN) then {
    if (local _unit) then {
        // A loadout is the unit's whole gear: the old containers' contents are gone with them, and so is
        // what Strict mode's hidden holder kept out of them (fnc_opStrict). A loadout saved in an arsenal
        // holds everything - the holder gives everything back while one is open -, and what the new
        // loadout brought that may not lie in a Strict container is hidden again a moment later.
        if (!isNil {_unit getVariable QGVAR(hidden)}) then {
            _unit setVariable [QGVAR(hidden), nil, true];
        };

        [_unit] call FUNC(queueMigrate);
    } else {
        [QGVAR(migrateUnit), [_unit], _unit] call CBA_fnc_targetEvent;
    };
};

private _layout = _extended getOrDefault ["einv_layout", []];

if !(_layout isEqualType [] && {(_layout param [0, 0]) isEqualTo 1} && {(_layout param [1, []]) isEqualType []}) exitWith {};

// Three lists, [uniform, vest, backpack], each of well-formed records only.
private _lists = [0, 1, 2] apply {
    ((_layout select 1) param [_x, [], [[]]]) select {
        _x isEqualType []
        && {count _x >= 6}
        && {(_x select 0) isEqualType ""}
        && {(_x select [1, 5]) isEqualTypeAll 0}
    } apply {
        // Which way round (rot, 0 or 1) when the record says it; a loadout saved before has none.
        (_x select [0, 6]) + ((_x select [6, 1]) select {_x isEqualTo 0 || {_x isEqualTo 1}})
    }
};

if (_lists findIf {_x isNotEqualTo []} < 0) exitWith {};

if (!local _unit) exitWith {
    [QGVAR(loadoutPlaces), [_unit, _lists], _unit] call CBA_fnc_targetEvent;
};

{
    private _container = _x;
    private _records = _lists select _forEachIndex;

    if (!isNull _container && {_records isNotEqualTo []}) then {
        [_container, _records] call FUNC(writePlaces);
    };
} forEach [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];
