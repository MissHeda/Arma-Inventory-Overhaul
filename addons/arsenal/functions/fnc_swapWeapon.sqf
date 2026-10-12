#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts a weapon on a weapon slot, ACE's rules made safe for the grid: what the new weapon takes of the old
 * one's parts stays on it, a magazine is loaded if the muzzle is empty, spare magazines that fit only the
 * old weapon go back to the arsenal, and an old weapon or part that is not in this arsenal is stored if
 * anything has room - else it is thrown away, after the second click.
 *
 * Planned before anything changes: the parts the new weapon does not take, and whether what the arsenal
 * lacks of them has a place. Then the new weapon, with the parts it keeps, goes on in one step
 * (einv_storage_fnc_putOn); the old one that came off is not stored itself - the weapon that is stored is
 * built from the plan, with the parts the new one did not take on it.
 *
 * ACE raises no event for a weapon swap, and neither does this: the baseline of the parts is reset.
 *
 * Arguments:
 * 0: Slot id - "primary", "handgun" or "launcher" <STRING>
 * 1: Class <STRING>
 *
 * Return Value:
 * Done <BOOL>
 *
 * Example:
 * ["primary", "arifle_MX_F"] call einv_arsenal_fnc_swapWeapon;
 *
 * Public: No
 */

params [["_slot", "", [""]], ["_class", "", [""]]];

private _unit = GVAR(center);

if (isNull _unit || {_class isEqualTo ""} || {!(_slot in ["primary", "handgun", "launcher"])}) exitWith {false};

private _equipment = [_unit] call EFUNC(storage,getEquipment);
private _old = _equipment getOrDefault [_slot, []];
private _oldClass = _old param [0, ""];

if (toLowerANSI _oldClass isEqualTo toLowerANSI _class) exitWith {true};

private _fnc_lower = {
    (_this) apply {toLowerANSI _x}
};

// ----- What the new weapon takes -----
private _items = ([_class] call CBA_fnc_compatibleItems) call _fnc_lower;
private _muzzles = getArray (configFile >> "CfgWeapons" >> _class >> "muzzles");
private _second = (_muzzles select {_x != "this" && {_x != (_muzzles param [0, ""])}}) param [0, ""];
private _magsThis = compatibleMagazines [_class, "this"];
private _magsSecond = [compatibleMagazines [_class, _second], []] select (_second isEqualTo "");

// The old weapon's parts as [place in the weapon array, part]: the ones that stay, and the ones that do not.
private _kept = [_class, "", "", "", [], [], ""];
private _lost = [];

{
    private _part = _old param [_x, ""];

    if (_part isNotEqualTo "") then {
        if ((toLowerANSI _part) in _items) then {
            _kept set [_x, _part];
        } else {
            _lost pushBack [_x, _part];
        };
    };
} forEach [1, 2, 3, 6];

{
    _x params ["_place", "_takes"];

    private _magazine = _old param [_place, []];

    if (_magazine isNotEqualTo []) then {
        if ((toLowerANSI (_magazine select 0)) in (_takes call _fnc_lower)) then {
            _kept set [_place, _magazine];
        } else {
            _lost pushBack [_place, _magazine];
        };
    };
} forEach [[4, _magsThis], [5, _magsSecond]];

// ----- What must be stored: the old weapon if the arsenal lacks it, with the parts the new one did not take -----
private _store = [];
private _oldUnique = _oldClass isNotEqualTo "" && {[_oldClass] call FUNC(isUnique)};

if (_oldUnique) then {
    private _weapon = [_oldClass, "", "", "", [], [], ""];

    {
        _weapon set [_x select 0, _x select 1];
    } forEach _lost;

    _store pushBack ["weapon", _weapon];
} else {
    {
        _x params ["", "_part"];

        if (_part isEqualType "" && {[_part] call FUNC(isUnique)}) then {
            _store pushBack ["item", _part, 1, []];
        };

        if (_part isEqualType [] && {[_part select 0] call FUNC(isUnique)}) then {
            _store pushBack ["magazine", _part select 0, [_part param [1, 0]]];
        };
    } forEach _lost;
};

// Without a place for one of them, the second click throws it away.
private _blocked = _store select {!([_x, true] call FUNC(storeAway))};

if (_blocked isNotEqualTo []) then {
    private _blockedClass = switch (_blocked select 0 select 0) do {
        case "weapon": {(_blocked select 0 select 1) select 0};
        default {_blocked select 0 select 1};
    };

    if !(["swap|" + _slot + "|" + _class, format [LLSTRING(Hint_ConfirmUnique), [_blockedClass] call EFUNC(gui,itemName)]] call FUNC(arm)) then {
        _class = "";
    };

    _store = _store - _blocked;
};

if (_class isEqualTo "") exitWith {false};

// ----- A magazine in an empty muzzle: the first one offered, full (ACE's rule) -----
if ((_kept select 4) isEqualTo []) then {
    private _first = _magsThis findIf {(toLowerANSI _x) in GVAR(availableLc)};

    if (_first >= 0) then {
        private _magazine = _magsThis select _first;

        _kept set [4, [_magazine, getNumber (configFile >> "CfgMagazines" >> _magazine >> "count")]];
    };
};

// ----- On -----
([_unit, _slot, ["weapon", _kept]] call EFUNC(storage,putOn)) params ["_status", "_taken"];

if (_status isNotEqualTo "") exitWith {
    // Whatever came off goes back on: nothing may be lost.
    if (_taken isNotEqualTo []) then {
        if ((([_unit, _slot, _taken] call EFUNC(storage,putOn)) select 0) isNotEqualTo "") then {
            ERROR_2("Could not put %1 on %2 and could not put the old one back.",_class,_slot);
        };
    };

    ["Failed"] call EFUNC(gui,flashHint);

    false
};

private _stored = false;

{
    if ([_x] call FUNC(storeAway)) then {
        _stored = true;
    };
} forEach _store;

// ----- Spare magazines that fit only the old weapon go back -----
private _gaveBack = 0;

if (_oldClass isNotEqualTo "") then {
    private _fitsOld = (compatibleMagazines _oldClass) call _fnc_lower;
    private _fitsNew = (compatibleMagazines _class) call _fnc_lower;
    private _others = [];

    {
        private _other = (_equipment getOrDefault [_x, []]) param [0, ""];

        if (_other isNotEqualTo "" && {_x isNotEqualTo _slot}) then {
            _others append ((compatibleMagazines _other) call _fnc_lower);
        };
    } forEach ["primary", "handgun", "launcher", "binocular"];

    private _spare = _fitsOld select {!(_x in _fitsNew) && {!(_x in _others)}};

    if (_spare isNotEqualTo []) then {
        {
            private _container = _x;

            if (!isNull _container) then {
                private _layout = [_container, [_container] call EFUNC(storage,getContents)] call EFUNC(storage,getLayout);

                {
                    private _lc = toLowerANSI (_x getOrDefault ["class", ""]);

                    if (_lc in _spare && {!([_x] call FUNC(isUnique))}) then {
                        private _n = _x getOrDefault ["count", 1];

                        if ([[_container, _x], -1, true] call FUNC(giveBack)) then {
                            _gaveBack = _gaveBack + _n;
                        };
                    };
                } forEach (_layout get "entries");
            };
        } forEach [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];
    };
};

// The parts that changed with the weapon are no news for ACE's listeners.
[true] call FUNC(weaponEvents);

["equip", _class] call EFUNC(gui,playSound);

switch (true) do {
    case (_gaveBack > 0): {
        [format [LLSTRING(Hint_MagsBack), _gaveBack, [_oldClass] call EFUNC(gui,itemName)]] call FUNC(message);
    };
    case (_stored): {
        [format [
            LLSTRING(Hint_StoredOld), [_oldClass] call EFUNC(gui,itemName),
            [(uiNamespace getVariable [QGVAR(column), createHashMap]) getOrDefault ["stored", objNull]] call EFUNC(gui,containerName)
        ]] call FUNC(message);
    };
    default {
        [format [LLSTRING(Hint_Added), [_class] call EFUNC(gui,itemName)]] call FUNC(message);
    };
};

call EFUNC(gui,requestRebuild);

true
