#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether an item class may go on the hotbar at all: only what does something when its key is pressed
 * (fnc_useOf). A weapon, an attachment, a uniform, a map or a radio does not, and neither does a
 * magazine that fits none of the weapons the player carries - nor food and drink while ACE's field
 * rations are off. Where the item lies is another question (fnc_canBindFrom).
 *
 * Arguments:
 * 0: Class <STRING>
 *
 * Return Value:
 * [may, reason] - reason is a text to show, "" when it may <ARRAY>
 *
 * Example:
 * ["ACE_tourniquet"] call aio_hotbar_fnc_canBind;
 *
 * Public: No
 */

params [["_class", "", [""]]];

([_class] call FUNC(useOf)) params ["_kind"];

switch (_kind) do {
    case "": {[false, LLSTRING(Reason_NoUse)]};
    case "reload": {
        // A magazine goes where the weapons take it: the magazine slot or the grenade launcher's.
        private _unit = ACE_player;
        private _fits = (["primary", "handgun", "launcher"] findIf {([_unit, _x, _class] call EFUNC(storage,partFor)) isNotEqualTo ""}) >= 0;

        [_fits, ["", LLSTRING(Reason_FitsNoWeapon)] select !_fits]
    };
    case "consume": {
        private _on = !isNil "ace_field_rations_fnc_consumeItem" && {missionNamespace getVariable ["acex_field_rations_enabled", false]};

        [_on, ["", LLSTRING(Reason_RationsOff)] select !_on]
    };
    default {[true, ""]};
}
