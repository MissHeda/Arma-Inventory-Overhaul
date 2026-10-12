#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A key in the window (the "key" hook), after the inventory's own: Escape closes (in the Eden editor it
 * cancels; in ACE's showcase mission Arsenal.VR it asks first, fnc_leaveVR), Backspace hides and shows the
 * panels, the night vision key goes through normal, night vision and thermal, Ctrl+F finds, Ctrl+C copies a
 * class or a loadout, Ctrl+V imports one, Delete gives back what the mouse is on, the arrow keys add and
 * give back one. The Gear key does nothing here. While the panels are hidden every key but Escape,
 * Backspace and the night vision key does nothing.
 *
 * Ctrl+C copies the class of what the mouse is on - a card, a tile, a slot - and only when there is
 * nothing there the soldier's loadout (with Shift the list of default loadouts); Ctrl+V takes a loadout
 * (with Shift in the Eden editor a list of defaults). Typing in a field never gets here: the field has the
 * keys (einv_gui_fnc_onKeyDown).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: DIK code <NUMBER>
 * 2: Shift held <BOOL>
 * 3: Ctrl held <BOOL>
 * 4: Alt held <BOOL>
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * [_display, 14, false, false, false] call einv_arsenal_fnc_onKey;
 *
 * Public: No
 */

#define DIK_BACKSPACE 14
#define DIK_F 33
#define DIK_C 46
#define DIK_V 47
#define DIK_LEFT 203
#define DIK_RIGHT 205

params ["_display", "_key", ["_shift", false], ["_ctrl", false], ["_alt", false]];

// ACE's own flag, read by the windows of other mods that look at it.
ACEGVAR(arsenal,shiftState) = _shift;

// What reached here is not the menu's, the card's or a field's: Escape closes - or, in Arsenal.VR, asks.
if (_key == DIK_ESCAPE) exitWith {
    if !([] call FUNC(leaveVR)) then {
        [2] call FUNC(close);
    };

    true
};

// The Gear key opens and closes the inventory; this is not it.
if (_key in actionKeys "Gear") exitWith {true};

// Backspace: the panels go, and come back (the field has Backspace for itself while it is typed in).
if (_key == DIK_BACKSPACE) exitWith {
    call FUNC(toggleHidden);

    true
};

// The game's night vision key: normal, night vision, thermal. Also while the panels are away - that is
// when the soldier is looked at.
if (_key in actionKeys "nightvision") exitWith {
    [] call FUNC(cycleVision);

    true
};

// Nothing can be pointed at while the panels are away, so no other key has anything to act on.
if (GVAR(hidden)) exitWith {true};

// Ctrl+F: into the search field.
if (_ctrl && {_key == DIK_F}) exitWith {
    ctrlSetFocus (uiNamespace getVariable [QEGVAR(gui,filterEdit), controlNull]);

    true
};

// Ctrl+C: the class under the mouse, else the loadout.
if (_ctrl && {_key == DIK_C}) exitWith {
    if !(call FUNC(copyClass)) then {
        [_shift] call FUNC(loadoutExport);
    };

    true
};

// Ctrl+V: a loadout from the clipboard.
if (_ctrl && {_key == DIK_V}) exitWith {
    [_shift && {is3DEN}] call FUNC(loadoutImport);

    true
};

// Delete: what the mouse is on goes back.
if (_key == DIK_DELETE) exitWith {
    if (!EGVAR(gui,dragging)) then {
        EGVAR(gui,hover) params [["_kind", ""], ["_index", -1], ["_tile", -1]];

        switch (_kind) do {
            case "tile": {
                [[_index, _tile]] call FUNC(giveBack);
            };
            case "slot": {
                // A slot is [rect, class, caption, anchor, weapon, slot, unit, hotbar].
                ((uiNamespace getVariable [QEGVAR(gui,slots), []]) param [_index, []]) params ["", ["_class", ""], "", "", "", ["_slot", ""], ["_unit", objNull]];

                if (_class isNotEqualTo "" && {_slot isNotEqualTo ""} && {!isNull _unit}) then {
                    [[_unit, _slot]] call FUNC(giveBack);
                };
            };
            default {};
        };
    };

    true
};

// The arrows: one more of that class, or one less (Shift: five).
if (_key == DIK_RIGHT || {_key == DIK_LEFT}) exitWith {
    if (!EGVAR(gui,dragging)) then {
        [[-1, 1] select (_key == DIK_RIGHT), _shift] call FUNC(stepCount);
    };

    true
};

false
