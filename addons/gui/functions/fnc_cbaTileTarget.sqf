#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What CBA's item context menu is told about a tile's grid - its slot name and container - the way its
 * hooks into the vanilla inventory tell it for the list the item lies in (cba_ui_fnc_getInventoryItemData):
 *   the unit's own uniform, vest or backpack - "UNIFORM_CONTAINER", "VEST_CONTAINER" or
 *                                              "BACKPACK_CONTAINER", with that container
 *   a pile on the ground                     - "GROUND", with the pile
 *   anything else                            - "CARGO", with the body a uniform, vest or backpack
 *                                              belongs to, else the crate, vehicle or container
 * A body's worn gear, a grid with no container and the contents of a kit have nothing to tell.
 *
 * Arguments:
 * 0: Grid <HASHMAP>
 *
 * Return Value:
 * [CBA slot, container], ["", objNull] for none <ARRAY>
 *
 * Example:
 * [_grid] call aio_gui_fnc_cbaTileTarget;
 *
 * Public: No
 */

params [["_grid", createHashMap, [createHashMap]]];

private _container = _grid getOrDefault ["container", objNull];

if (isNull _container || {_grid getOrDefault ["virtual", true]} || {(_grid getOrDefault ["kit", ""]) isNotEqualTo ""}) exitWith {["", objNull]};

private _unit = GVAR(unit);

switch (true) do {
    case (_container isEqualTo uniformContainer _unit): {["UNIFORM_CONTAINER", _container]};
    case (_container isEqualTo vestContainer _unit): {["VEST_CONTAINER", _container]};
    case (_container isEqualTo backpackContainer _unit): {["BACKPACK_CONTAINER", _container]};
    case ([_container] call EFUNC(storage,isGroundHolder)): {["GROUND", _container]};
    default {
        private _owner = ([_container] call EFUNC(storage,getOwner)) select 0;

        ["CARGO", [_container, _owner] select (!isNull _owner)]
    };
}
