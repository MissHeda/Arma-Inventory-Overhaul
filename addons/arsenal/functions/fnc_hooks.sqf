#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The hook table the inventory's engine is attached to ACE Arsenal's display with (einv_gui_fnc_attach).
 * The engine is a guest there: it sweeps only what it made, and ACE's own handlers keep every click. It
 * draws neither the inventory's header nor its footer, only the open container's grid in the panel and a
 * line for its hints (fnc_layout, fnc_footer); the camera is ACE's, and so is the closing.
 *
 * The mouse is the engine's only over the panel and while it holds something it lifted there (fnc_onMouse,
 * fnc_onFrame); clicks that would equip or move things elsewhere are swallowed (fnc_onClick). Whatever is
 * let go outside the panel is taken out of the container, never put on the ground (fnc_dragCheck,
 * fnc_onDrop, the "ground" hook - Delete over a tile ends there too), and the right click has only "Remove"
 * and "Remove all" (fnc_menu). Over nothing the hint line says what the panel does.
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

    // How it looks: no header of the inventory's, the panel, and its hint line in place of the footer
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

    // Dragging, and what leaves the panel
    ["dragCheck", {_this call FUNC(dragCheck)}],
    ["drop", {_this call FUNC(onDrop)}],
    ["ground", {_this call FUNC(remove); true}],

    // The right click, and what the hint line says over nothing
    ["menu", {_this call FUNC(menu)}],
    ["hint", {
        params [["_kind", "", [""]]];

        [[], [[LLSTRING(Hint_Idle), "muted"]]] select (_kind isEqualTo "none")
    }]
]
