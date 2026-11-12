#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Each player's own view of a weapon (Mia, 0.7.13): how he turned, zoomed and moved it in the inspect card's 3D view
 * (fnc_inspect3D) is kept per weapon class in his profile, and the weapon's card shows it the same way (fnc_cardScene) - the
 * MX SW zoomed in on its optic is there again after a restart. A view is [turn from the side view in degrees, pitch in degrees,
 * zoom (1 fits the weapon to the picture), move across, move up - both in half a picture's width or height], WEAPON_VIEW_PLAIN
 * for none: from the left side, fitted (fnc_viewCamera makes a camera of it).
 *
 * "Show view on slot", the inspect card's checkbox, switches it off for that one weapon (GVAR(viewsOff), by class, in the
 * profile too): its card shows it plainly, the inspect card starts plainly and keeps nothing - the view kept before stays for
 * when it is on again. Per weapon since 0.7.15: one switch for all of them took the handgun's view away with the rifle's (Mia).
 *
 * Arguments:
 * 0: What to do <STRING>
 *    "get"   the view the weapon is shown with: its own, or the plain one
 *    "set"   this view is the weapon's own from now on (the plain one: it has none any more)
 *    "shown" whether the weapon's slot shows its view
 *    "apply" the weapon's slot shows its view, and the view is kept (argument 2: true or false) - its card is drawn anew
 *    "save"  what changed goes to the profile's file (the inspect card closing)
 * 1: Weapon class <STRING> (default: "")
 * 2: "set": the view <ARRAY>; "apply": on or off <BOOL> (default: [])
 *
 * Return Value:
 * "get": the view <ARRAY>; "shown": <BOOL>; else nothing
 *
 * Example:
 * ["get", "arifle_MX_SW_F"] call aio_gui_fnc_weaponView;
 *
 * Public: No
 */

params [["_mode", "", [""]], ["_class", "", [""]], ["_value", []]];

private _key = toLowerANSI _class;

switch (_mode) do {
    case "shown": {
        !(_key in GVAR(viewsOff))
    };

    case "get": {
        if (_key in GVAR(viewsOff)) exitWith {+WEAPON_VIEW_PLAIN};

        private _view = GVAR(weaponViews) getOrDefault [_key, WEAPON_VIEW_PLAIN];

        // Five numbers, or it is nobody's view (a profile written by hand, an older format).
        if !(_view isEqualTypeArray WEAPON_VIEW_PLAIN) exitWith {+WEAPON_VIEW_PLAIN};

        +_view
    };

    case "set": {
        if (_key isEqualTo "" || {_key in GVAR(viewsOff)} || {!(_value isEqualTypeArray WEAPON_VIEW_PLAIN)}) exitWith {};

        // As good as plain: none of its own.
        private _plain = true;

        {
            if (abs ((_value select _forEachIndex) - _x) > 0.01) exitWith {_plain = false};
        } forEach WEAPON_VIEW_PLAIN;

        if (_plain) then {
            GVAR(weaponViews) deleteAt _key;
        } else {
            GVAR(weaponViews) set [_key, +_value];
        };

        GVAR(viewsDirty) = true;
    };

    case "apply": {
        if (_key isEqualTo "") exitWith {};

        if (_value isEqualTo true) then {
            GVAR(viewsOff) deleteAt _key;
        } else {
            GVAR(viewsOff) set [_key, true];
        };

        profileNamespace setVariable [QGVAR(weaponViewsOff), GVAR(viewsOff)];
        saveProfileNamespace;

        ["view", [_class]] call FUNC(cardScene);
    };

    case "save": {
        if (!GVAR(viewsDirty)) exitWith {};

        GVAR(viewsDirty) = false;
        profileNamespace setVariable [QGVAR(weaponViews), GVAR(weaponViews)];
        saveProfileNamespace;
    };
};
