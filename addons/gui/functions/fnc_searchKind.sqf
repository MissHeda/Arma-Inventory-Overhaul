#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What kind of box a container is searched as, for its time per cell (fnc_searchTime, the settings aio_gui_searchTime
 * and aio_gui_searchTimeUniform to searchTimeBody):
 *   uniform, vest, backpack - one a man wears (by its slot), one lying on the ground, in a crate or opened from inside
 *     another container (a backpack is Bag_Base, a uniform's or vest's container a Supply class, told apart by the item
 *     class it lies as), and a backpack set down as an object of its own
 *   ground   - a pile on the ground
 *   vehicle  - a vehicle's cargo, also the one the player sits in
 *   crate    - everything else
 * And whether it is a body's: what a dead man wears, and a uniform, vest or backpack that came off a body unsearched and
 * carries that with it (aio_storage_searchState, source "body") - the body's factor counts on top of the container's.
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * [kind, a body's] <ARRAY>
 *
 * Example:
 * [backpackContainer cursorObject] call aio_gui_fnc_searchKind;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]]];

if (isNull _container) exitWith {["crate", false]};

([_container] call EFUNC(storage,getOwner)) params ["_owner", "_slot"];

if (!isNull _owner && {_owner isKindOf "CAManBase"} && {_slot isNotEqualTo ""}) exitWith {[_slot, !alive _owner]};

private _body = ((_container getVariable [QEGVAR(storage,searchState), []]) param [1, "", [""]]) isEqualTo "body";

switch (true) do {
    case ([_container] call EFUNC(storage,isGroundHolder)): {["ground", false]};
    case (_container isKindOf "Bag_Base"): {["backpack", _body]};
    case (_container isKindOf "ContainerSupply"): {
        // Which of the two only the item class it lies as says: tagged when it was opened (fnc_openNested), else the id
        // its parent gave it (aio_storage_tag). One that says nothing is taken for a vest.
        private _class = _container getVariable [QEGVAR(storage,itemClass), ""];

        if (_class isEqualTo "") then {
            _class = (_container getVariable [QEGVAR(storage,tag), []]) param [1, "", [""]];
        };

        [["vest", "uniform"] select (getNumber (configFile >> "CfgWeapons" >> _class >> "ItemInfo" >> "type") == 801), _body]
    };
    case (_container isKindOf "AllVehicles"): {["vehicle", false]};
    default {["crate", false]};
}
