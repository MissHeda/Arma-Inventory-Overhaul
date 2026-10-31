// The hotbar: how many slots, their keys, and the geometry and timing of the bar on the screen.

// ---------------------------------------------------------------------------
// Arma's interface grid. The project has no a3 include folder, so the numbers of
// \a3\ui_f\hpp\defineCommonGrids.inc are copied here under the names they have there: the grid the
// player's interface size scales, which the layout editor (CfgUIGrids) moves elements on.
// ---------------------------------------------------------------------------

#define GUI_GRID_WAbs ((safeZoneW / safeZoneH) min 1.2)
#define GUI_GRID_HAbs (GUI_GRID_WAbs / 1.2)
#define GUI_GRID_W (GUI_GRID_WAbs / 40)
#define GUI_GRID_H (GUI_GRID_HAbs / 25)

// ---------------------------------------------------------------------------
// The slots: seven, on 4 5 6 7 8 9 0. The keys are the defaults of the keybinds [DIK code, name]; the
// player can move them in Configure Addons.
// ---------------------------------------------------------------------------

#define SLOT_COUNT 7
#define DEFAULT_KEYS [[5, "4"], [6, "5"], [7, "6"], [8, "7"], [9, "8"], [10, "9"], [11, "0"]]
#define DIK_G 34
#define DIK_DELETE 211

// ---------------------------------------------------------------------------
// The bar on the screen: seven square boxes side by side with a line for messages above them, at the
// bottom centre. Positions are read from the profile, where the layout editor keeps them
// (IGUI_einv_hotbar_grid_X and _Y), and fall back to the defaults.
// ---------------------------------------------------------------------------

#define HUD_SLOT_H (2.4 * GUI_GRID_H)
#define HUD_SLOT_W (HUD_SLOT_H * pixelW / pixelH)
#define HUD_GAP_W (0.25 * GUI_GRID_W)
#define HUD_MESSAGE_H (1 * GUI_GRID_H)
#define HUD_BAR_H (0.15 * GUI_GRID_H)
#define HUD_W (SLOT_COUNT * HUD_SLOT_W + (SLOT_COUNT - 1) * HUD_GAP_W)
#define HUD_H (HUD_MESSAGE_H + HUD_SLOT_H)
#define HUD_DEFAULT_X (safeZoneX + (safeZoneW - HUD_W) / 2)
#define HUD_DEFAULT_Y (safeZoneY + safeZoneH - HUD_H - 3.2 * GUI_GRID_H)
#define HUD_X profileNamespace getVariable [ARR_2('IGUI_einv_hotbar_grid_X',HUD_DEFAULT_X)]
#define HUD_Y profileNamespace getVariable [ARR_2('IGUI_einv_hotbar_grid_Y',HUD_DEFAULT_Y)]

// The group of controls the bar is made in, inside the titles display.
#define HUD_GROUP_IDC 9701

// Seconds to fade in and out, how often the counts are read while the bar shows, how long a refused
// press lights its box, and how long a message stays.
#define HUD_FADE 0.3
#define HUD_COUNT_INTERVAL 0.25
#define HUD_FLASH 0.6
#define HUD_MESSAGE_TIME 2.5

// ---------------------------------------------------------------------------
// Using what lies on a slot
// ---------------------------------------------------------------------------

// A second press within this many seconds is ignored.
#define USE_LOCK 0.4

// Without ACE's advanced throwing a second press within this many seconds throws what the first one
// readied.
#define THROW_AGAIN 1.5

// The gap ACE's advanced throwing keeps between two throws (ace_advanced_throwing_fnc_canPrepare).
#define THROW_COOLDOWN 2
