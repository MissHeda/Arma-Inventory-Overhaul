#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Which family of CfgAioSounds a container sounds like when it is opened, closed or searched:
 *   body     - a body or a living person, and the uniform, vest or backpack a man wears
 *   ground   - a pile on the ground
 *   vehicle  - any vehicle: its own doors
 *   uniform, vest, backpack - one lying in a container and opened there: the family of its item
 *   crate    - everything else, supply boxes and the like
 * Nothing at all is "Default".
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * A class of CfgAioSounds <STRING>
 *
 * Example:
 * [cursorObject] call aio_gui_fnc_containerFamily;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]]];

if (isNull _container) exitWith {"Default"};

if (_container isKindOf "CAManBase") exitWith {"body"};

// A uniform, vest or backpack a man wears (the unit is its owner - fnc_getOwner), and the pile at his feet.
private _owner = ([_container] call EFUNC(storage,getOwner)) select 0;

if (!isNull _owner && {_owner isKindOf "CAManBase"}) exitWith {"body"};

if ([_container] call EFUNC(storage,isGroundHolder)) exitWith {"ground"};

if (_container isKindOf "AllVehicles") exitWith {"vehicle"};

// One lying in a container is tagged with its item class when it is opened (fnc_openNested); a backpack
// lying on its own is an object of its class.
private _itemClass = _container getVariable [QEGVAR(storage,itemClass), ""];

if (_itemClass isNotEqualTo "") exitWith {
    [_itemClass] call FUNC(soundFamily)
};

if (_container isKindOf "Bag_Base") exitWith {
    [typeOf _container] call FUNC(soundFamily)
};

"crate"
