#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Tells the player once which keys of the hotbar are used by something else as well - another mod's
 * keybind on the same key, or one of Arma's command menus (1 to 0) - and where to change it. ACE binds
 * 6, 7 and 0 to its grenades and holstering, and Arma's command menus sit on 1 to 0: a slot on such a
 * key shares it until one of the two is moved. The hotbar changes nobody else's keys.
 *
 * The notice is a line in the chat. It is not repeated: what it said is kept in the profile and a
 * notice comes again only when the list is a different one.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_hotbar_fnc_checkKeys;
 *
 * Public: No
 */

if (!(call FUNC(isActive)) || {isNil "cba_keybinding_actions"} || {isNil "cba_keybinding_addons"}) exitWith {};

private _lines = [];
private _others = [];

// Every other action with a key of CBA's: [key, modifiers, what it is called].
{
    private _action = cba_keybinding_actions getVariable _x;

    if (isNil "_action") then {continue};

    private _name = _action param [0, ""];

    // The addon's name as its mod wrote it - the variable's name is lowercase.
    private _addon = _x select [0, (_x find "$") max 0];
    _addon = (cba_keybinding_addons getVariable [_addon, [_addon]]) param [0, _addon];

    if (_name isEqualType []) then {
        _name = _name param [0, ""];
    };

    // The slots' own keybinds are not "something else".
    if ((_x find "einv_hotbar") >= 0 || {_name isEqualTo ""}) then {continue};

    {
        _others pushBack [_x select 0, _x select 1, format ["%1 - %2", _addon, _name]];
    } forEach (_action param [2, []]);
} forEach (allVariables cba_keybinding_actions);

for "_i" from 0 to (SLOT_COUNT - 1) do {
    private _entry = [CBA_SETTINGS_EINV, format [QGVAR(slot%1), _i + 1]] call CBA_fnc_getKeybind;

    if (isNil "_entry") then {continue};

    private _shared = [];

    {
        _x params ["_key", "_modifiers"];

        if (_key <= 0) then {continue};

        // Arma's command menus have the number keys, with no modifier.
        if (_modifiers isEqualTo [false, false, false]) then {
            {
                if (_key in actionKeys _x) exitWith {
                    _shared pushBackUnique LLSTRING(Shared_CommandMenu);
                };
            } forEach ["CommandingMenu1", "CommandingMenu2", "CommandingMenu3", "CommandingMenu4", "CommandingMenu5", "CommandingMenu6", "CommandingMenu7", "CommandingMenu8", "CommandingMenu9", "CommandingMenu0"];
        };

        private _pressed = [_key, _modifiers];

        {
            if ([_x select 0, _x select 1] isEqualTo _pressed) then {
                _shared pushBackUnique (_x select 2);
            };
        } forEach _others;
    } forEach (_entry param [8, []]);

    if (_shared isNotEqualTo []) then {
        _lines pushBack format ["%1: %2", [_i] call FUNC(keyName), _shared joinString ", "];
    };
};

if (_lines isEqualTo []) exitWith {};

private _text = _lines joinString "; ";

if ((profileNamespace getVariable ["einv_hotbar_keysNoticed", ""]) isEqualTo _text) exitWith {};

systemChat format [LLSTRING(Notice_SharedKeys), _text];

profileNamespace setVariable ["einv_hotbar_keysNoticed", _text];
saveProfileNamespace;
