#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Gives the instance of a kit taken away in ACE Arsenal back to Enhanced First Aid Kits' pool, with what it held
 * (efak_core_fnc_freeInstance), as that mod does for a kit ACE's own "-" takes out (efak_arsenal_fnc_onCargoChanged):
 * a kit taken out of the panel (einv_arsenal_fnc_remove, fnc_removeKind), out of a kit (fnc_discard), what did not
 * fit when the window closed (einv_arsenal_fnc_dropOverflow) and what lay in the staging space as it went
 * (einv_arsenal_fnc_onClosed). Without it each such kit kept its instance - a class of a numbered pool - for the
 * rest of the mission. Only for an instance (not a prototype, which has none yet) that lies in none of the holders
 * given any more, their cargo or what Strict mode's hidden holder keeps for them; the kits packed inside it go back
 * with it (that mod's freeInstance).
 *
 * Arguments:
 * 0: Classes taken away <ARRAY of STRINGs>
 * 1: Where a kit of such a class may still lie - the soldier's uniform, vest and backpack, the staging space
 *    <ARRAY of OBJECTs> (default: [])
 *
 * Return Value:
 * How many instances went back <NUMBER>
 *
 * Example:
 * [["efak_IFAK_7"], [uniformContainer player]] call einv_compat_efak_fnc_arsenalFree;
 *
 * Public: No
 */

params [["_classes", [], [[]]], ["_holders", [], [[]]]];

if (isNil QEFAKFUNC(core,freeInstance)) exitWith {0};

private _unready = missionNamespace getVariable [QEFAKGVAR(core,needsConversion), createHashMap];
private _kits = createHashMap;

{
    if (_x isEqualType "" && {[_x] call FUNC(isKit)} && {!(toLowerANSI _x in _unready)}) then {
        _kits set [toLowerANSI _x, _x];
    };
} forEach _classes;

if (count _kits == 0) exitWith {0};

// What still lies in the holders, in lowercase.
private _left = createHashMap;

{
    if (!isNull _x) then {
        {
            _left set [toLowerANSI _x, true];
        } forEach (((getItemCargo _x) param [0, []]) + ([_x] call EFUNC(storage,hiddenClasses)));
    };
} forEach _holders;

private _freed = 0;

{
    if !(_x in _left) then {
        [_y] call EFAKFUNC(core,freeInstance);
        _freed = _freed + 1;
    };
} forEach _kits;

_freed
