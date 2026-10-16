#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The hook table the inventory's engine is attached to ACE Arsenal's display with (einv_gui_fnc_attach).
 * The engine is a guest there: it sweeps only what it made, and ACE's own handlers keep every click. It
 * draws neither the inventory's header nor its footer, only the open container's grid and the staging
 * space in the panel and a line for its hints (fnc_layout, fnc_footer), in the inventory's look; the
 * camera is ACE's, and so is the closing.
 *
 * The mouse is the engine's only over the panel and while it holds something it lifted there or out of
 * ACE's list (fnc_onMouse, fnc_onFrame, fnc_listDrag); clicks that would equip or move things elsewhere are
 * swallowed (fnc_onClick). Whatever is let go outside the panel is taken out, never put on the ground
 * (fnc_dragCheck, fnc_onDrop, the "ground" hook - Delete over a tile ends there too); an item out of ACE's
 * list goes in only on a free spot of a grid. The right click has only "Remove" and "Remove all"
 * (fnc_menu), Ctrl and the wheel over a tile add or take out one (fnc_onWheel). Over nothing the hint line
 * says what the panel does, and what lies in the staging space while something does. A section's caption
 * folds it, kept per container class while ACE's window is open (the "fold" hook, fnc_layout).
 *
 * Each is a function of this addon, found by name when it is called, so a function compiled again while
 * testing is the one used.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Hooks, name -> CODE or flag <HASHMAP>
 *
 * Example:
 * call einv_arsenal_fnc_hooks;
 *
 * Public: No
 */

createHashMapFromArray [
    // A guest on another mod's display
    ["guest", true],

    // How it looks: the inventory's own look, no header of it, the panel, and its hint line in place of the
    // footer
    ["header", {}],
    ["layout", {_this call FUNC(layout)}],
    ["footer", {_this call FUNC(footer)}],

    // ACE's camera, and ACE decides when its window closes
    ["camera", {}],
    ["keepOpen", true],
    ["frame", {_this call FUNC(onFrame)}],

    // The mouse
    ["mouseDown", {([true] + _this) call FUNC(onMouse)}],
    ["mouseUp", {([false] + _this) call FUNC(onMouse)}],
    ["click", {_this call FUNC(onClick)}],
    ["wheel", {_this call FUNC(onWheel)}],

    // Dragging, and what leaves the panel
    ["dragCheck", {_this call FUNC(dragCheck)}],
    ["drop", {_this call FUNC(onDrop)}],
    ["ground", {_this call FUNC(remove); true}],

    // The staging space is drawn here, not a section of the soldier's: its cargo and places go into the
    // engine's signature too, so a move that only rearranged it draws the panel again at once
    ["signature", {[GVAR(staging)] select {!isNull _x}}],

    // A click on a section's caption folds it per container class while ACE's window is open, not per
    // object in the inventory's list: ACE makes a new uniform, vest or backpack for every one picked
    // (fnc_layout keeps which class each section shows)
    ["fold", {
        params [["_container", objNull, [objNull]]];

        private _index = GVAR(foldKeys) findIf {(_x select 0) isEqualTo _container};

        if (_index < 0) exitWith {true};

        private _key = (GVAR(foldKeys) select _index) select 1;

        if (_key in GVAR(folded)) then {
            GVAR(folded) deleteAt _key;
        } else {
            GVAR(folded) set [_key, true];
        };

        true
    }],

    // The right click, and what the hint line says over nothing: what the panel does - cut to the line, as
    // the band has no second line for it -, Ctrl and the wheel where that still fits beside it, and while
    // something lies in the staging space, in the accent colour, that it goes when the window closes (on
    // the second line fnc_layout then gives the band, should it not fit beside)
    ["menu", {_this call FUNC(menu)}],
    ["hint", {
        params [["_kind", "", [""]]];

        if (_kind isNotEqualTo "none" || {GVAR(hintRect) isEqualTo []}) exitWith {[]};

        private _width = (GVAR(hintRect) select 2) - SQUARE(UNIT * PANEL_PAD) * 2;
        private _font = EGVAR(gui,theme) getOrDefault ["font", "PuristaMedium"];
        private _idle = [LLSTRING(Hint_Idle), _width, _font, HINT_SIZE] call EFUNC(gui,fitText);
        private _parts = [[_idle, "muted"]];

        if (GVAR(stagingCount) > 0) exitWith {
            private _note = if (GVAR(stagingCount) == 1) then {
                LLSTRING(Staging_NoteOne)
            } else {
                format [LLSTRING(Staging_Note), GVAR(stagingCount)]
            };

            _parts pushBack [[_note, _width, _font, HINT_SIZE] call EFUNC(gui,fitText), "accent"];
            _parts
        };

        // The engine puts four spaces between the parts.
        private _both = _idle + "    " + LLSTRING(Hint_Wheel);

        if (((_both getTextWidth [_font, HINT_SIZE]) * TEXT_SLACK) <= _width) then {
            _parts pushBack [LLSTRING(Hint_Wheel), "muted"];
        };

        _parts
    }]
]
