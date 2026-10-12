#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What an item does when its key is pressed - the one question that decides what may go on the hotbar.
 * Asked once per class and kept. In this order, the first that applies:
 *
 *   "kit"     - a kit of Enhanced First Aid Kits or Enhanced Utility Pouches; opens it. Data: its prototype.
 *   "throw"   - a grenade, a smoke shell, a chemlight: anything the Throw weapon takes. Takes it in hand.
 *   "consume" - food or drink of ACE's field rations. Data: the class and what it turns into, so a
 *               bottle that became half a bottle is still the same key.
 *   "medical" - what ACE's treatments (or those of a mod that adds its own) use up. Data: its actions,
 *               [[action, role], ...] (fnc_treatmentIndex).
 *   "reload"  - a magazine: reloads the weapon in the hands with it. Whether it fits a weapon the unit
 *               carries is for fnc_canBind.
 *   ""        - nothing: weapons, attachments, clothes, maps, radios, tools, explosives ...
 *
 * Arguments:
 * 0: Class <STRING>
 *
 * Return Value:
 * [kind, data] - the kind above, data as it says, [] when it has none <ARRAY>
 *
 * Example:
 * ["ACE_elasticBandage"] call einv_hotbar_fnc_useOf;
 *
 * Public: Yes
 */

params [["_class", "", [""]]];

if (_class isEqualTo "") exitWith {["", []]};

private _key = toLowerANSI _class;
private _known = GVAR(useCache) getOrDefault [_key, []];

if (_known isNotEqualTo []) exitWith {_known};

private _result = ["", []];

call {
    // Kits and pouches: the whole type, whichever kit of it is carried.
    if (!isNil "efak_core_fnc_isKit" && {[_class] call efak_core_fnc_isKit}) exitWith {
        _result = ["kit", [_class] call efak_core_fnc_getPrototype];
    };

    // Everything the Throw weapon takes, from all of its muzzles - mods add theirs to them. Worked out once.
    if (isNil QGVAR(throwables)) then {
        GVAR(throwables) = createHashMap;

        {
            {
                GVAR(throwables) set [toLowerANSI _x, true];
            } forEach (compatibleMagazines ["Throw", _x]);
        } forEach getArray (configFile >> "CfgWeapons" >> "Throw" >> "muzzles");
    };

    if (_key in GVAR(throwables)) exitWith {
        _result = ["throw", []];
    };

    // Food and drink: a value to quench or to satisfy, then what is left when it is used.
    private _fnc_consumable = {
        params ["_item"];

        private _config = _item call CBA_fnc_getItemConfig;

        isClass _config
        && {getNumber (_config >> "acex_field_rations_thirstQuenched") > 0 || {getNumber (_config >> "acex_field_rations_hungerSatiated") > 0}}
    };

    if ([_class] call _fnc_consumable) exitWith {
        private _chain = [_class];
        private _next = getText ((_class call CBA_fnc_getItemConfig) >> "acex_field_rations_replacementItem");

        while {_next isNotEqualTo "" && {count _chain < 4} && {(_chain findIf {_x == _next}) < 0} && {[_next] call _fnc_consumable}} do {
            _chain pushBack _next;
            _next = getText ((_next call CBA_fnc_getItemConfig) >> "acex_field_rations_replacementItem");
        };

        _result = ["consume", _chain];
    };

    // Medicine and bandages: the treatments that use it up.
    private _actions = (call FUNC(treatmentIndex)) getOrDefault [_key, []];

    if (_actions isNotEqualTo []) exitWith {
        _result = ["medical", _actions];
    };

    if (isClass (configFile >> "CfgMagazines" >> _class) && {getNumber (configFile >> "CfgMagazines" >> _class >> "count") >= 1}) exitWith {
        _result = ["reload", []];
    };
};

GVAR(useCache) set [_key, _result];

_result
