#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Compares the rules this client compiled with what the server published (fnc_loadRules) and warns
 * once - in the RPT and in the chat - when they cannot agree: another version of the mod, or the same
 * settings read into other sizes. Layouts are worked out on each machine; when two read the same
 * rules differently, a move one player's window allows can look wrong on another's.
 *
 * Only settings that are the same on both sides are compared - the server's hash and CBA's settings
 * reach a client in either order, and comparing in between would warn on every change. Runs after
 * every compile and when the server publishes anew.
 *
 * Arguments:
 * 0: What the server published, [settings key, hash, version] <ARRAY> (default: aio_items_rulesHash)
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call aio_items_fnc_checkServerRules;
 *
 * Public: No
 */

params [["_server", missionNamespace getVariable [QGVAR(rulesHash), []], [[]]]];

if (isServer || {!(_server isEqualTypeArray ["", "", ""])}) exitWith {};

_server params ["_inputsKey", "_hash", "_version"];

if (_version isNotEqualTo QUOTE(VERSION_STR)) exitWith {
    if (!GVAR(versionWarned)) then {
        GVAR(versionWarned) = true;

        WARNING_2("Arma Inventory Overhaul %1 here, %2 on the server - item sizes and grids may not match.",QUOTE(VERSION_STR),_version);

        if (hasInterface) then {
            systemChat format [LLSTRING(Warning_VersionMismatch), QUOTE(VERSION_STR), _version];
        };
    };
};

if (isNil QGVAR(ruleset) || {_inputsKey isNotEqualTo (missionNamespace getVariable [QGVAR(rulesInputsKey), ""])}) exitWith {};

if (_hash isNotEqualTo (GVAR(ruleset) get "hash") && {!GVAR(hashWarned)}) then {
    GVAR(hashWarned) = true;

    WARNING_2("The same rules compile to %1 here and %2 on the server - a preset differs.",GVAR(ruleset) get "hash",_hash);

    if (hasInterface) then {
        systemChat LLSTRING(Warning_HashMismatch);
    };
};
