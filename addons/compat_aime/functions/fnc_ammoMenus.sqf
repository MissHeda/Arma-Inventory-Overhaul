#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The children of "Change Ammo Type": one entry for each class of magazine the weapon in the hands takes in
 * its muzzle that the unit has and may use - the ones in a container the "Use items from ..." settings close
 * to it are not offered (einv_storage_fnc_useCarried), as AIME lists every magazine in every container. The
 * class already loaded is left out, as AIME leaves it out. Choosing one loads the fullest magazine of that
 * class (fnc_ammoLoad).
 *
 * When magazines that would do lie only in closed containers, one entry says so and where to take one out
 * of, so the menu is not simply empty.
 *
 * ACE asks it as the menu opens, for the player only.
 *
 * Arguments:
 * 0: Target - the player <OBJECT>
 * 1: Player <OBJECT>
 * 2: Action parameters - not used <ANY>
 *
 * Return Value:
 * Children for ACE, [[action, [], target], ...] <ARRAY>
 *
 * Example:
 * [ACE_player, ACE_player, []] call einv_compat_aime_fnc_ammoMenus;
 *
 * Public: No
 */

params [["_target", objNull, [objNull]], ["_player", objNull, [objNull]]];

private _weapon = currentWeapon _player;
private _muzzle = currentMuzzle _player;

if (_weapon isEqualTo "") exitWith {[]};

private _compatible = (compatibleMagazines [_weapon, _muzzle]) apply {toLowerANSI _x};
private _loaded = toLowerANSI currentMagazine _player;

// What would do: not loaded, with rounds in it, of a class this muzzle takes - and what the settings leave.
private _fnc_fit = {
    params ["_entry"];

    !(_entry select 2) && {(_entry select 1) > 0} && {(toLowerANSI (_entry select 0)) in _compatible}
};

private _all = magazinesAmmoFull _player;
private _candidates = _all select {[_x] call _fnc_fit};
private _usable = (([_player, [[], [], _all]] call EFUNC(storage,useCarried)) select 2) select {[_x] call _fnc_fit};

// By class, in the order they were found, with how many there are.
private _classes = [];
private _counts = createHashMap;

{
    private _key = toLowerANSI (_x select 0);

    if (_key isEqualTo _loaded) then {continue};

    if (_classes pushBackUnique _key >= 0) then {
        _counts set [_key, 0];
    };

    _counts set [_key, (_counts get _key) + 1];
} forEach _usable;

private _menus = [];

{
    private _class = _x;
    private _config = configFile >> "CfgMagazines" >> _class;
    private _name = getText (_config >> "displayName");

    private _action = [
        _class,
        format [LLSTRING(Menu_Left), _name, _counts get _class],
        getText (_config >> "picture"),
        {
            params ["_target", "_player", "_args"];

            _args params ["_weapon", "_muzzle", "_class"];

            [_player, _weapon, _muzzle, _class] call FUNC(ammoLoad);
        },
        {true},
        nil,
        [_weapon, _muzzle, _class]
    ] call ACEFUNC(interact_menu,createAction);

    _menus pushBack [_action, [], _target];
} forEach _classes;

// Magazines that would do lie only where the settings close them: say where.
if (_menus isEqualTo [] && {_candidates isNotEqualTo []}) then {
    private _action = [
        "blocked",
        LLSTRING(Menu_Blocked),
        "",
        {
            params ["", "_player", "_args"];

            private _where = [];

            {
                {
                    _where pushBackUnique _x;
                } forEach ([_player, _x] call EFUNC(storage,useBlockedIn));
            } forEach _args;

            [format [localize "STR_einv_storage_Hint_NoReload", [USE_KINDS select {_x in _where}] call EFUNC(storage,useKindName)]] call EFUNC(storage,useHint);
        },
        {true},
        nil,
        _candidates apply {_x select 0}
    ] call ACEFUNC(interact_menu,createAction);

    _menus pushBack [_action, [], _target];
};

_menus
