#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes the places of a loadout that was set on another machine (CBA_fnc_setLoadout carrying
 * aio_layout, event aio_storage_loadoutPlaces) here, where the unit is local, a frame later: the
 * loadout's containers have arrived by then. Records whose items are not there drop out at the next
 * layout.
 *
 * Only the unit's own machine writes them (fnc_writePlaces): should the unit have moved on to another
 * machine meanwhile, its gear starts unsorted. The records came over the network, so only well-formed
 * ones are kept, in canonical order (by key, the order within a key kept).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Records per container, [uniform, vest, backpack], each [[key, col, row, w, h, block, rot], ...] -
 *    rot may be missing (an older loadout) <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, [_uniformRecords, _vestRecords, _backpackRecords]] call aio_storage_fnc_onLoadoutPlaces;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_records", [], [[]]]];

if (isNull _unit) exitWith {};

[{
    params ["_unit", "_records"];

    if (isNull _unit) exitWith {};

    if (!local _unit) exitWith {
        WARNING_1("The places of %1's loadout arrived where it is not local - its gear starts unsorted.",_unit);
    };

    {
        private _container = _x;
        private _list = (_records param [_forEachIndex, [], [[]]]) select {
            _x isEqualType []
            && {count _x >= 6}
            && {(_x select 0) isEqualType ""}
            && {(_x select [1, 5]) isEqualTypeAll 0}
        };

        if (!isNull _container && {_list isNotEqualTo []}) then {
            private _order = [];

            {
                _order pushBack [_x select 0, _forEachIndex];
            } forEach _list;

            _order sort true;

            // Which way round goes along when a record says it (fnc_writePlaces keeps a valid rot).
            [_container, _order apply {(_list select (_x select 1)) select [0, 7]}] call FUNC(writePlaces);
        };
    } forEach [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];
}, [_unit, _records]] call FUNC(nextFrame);
