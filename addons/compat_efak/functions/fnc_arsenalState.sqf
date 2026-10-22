#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Everything a kit's answer to "one more of this?" depends on, as one value that compares equal while none of it
 * changed: what it holds (that mod's table, copied), where its tiles lie (its places' revision), the rules, whether
 * it follows the default contents, what the kits tab may change about its type, and whether its contents are here.
 * ACE Arsenal's panel keeps its answers per class while this stays the same (einv_arsenal_fnc_ungreyKit).
 *
 * Arguments:
 * 0: Kit class <STRING>
 *
 * Return Value:
 * The state <ARRAY>
 *
 * Example:
 * ["efak_IFAK_7"] call einv_compat_efak_fnc_arsenalState;
 *
 * Public: No
 */

params [["_kit", "", [""]]];

private _key = toLowerANSI _kit;

[
    _key,
    +([_kit] call EFAKFUNC(core,getContents)),
    (["kit:" + _key] call EFUNC(storage,readPlaces)) param [0, 0],
    missionNamespace getVariable [QEGVAR(items,rulesRevision), 0],
    _key in (missionNamespace getVariable [QEFAKGVAR(core,followDefaults), createHashMap]),
    if (isNil QEFAKFUNC(core,getArsenalEditing)) then {-1} else {[_kit] call EFAKFUNC(core,getArsenalEditing)},
    [] call FUNC(notReady)
]
