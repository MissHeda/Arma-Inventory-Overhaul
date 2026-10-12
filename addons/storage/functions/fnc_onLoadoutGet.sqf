#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A loadout is read (CBA_fnc_getLoadout, event CBA_loadoutGet): where the unit's uniform, vest and backpack
 * keep their things goes along in its extended info, under "einv_layout" - [1, [uniform, vest, backpack]],
 * each a list of [key, col, row, w, h, block] in the records' own shape (fnc_readPlaces). So a loadout
 * saved in the Arsenal or ACE's, exported, kept for a respawn, comes back with everything on its cell;
 * ACE leaves a key it does not know alone.
 *
 * The key is the base one, fnc_layoutKey of the class: an instance of a radio or kit means nothing in
 * another session, and a magazine's rounds or an id given to a backpack are not the loadout's.
 * fnc_onLoadoutSet reads it back the same way, and the second pass of the layout (fnc_getLayout) finds the
 * item by it.
 *
 * Nothing is written when none of the three has records.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: The loadout, as getUnitLoadout gives it <ARRAY>
 * 2: Extended info, filled in here <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, getUnitLoadout player, createHashMap] call einv_storage_fnc_onLoadoutGet;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_loadout", [], [[]]], ["_extended", createHashMap, [createHashMap]]];

if (isNull _unit) exitWith {};

private _any = false;

private _lists = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit] apply {
    if (isNull _x) then {
        []
    } else {
        private _records = (([_x] call FUNC(readPlaces)) select 1) apply {
            _x params ["_key", "_col", "_row", "_w", "_h", "_block"];

            // The class is what the key says before its first "|".
            [[(_key splitString "|") param [0, _key]] call FUNC(layoutKey), _col, _row, _w, _h, _block]
        };

        if (_records isNotEqualTo []) then {
            _any = true;
        };

        _records
    }
};

if (_any) then {
    _extended set ["einv_layout", [1, _lists]];
};
