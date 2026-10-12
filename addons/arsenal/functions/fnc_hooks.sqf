#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The hook table this window attaches to the inventory's engine with (einv_gui_fnc_attach): theme, context,
 * layout, header, footer keys, camera, keep open, frame, wheel, mouse, click, key, submit, drag check,
 * drop, ground, menu, filter, tile badge, hint, inspect rows, after build and the flag that has the focus
 * given back to the sink. Each is a function of this addon, found by name when it is called, so a function
 * compiled again while testing is the one used.
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
    // How it looks
    ["theme", {_this call FUNC(theme)}],
    ["context", {_this call FUNC(context)}],
    ["layout", {_this call FUNC(layout)}],
    ["header", {_this call FUNC(drawHeader)}],
    ["footerKeys", {call FUNC(footerKeys)}],
    ["afterBuild", {_this call FUNC(afterBuild)}],

    // The soldier and the frame
    ["camera", {_this call FUNC(cameraRect)}],
    ["keepOpen", {call FUNC(keepOpen)}],
    ["frame", {_this call FUNC(onFrame)}],
    ["focusAll", true],

    // The mouse and the keys
    ["wheel", {_this call FUNC(onWheel)}],
    ["mouseDown", {_this call FUNC(onMouseDown)}],
    ["mouseUp", {_this call FUNC(onMouseUp)}],
    ["click", {_this call FUNC(onClick)}],
    ["key", {_this call FUNC(onKey)}],
    ["submit", {_this call FUNC(onSubmit)}],

    // Dragging: where a card may go, what a drop does, and that nothing ever goes to the ground - always
    // "handled", also when nothing was given back (a unique item waiting for its second click, a kit's
    // item): the inventory would put it on the ground otherwise.
    ["dragCheck", {_this call FUNC(dragCheck)}],
    ["drop", {_this call FUNC(onDrop)}],
    ["ground", {_this call FUNC(giveBack); true}],

    // Menus, the search, marks and words
    ["menu", {_this call FUNC(menu)}],
    ["filter", {call FUNC(onFilter)}],
    ["tileBadge", {_this call FUNC(tileBadge)}],
    ["hint", {_this call FUNC(hintParts)}],
    ["inspectRows", {_this call FUNC(inspectRows)}]
]
