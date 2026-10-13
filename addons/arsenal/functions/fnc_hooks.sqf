#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The hook table the inventory's engine is attached to ACE Arsenal's display with (einv_gui_fnc_attach).
 * The engine is a guest there: it sweeps only what it made, and ACE's own handlers keep every click. It
 * draws neither the inventory's header nor its footer, only the open container's grid and the staging
 * space in the panel and a line for its hints (fnc_layout, fnc_footer), in ACE's look (fnc_theme); the
 * camera is ACE's, and so is the closing.
 *
 * The mouse is the engine's only over the panel and while it holds something it lifted there or out of
 * ACE's list (fnc_onMouse, fnc_onFrame, fnc_listDrag); clicks that would equip or move things elsewhere are
 * swallowed (fnc_onClick). Whatever is let go outside the panel is taken out, never put on the ground
 * (fnc_dragCheck, fnc_onDrop, the "ground" hook - Delete over a tile ends there too); an item out of ACE's
 * list goes in only on a free spot of a grid. The right click has only "Remove" and "Remove all"
 * (fnc_menu), Ctrl and the wheel over a tile add or take out one (fnc_onWheel). Over nothing the hint line
 * says what the panel does, and what lies in the staging space while something does.
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

    // How it looks: ACE's look, no header of the inventory's, the panel, and its hint line in place of the
    // footer
    ["theme", {_this call FUNC(theme)}],
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

    // The right click, and what the hint line says over nothing: what the panel does, and - while something
    // lies in the staging space - that it goes when the window closes
    ["menu", {_this call FUNC(menu)}],
    ["hint", {
        params [["_kind", "", [""]]];

        if (_kind isNotEqualTo "none") exitWith {[]};

        [
            [LLSTRING(Hint_Idle), "muted"],
            switch (true) do {
                case (GVAR(stagingCount) == 1): {[LLSTRING(Staging_NoteOne), "warn"]};
                case (GVAR(stagingCount) > 1): {[format [LLSTRING(Staging_Note), GVAR(stagingCount)], "warn"]};
                default {[LLSTRING(Hint_Wheel), "muted"]};
            }
        ]
    }]
]
