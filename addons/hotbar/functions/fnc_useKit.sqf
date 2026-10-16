#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Opens a kit of Enhanced First Aid Kits or a pouch of Enhanced Utility Pouches. The slot stands for the
 * kit it was bound with, or - when that one is gone - any kit of the same type that is carried.
 *
 * With Enhanced Inventory's kit support loaded, the window opens on the unit's own gear with the kit
 * opened as a window inside it, where its contents can be taken out and put in by drag and drop.
 * Otherwise - the support is not loaded, or the window could not open - Enhanced First Aid Kits' own
 * window opens.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Class <STRING>
 * 2: Slot index - not used <NUMBER>
 *
 * Return Value:
 * [done, text] - "" for done, else why not <ARRAY>
 *
 * Example:
 * [player, "efak_IFAK_7", 4] call einv_hotbar_fnc_useKit;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_class", "", [""]]];

if (isNil "efak_core_fnc_getCarriedKits" || {isNil "efak_core_fnc_openKit"}) exitWith {[false, LLSTRING(Reason_NoUse)]};

([_class] call FUNC(useOf)) params ["", "_prototype"];

// The kit the slot was bound with, else the first carried one of its type - not one that lies in a container
// the settings "Use items from ..." close to it.
private _carried = ([_unit, [[_unit] call efak_core_fnc_getCarriedKits]] call EFUNC(storage,useCarried)) select 0;
private _kit = "";
private _found = _carried findIf {_x == _class};

if (_found >= 0) then {
    _kit = _carried select _found;
} else {
    _found = _carried findIf {([_x] call efak_core_fnc_getPrototype) == _prototype};

    if (_found >= 0) then {
        _kit = _carried select _found;
    };
};

if (_kit isEqualTo "") exitWith {[false, LLSTRING(Reason_NoneLeft)]};

if (!([_unit, ["isNotInside", "isNotSitting", "isNotSwimming"]] call FUNC(canAct))) exitWith {[false, LLSTRING(Reason_NotNow)]};

if (!isNil QEFUNC(compat_efak,open)) then {
    // The container the kit lies in: the first of the three whose items hold it.
    private _container = objNull;

    {
        if ((((getItemCargo _x) select 0) findIf {_x == _kit}) >= 0) exitWith {
            _container = _x;
        };
    } forEach [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];

    // The window first, then the kit in it: opening the window forgets the kits of the last one.
    if ([_unit] call EFUNC(gui,open)) exitWith {
        [_kit, _container, ""] call EFUNC(compat_efak,open);
    };

    // The window did not open: the kit's own.
    [_unit, _kit] call efak_core_fnc_openKit;
} else {
    [_unit, _kit] call efak_core_fnc_openKit;
};

[true, ""]
