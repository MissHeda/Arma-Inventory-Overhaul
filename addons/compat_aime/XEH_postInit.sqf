#include "script_component.hpp"

// ACE's self interaction is the player's own: nothing to change where nobody looks at a screen.
if (!hasInterface) exitWith {};

// "Change Ammo Type" (AIME, ACE self interaction): AIME lists every magazine in every container and loads
// the one the engine's reload picks, from the backpack too - past the "Use items from ..." settings. Its
// menu is built by a function of its own that cannot be changed, so the action is taken out and one of the
// same name, place and look is put in, listing and loading only what the settings leave open (fnc_ammoMenus,
// fnc_ammoLoad). AIME's own setting "Enable ammo switch menu" is still read (fnc_ammoCondition).
//
// Once AIME has registered its action: both addons add theirs at postInit and the order between them is not
// ours. ACE builds the menu of a class from the registered actions the first time it needs it, so the old
// one is taken out of every class built so far and kept out of every class built later (the removal with
// inheritance), and the new one is registered for both (the add with inheritance).
[
    {(ACEGVAR(interact_menu,inheritedActionsMan) findIf {((_x select 2) select 0) isEqualTo AIME_AMMO_ACTION}) >= 0},
    {
        ["CAManBase", 1, ["ACE_SelfActions", AIME_AMMO_ACTION], true] call ACEFUNC(interact_menu,removeActionFromClass);

        private _action = [
            AIME_AMMO_ACTION,
            LLSTRING(Action_ChangeAmmo),
            "\A3\ui_f\data\igui\cfg\actions\reload_ca.paa",
            {},
            {_this call FUNC(ammoCondition)},
            {_this call FUNC(ammoMenus)}
        ] call ACEFUNC(interact_menu,createAction);

        ["CAManBase", 1, ["ACE_SelfActions"], _action, true] call ACEFUNC(interact_menu,addActionToClass);

        INFO("AIME's Change Ammo Type was replaced by this mod's own: only magazines the use settings allow.");
    },
    [],
    60,
    {
        WARNING("AIME's Change Ammo Type action was not registered within a minute - it stays as AIME made it.");
    }
] call CBA_fnc_waitUntilAndExecute;
