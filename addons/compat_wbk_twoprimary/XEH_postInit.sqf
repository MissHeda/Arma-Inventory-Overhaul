#include "script_component.hpp"

if (!hasInterface) exitWith {};

// How often what lies on the back and in the containers is noted for the switch WebKnight's mod makes by itself, in seconds.
#define GUARD_NOTE 0.25

// The guard round WebKnight's switch (fnc_guard, issue 74). Its key looks the function up when it is pressed, so the one put
// in its place here is what runs: what is on the back and in the containers is noted, that mod's own switch runs untouched, and
// once the weapon from the back is in the hands its magazines are put right. This addon loads after that mod (requiredAddons),
// so its function is there by now; where it is not - another version of that mod - nothing is wrapped.
if (!isNil "WBK_CreateSwitchBetweenWeapons" && {WBK_CreateSwitchBetweenWeapons isEqualType {}} && {isNil QGVAR(switch)}) then {
    GVAR(switch) = WBK_CreateSwitchBetweenWeapons;

    // That mod's code sets its variables without "private": none of this one's may bear a name it uses.
    WBK_CreateSwitchBetweenWeapons = {
        private _aioUnit = _this;
        private _aioNoted = if (_aioUnit isEqualType objNull) then {["note", _aioUnit] call FUNC(guard)} else {[]};

        _this call GVAR(switch);

        if (_aioNoted isNotEqualTo [] && {(_aioNoted select 0) isNotEqualTo []}) then {
            ["watch", _aioUnit, _aioNoted] spawn FUNC(guard);
        };
    };
} else {
    WARNING("WebKnight's switch function was not found - the magazines of the weapon on the back are not guarded.");
};

// The switch that mod makes by itself when the primary weapon is put away (its Put handler, which cannot be wrapped): what was
// on the back and in the containers a moment before is what is noted every GUARD_NOTE seconds.
GVAR(noted) = [];

[{
    private _unit = player;

    if (isNull _unit || {!alive _unit} || {isNil {_unit getVariable "WBK_SecondWeapon"}}) exitWith {
        GVAR(noted) = [];
    };

    GVAR(noted) = ["note", _unit] call FUNC(guard);
}, GUARD_NOTE] call CBA_fnc_addPerFrameHandler;

["CAManBase", "Put", {
    params ["_unit"];

    if (_unit isNotEqualTo player || {GVAR(noted) isEqualTo []} || {(GVAR(noted) select 0) isEqualTo []}) exitWith {};

    // Only where that mod takes the weapon off the back: the hands are empty now, or hold it already.
    private _class = (GVAR(noted) select 0) param [0, ""];

    if (primaryWeapon _unit isEqualTo "" || {primaryWeapon _unit == _class && {isNil {_unit getVariable "WBK_SecondWeapon"}}}) then {
        ["watch", _unit, +GVAR(noted)] spawn FUNC(guard);
    };
}] call CBA_fnc_addClassEventHandler;
