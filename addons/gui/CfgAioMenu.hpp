// The inventory's right-click menu and double click, set by mods without script (aio_gui_fnc_menuInit).
// The same from script: aio_gui_fnc_addMenuEntry, aio_gui_fnc_hideMenuEntry, aio_gui_fnc_setDoubleClick.
//
// class CfgAioMenu {
//     class Entries {                           // rows of the menu - options of CBA's item context menu
//         class myMod_drink {                   // its id
//             displayName = "Drink";
//             items[] = {"myMod_Canteen"};      // classes (child classes too), "##" + subtype, "#" + type, "#All"
//             statement = "systemChat 'Gulp'"; // _this = [unit, container, item, slot, params, id]
//             condition = "true";               // shown at all (optional)
//             enabled = "true";                 // greyed out while false (optional)
//             slots[] = {"ALL"};                // CBA's slots (optional)
//             consume = 0;                      // 1: used up first (optional)
//             doubleClick = 1;                  // a double click runs it (optional)
//             tooltip = ""; icon = "";          // (optional)
//         };
//     };
//     class Hide {                              // rows hidden by id
//         class myMod_noDrop { entries[] = {"drop", "hotbar"}; items[] = {"myMod_Canteen"}; };
//     };
//     class Change {                            // the window's own rows: another name or picture
//         class myMod_canteenDrop { entries[] = {"drop"}; items[] = {"myMod_Canteen"}; displayName = "$STR_myMod_Pour"; icon = "myMod\\ui\\pour_ca.paa"; };
//     };
//     class DoubleClick {                       // "move", "menu" or the id (or name) of a row
//         class myMod_canteen { items[] = {"myMod_Canteen"}; action = "menu"; };
//     };
// };
//
// Ids of the window's own rows: inspect, attachments, equip, attach, load, detach, drop, swap, open, repack, hotbar, kit, radio,
// selectAll, arsenal, settings, cancel, deselect.

class CfgAioMenu {
    class Entries {};
    class Hide {};
    class Change {};
    class DoubleClick {};
};
