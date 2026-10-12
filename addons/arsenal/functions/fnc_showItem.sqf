#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Shows what was just put on the soldier: a weapon is held, in the pose ACE's window gives it (the rifle
 * raised, the launcher on the shoulder, the pistol out, the binoculars up), a new insignia is saluted, a new
 * voice says a line. Anything else, and a soldier whose weapon is gone, stands at ease. ACE does this when a
 * tab is chosen (ace_arsenal_fnc_showItem), which this window has not got; the poses are its own, played the
 * way it plays them, and - as ACE does - not for a unit that is not the player's own, such as one a Zeus
 * controls.
 *
 * The pose is remembered in ACE's variables of the session (ace_arsenal_currentAction,
 * ace_arsenal_selectedWeaponType). "keep" asks nothing new: the weapon shown is held again, or put away if it
 * is gone - the window looks at that after every build.
 *
 * Arguments:
 * 0: Slot of the weapon - "primary", "handgun", "launcher" or "binocular" -, "voice", "insignia", "keep",
 *    or "" for standing at ease <STRING> (default: "")
 *
 * Return Value:
 * None
 *
 * Example:
 * ["primary"] call einv_arsenal_fnc_showItem;
 *
 * Public: No
 */

params [["_what", "", [""]]];

private _unit = GVAR(center);

if (isNull _unit || {missionNamespace getVariable [QACEGVAR(arsenal,centerNotPlayer), false]}) exitWith {};

// Nothing is lifted during a reload: the magazines would go where the reload sends them.
if (missionNamespace getVariable [QACEGVAR(common,isReloading), false]) exitWith {
    [{
        !(missionNamespace getVariable [QACEGVAR(common,isReloading), false])
    }, {
        _this call FUNC(showItem);
    }, _this, 5] call CBA_fnc_waitUntilAndExecute;
};

private _current = missionNamespace getVariable [QACEGVAR(arsenal,currentAction), "Stand"];

// Nothing shown yet, and nothing to keep.
if (_what isEqualTo "keep" && {_current in ["Stand", "Civil", "Salute"]}) exitWith {};

// The weapons, in the order ACE's selectedWeaponType counts them, and the poses that hold them.
private _weapons = [primaryWeapon _unit, secondaryWeapon _unit, handgunWeapon _unit, binocular _unit];
private _poses = ["PrimaryWeapon", "SecondaryWeapon", "HandGunOn", "Binoculars"];

private _action = switch (_what) do {
    case "primary": {["Civil", "PrimaryWeapon"] select ((_weapons select 0) isNotEqualTo "")};
    case "launcher": {["Civil", "SecondaryWeapon"] select ((_weapons select 1) isNotEqualTo "")};
    case "handgun": {["Civil", "HandGunOn"] select ((_weapons select 2) isNotEqualTo "")};
    case "binocular": {["Civil", "Binoculars"] select ((_weapons select 3) isNotEqualTo "")};
    case "insignia": {"Salute"};
    case "voice": {
        _unit directSay "CuratorObjectPlaced";

        "Civil"
    };
    // The weapon shown last, when it is still there.
    case "keep": {
        private _index = _poses find _current;

        ["Civil", _current] select (_index >= 0 && {(_weapons select _index) isNotEqualTo ""})
    };
    default {"Civil"};
};

private _type = _poses find _action;

if (_type >= 0) then {
    missionNamespace setVariable [QACEGVAR(arsenal,selectedWeaponType), _type];
};

if (_action isNotEqualTo _current) then {
    if (simulationEnabled _unit) then {
        // A gesture left over would break the next animation.
        if (!isNil QACEFUNC(common,stopGesture)) then {
            _unit call ACEFUNC(common,stopGesture);
        };

        _unit playActionNow _action;
    } else {
        _unit switchAction _action;
    };

    missionNamespace setVariable [QACEGVAR(arsenal,currentAction), _action];
};

// The weapon the pose is for is the one in hand: no floating weapons.
if !(_action in ["Civil", "Salute"]) then {
    _unit selectWeapon (_weapons select (missionNamespace getVariable [QACEGVAR(arsenal,selectedWeaponType), 0]));
};
