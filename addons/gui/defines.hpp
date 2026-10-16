// The inventory window: ids, timings, textures and the screen geometry every look is laid out on.
//
// No colours of the looks here: each look's theme function holds its own (fnc_themeBase and the
// fnc_themeX of each look), so switching the style in the game recolours everything. The few colours
// below are only what the config classes start with before a theme paints them.

#define IDD_INVENTORY 9600
#define IDC_DIM       9601
#define IDC_FIRST     9602

// A top-level control with this id, and everything in it, survives every build (fnc_build): a window that
// attaches to this one may keep a control in such an id rather than make it again each time.
#define IDC_KEEP      9603

// The vanilla inventory (RscDisplayInventory), which this mod keeps closed (fnc_guardVanilla).
#define IDD_VANILLA_INVENTORY 602

// How often every client looks whether a vanilla inventory is on the screen that its load event missed,
// in seconds (XEH_postInit, fnc_guardVanilla).
#define GUARD_INTERVAL 0.25

// How many frames fnc_open waits for a vanilla inventory to go before it makes the window: made while
// one is open, the window would be its child dialog and close with it (fnc_guardVanilla).
#define OPEN_TRIES 10

// The window made again after the vanilla inventory under it was closed takes it down with it
// (fnc_guardVanilla) - not again within this many seconds, so two mods fighting over it cannot loop.
#define REOPEN_PAUSE 2

// The unit's handler is put behind every other handler of the same event (fnc_initUnit): once this many
// seconds after the mission's display exists - mods add theirs in their own postInit or in a script that
// waits for that display - and again when a vanilla inventory came up although the handler had answered
// (fnc_guardVanilla), not more often than every HANDLER_PAUSE seconds, so two mods that both want to be
// last cannot loop.
#define HANDLER_RECHECK 3
#define HANDLER_PAUSE 5

// A vanilla inventory that comes up within this many frames of the handler's answer belongs to that
// opening: the handler was asked and another handler's answer let the engine open the display anyway. One
// that comes later, or with no answer at all, was not asked for by the handler (fnc_guardVanilla).
#define ASK_FRAMES 12

// DIK codes the window looks at itself
#define DIK_ESCAPE 1
#define DIK_RETURN 28
#define DIK_NUMPADENTER 156
#define DIK_A      30
#define DIK_G      34
#define DIK_R      19
#define DIK_DELETE 211

// The Gear key (I) closes the window again - but not the press that opened it, still held down or
// repeating, which arrives within this many seconds.
#define GEAR_KEY_GRACE 0.35

// How often the open window checks whether it should still be open, in seconds.
#define CHECK_INTERVAL 0.25

// How many timed frames make one line of the timing log (fnc_logFrame).
#define FRAME_LOG_COUNT 1500

// How often it compares what the containers hold with what it shows (fnc_getSignature), in seconds.
// Rarely enough that reading a full crate's cargo costs nothing noticeable.
#define SIGNATURE_INTERVAL 1

// How long the window stays closed before the code it stepped aside for runs (fnc_stepAside): TFAR's own
// radio menu waits as long before it opens a radio, so its dialog finds none open.
#define STEP_ASIDE_DELAY 0.2

// Moves under way (fnc_sendMoves). Nothing is shown before it happened, so without an answer after
// PENDING_TIMEOUT seconds the window stops waiting and shows what is there ("Still waiting for an
// answer"); a late answer is still finished. An answer is finished once this machine reads the places it
// names, or ANSWER_WAIT seconds after it arrived - the places of a holder may reach it after its cargo.
#define PENDING_TIMEOUT 15
#define ANSWER_WAIT 3

// A holder whose places and cargo disagree (drift) is reported to its authority once it drifted for
// DRIFT_WAIT seconds - a move under way settles by itself - and again at most every DRIFT_REPEAT seconds
// (fnc_requestNormalize).
#define DRIFT_WAIT 1
#define DRIFT_REPEAT 3

// Living persons (fnc_addPersonAction, fnc_personInReach). The action is offered within PERSON_REACH
// metres from the player's eyes to the person's feet - about 2.5 m on level ground, as close as the
// engine's own inventory actions. The window closes once the two stand more than PERSON_KEEP apart; the
// person's machine turns a request down only beyond PERSON_KEEP_REMOTE, as positions reach it late.
#define PERSON_REACH 3
#define PERSON_KEEP 4
#define PERSON_KEEP_REMOTE 6

// The reach of ACE medical's own "Inventory" on the unconscious, measured the same way - its addAction
// radius (ace_medical_status_fnc_addInventoryActions). Within it the person action gives way to ACE's
// (fnc_personActionCondition): about 1.2 m to someone lying on level ground.
#define ACE_INVENTORY_REACH 2

// Whom a setting for living persons covers (einv_gui_personOpen, personItems, personWorn).
#define ACCESS_EVERYONE 2
#define ACCESS_HELPLESS 1
#define ACCESS_NONE 0

// How much brighter a tile gets under the mouse.
#define HOVER_ALPHA 0.08

// The flat grey every editor picture (editorPreview) is rendered on - BIS_fnc_exportEditorPreviews, which
// mods use as well: rgb 123 132 129 (fnc_uiPictureRounded).
#define EDITOR_PREVIEW_BACKDROP [0.482, 0.518, 0.506, 1]

// ACE's previews lie on a lighter grey (rgb 135 144 141), other mods' differ again, and a script cannot read a
// picture's pixels: the edges of the image fade into the backdrop over FADE_SHARE of the box's height in
// FADE_STEPS strips so no rectangle shows (fnc_uiPictureRounded).
#define FADE_STEPS 4
#define FADE_SHARE 0.05

// Searching, as Tarkov shows it (fnc_showSearch, fnc_animateSearch, fnc_revealFx). The ring that fills
// comes in SEARCH_FRAMES steps (search_ring_01_ca to _32_ca, drawn by tools/generate_ui_textures.py),
// as big as SEARCH_RING_SIZE of the tile's shorter side. The glass in it is SEARCH_GLASS_SIZE of the
// ring and goes round a circle of SEARCH_GLASS_ORBIT of it, SEARCH_GLASS_SPEED degrees a second. A
// rustle every SEARCH_SOUND_GAP seconds, plus up to as much again.
#define SEARCH_FRAMES 32
#define SEARCH_RING(N) format ["%1\search_ring_%2_ca.paa", QPATHTOF(ui), [str (N), "0" + str (N)] select ((N) < 10)]
#define SEARCH_RING_SIZE 0.72
#define SEARCH_GLASS_SIZE 0.5
#define SEARCH_GLASS_ORBIT 0.12
#define SEARCH_GLASS_SPEED 300
#define SEARCH_SOUND_GAP 0.3

// Longer than this between two frames of searching, and the search was paused (something held).
#define SEARCH_PAUSE 0.25

// Tiles that do not match the search field fade this far, this quickly (fnc_applyFilter).
#define FILTER_FADE 0.82
#define FILTER_TIME 0.12

// The slots that take a dragged item: their fill, under a green outline (fnc_showTargets).
#define TARGET_FILL_ALPHA 0.1

// The name at the mouse (fnc_updateHover, fnc_onFrame): this far right of and below the pointer.
#define TOOLTIP_DX SQUARE(UNIT * 0.7)
#define TOOLTIP_DY (UNIT * 0.8)

// Where a dragged item landed lights up, this strong, for this long (fnc_flashTile).
#define LAND_FLASH_ALPHA 0.28
#define LAND_FLASH 0.45

// A found item: its picture and texts fade in over REVEAL_FADE seconds, and a flash in the accent
// colour, REVEAL_FLASH_ALPHA strong, dies away over REVEAL_FLASH.
#define REVEAL_FADE 0.35
#define REVEAL_FLASH 0.6
#define REVEAL_FLASH_ALPHA 0.45

// A kit's window fades in over this many seconds when it opens (fnc_drawWindow), its title lit up in the
// accent colour as a landed tile is.
#define WINDOW_FADE 0.15

// How thick a round outline is, as a share of its corner (fnc_uiRing) - as tools/generate_ui_textures.py
// draws the ring corners.
#define RING_SHARE 0.2

// getTextWidth reports less than the engine draws: every measured text gets this much more room.
#define TEXT_SLACK 1.3

// One turn of the mouse wheel scrolls a column this far when a picture's clip group has taken the turn from it
// (fnc_passWheel): about the three rows the engine's own step comes to.
#define WHEEL_STEP (UNIT * 3)

// How many frames a clip group the wheel turned over is put back to the top, after the engine scrolled it
// (fnc_unscroll, fnc_onFrame).
#define UNSCROLL_FRAMES 3

// A label draws its text from its top edge down whatever its height, so a text that has to sit in the middle of
// a box starts a little above the box's middle: the middle of the line of capitals lies this share of the font
// height under the label's top (Purista's capitals run from about 0.4 to 0.9 of it) - fnc_uiButton in a button,
// the title row of the Arsenal panel.
#define TEXT_MID 0.66

// A button (fnc_uiButton, fnc_buttonWidth), as shares of its height: the room either side of what it holds,
// the icon, and the gap between an icon and its label.
#define BUTTON_PAD 0.3
#define BUTTON_ICON 0.56
#define BUTTON_GAP 0.22

// How far the mouse has to move with the button held before a press on a tile becomes a drag, and how
// faint the tile it was lifted from stays while it is dragged.
#define DRAG_THRESHOLD 0.008

// The slots whose gear may be exchanged with a body or a person (fnc_canSwap, fnc_doSwap): what one wears,
// never a weapon - the engine does not hand a body one.
#define SWAP_SLOTS ["headgear", "goggles", "nvg", "uniform", "vest", "backpack", "map", "gps", "radio", "compass", "watch"]

// A tall compartment (a crate's, a vehicle's) shows its rows down to the last one in use and
// COLLAPSE_SPARE_ROWS more, at least COLLAPSE_MIN_ROWS; the empty rows below fold into one line that
// opens them (fnc_viewBlocks) - only when that hides COLLAPSE_HIDE_MIN rows or more.
#define COLLAPSE_SPARE_ROWS 2
#define COLLAPSE_MIN_ROWS 4
#define COLLAPSE_HIDE_MIN 4

// ---------------------------------------------------------------------------
// Weight: what lifting something previews on the weight card, and the comparison card at the mouse
// (fnc_previewWeight, fnc_drawCompare)
// ---------------------------------------------------------------------------

// A preview of what would be added to the weight bar is this strong.
#define PREVIEW_ALPHA 0.6

// The comparison card: its width, the room of the label, of the value and of the difference, and one row.
// The padding is what is left of the width. A long name makes the card wider; the value takes the rest.
#define COMPARE_W SQUARE(UNIT * 9.5)
#define COMPARE_LABEL_W SQUARE(UNIT * 3.2)
#define COMPARE_VALUE_W SQUARE(UNIT * 4.3)
#define COMPARE_DIFF_W SQUARE(UNIT * 1.6)
#define COMPARE_ROW_H (UNIT * 0.62)

// The body zones of an item's protection from head to legs (einv_items_fnc_getProtection), the order the
// card lists them in.
#define ZONE_ORDER ["head", "face", "neck", "arms", "chest", "stomach", "pelvis", "legs"]

// Two clicks on the same tile within this many seconds are a double click.
#define DOUBLE_CLICK 0.35
#define DRAG_SOURCE_FADE 0.6
#define DRAG_FOOTPRINT_ALPHA 0.35

// Several tiles selected (fnc_drawSelection) and dragged together (fnc_makeGhost): a selected tile gets
// an accent frame and a fill SELECT_FILL_ALPHA strong, the frame dragged out from an empty cell
// (fnc_startBand) a fill BAND_FILL_ALPHA strong. A group drag shows at most GROUP_GHOSTS pictures
// at the mouse - the rest still goes along, and every tile gets its footprint.
#define GROUP_GHOSTS 12
#define SELECT_FILL_ALPHA 0.1
#define BAND_FILL_ALPHA 0.08

// The sounds (fnc_playSound, fnc_playLayer, fnc_sendNoise). The same sound twice within SOUND_REPEAT_GAP plays
// once. Others hear a looter at most every NOISE_GAP seconds, NOISE_GAIN as loud as he does, from NOISE_POINT on
// his model (the hands), up to a sound's range plus NOISE_MARGIN metres. A weapon's own reload sound plays at
// RELOAD_GAIN of its config volume. The ground under the player is read again after SURFACE_CACHE seconds.
#define SOUND_REPEAT_GAP 0.05
#define NOISE_GAP 0.2
#define NOISE_GAIN 0.9
#define NOISE_POINT [0, 0.35, 0.9]
#define NOISE_MARGIN 5
#define RELOAD_GAIN 0.4
#define SURFACE_CACHE 2

// The looting pose (fnc_poseStart, fnc_poseCheck, fnc_poseEnd). A crate whose top is less than LOW_TARGET metres
// above the player's feet is looted kneeling. Moved more than POSE_LEASH metres from where the window opened, the
// player has left the loot. A pose not reached within POSE_REACH_TIME seconds is someone else's turn; after a
// weapon change it comes back POSE_REENTRIES times at most. Closed by a key tap that moved nothing, the soldier
// stands up after POSE_MOVE_GRACE seconds. Movement keys count only MOVE_GRACE seconds after the window opened.
#define LOW_TARGET 0.6
#define POSE_LEASH 1.5
#define POSE_REACH_TIME 2.5
#define POSE_REENTRIES 3
#define POSE_MOVE_GRACE 0.6
#define MOVE_GRACE 0.5

// The weapon after the pose (fnc_poseEnd, fnc_raiseWeapon): one he held raised when the window opened and finds
// lowered once out of the pose is raised again - looked at every POSE_RAISE_STEP seconds, POSE_RAISE_TRIES times
// at most, while he is still bent over his gear or a reload runs. A reload in the window (fnc_reloadGesture)
// steps out of the pose and keeps it away for RELOAD_HOLD seconds, the length of a rifle's reload gesture; the
// gesture waits RELOAD_STEP_OUT seconds at most for him to be out of the pose.
#define POSE_RAISE_STEP 0.25
#define POSE_RAISE_TRIES 20
#define RELOAD_HOLD 3
#define RELOAD_STEP_OUT 1.5
#define MOVE_ACTIONS ["MoveForward", "MoveBack", "TurnLeft", "TurnRight", "MoveLeft", "MoveRight", "MoveFastForward", "MoveSlowForward", "EvasiveLeft", "EvasiveRight"]

// Textures, drawn by tools/generate_ui_textures.py
#define UI_TEX(NAME) QPATHTOF(ui\NAME.paa)

// The silhouettes of empty equipment slots are Arma's own, from its vanilla inventory: players know
// them, and they match the game's items better than anything drawn for this mod.
#define GEAR_ICON(NAME) QUOTE(\A3\ui_f\data\GUI\Rsc\RscDisplayGear\NAME.paa)

// What the config classes start with. Every control gets its real colours from the theme.
#define C_CLEAR         {0, 0, 0, 0}
#define C_WHITE         {1, 1, 1, 1}
#define C_TOOLTIP_TEXT  {1, 1, 1, 1}
#define C_TOOLTIP_BOX   {1, 1, 1, 0.1}
#define C_TOOLTIP_SHADE {0.03, 0.03, 0.03, 0.97}

// ---------------------------------------------------------------------------
// Screen geometry, relative to the safezone so it scales with the UI size. The window takes the whole
// screen; the looks share its frame and lay out the content between header and footer themselves:
//
//    0.6 -  2.2   header: title, camera, Close                           (in UNITs from the top)
//    3.0 - 37.4   content: whatever the look draws
//   38.0 - 39.4   footer: key hints, the hint, the version
// ---------------------------------------------------------------------------

// One row, ~27 px at 1080p whatever the UI size.
#define UNIT (safezoneH / 40)

// The width of something square that is H high, whatever the screen's shape - and the other way round.
#define SQUARE(H) ((H) * pixelW / pixelH)
#define UNSQUARE(W) ((W) * pixelH / pixelW)

// On the screen's pixels: an edge on the nearest one, a length in whole ones. Much of every look is
// see-through, so its pieces must meet exactly - an overlap would show as a darker line, a gap as a
// lighter one.
#define SNAP_X(V) (safezoneX + round(((V) - safezoneX) / pixelW) * pixelW)
#define SNAP_Y(V) (safezoneY + round(((V) - safezoneY) / pixelH) * pixelH)
#define SNAP_W(V) (floor((V) / pixelW) * pixelW)
#define SNAP_H(V) (floor((V) / pixelH) * pixelH)

#define MARGIN_X (SQUARE(UNIT * 1.2))

#define HEAD_Y (safezoneY + UNIT * 0.6)
#define HEAD_H (UNIT * 1.6)

#define CONTENT_X (safezoneX + MARGIN_X)
#define CONTENT_W (safezoneW - MARGIN_X * 2)
#define CONTENT_Y (safezoneY + UNIT * 3)
#define CONTENT_B (safezoneY + safezoneH - UNIT * 2.6)
#define CONTENT_H (CONTENT_B - CONTENT_Y)

#define FOOT_Y (safezoneY + safezoneH - UNIT * 2)
#define FOOT_H (UNIT * 1.4)

// The scroll bar of a scrolling column (EINV_ScrollGroup). A plain number: the engine reads it from
// config as it is.
#define SCROLL_W 0.006

// A storage column for cells CELLW wide (fnc_layoutGlass): the container's picture box and its compartments
// beside it (STORAGE_COLS + 3 cells), the column's padding - the right one wide enough for the scroll bar -
// and a little air; the gap between two columns. fnc_getCell sizes the player's tile scale by them.
#define COLUMN_PAD_X SQUARE(UNIT * 0.4)
#define COLUMN_W(CELLW) ((STORAGE_COLS + 3) * (CELLW) + SQUARE(UNIT * 0.35) + ((COLUMN_PAD_X * 2) max (COLUMN_PAD_X + SCROLL_W + pixelW * 4)) + SQUARE(UNIT * 0.6))
#define COLUMN_GAP SQUARE(UNIT * 0.8)

// The least of the equipment column, in UNITs, that a larger tile scale leaves beside the storage and loot
// columns (fnc_getCell) - about what it gets at 4:3 with the scale at 1.
#define CELL_FIT_LEFT 16

// The tile scale's limits (einv_gui_cellScale), a share of the cell fnc_getCell works out.
#define CELL_SCALE_MIN 0.8
#define CELL_SCALE_MAX 1.3

// The room between two compartments of a container, a share of a cell rounded to whole pixels: between
// blocks that flow side by side or one under another (fnc_flowCompartments).
#define COMPARTMENT_GAP 0.22

// Where two compartments of a canvas touch (grid=aab/acc), the drawing opens up between them: a column
// boundary at which some row has cells of two different compartments on its two sides, and a row boundary
// at which some column has, gets this much more room, a share of a cell rounded to whole pixels (across for
// a column boundary, down for a row boundary). Everything beyond it moves on by that much, so the
// compartments keep where they were painted relative to each other and every cell keeps its size and the
// plain gap to the next; a boundary where a compartment meets an empty place gets none (fnc_flowCompartments).
// The same room as between two flowed blocks: the wizard writes a painted drawing the flow can make as
// flowed blocks (einv_setup_fnc_canvasBlocks), and it must look like one it cannot.
#define SEAM_GAP COMPARTMENT_GAP

// The panel behind each compartment's cells (fnc_drawCompartments): how far it reaches past them, a share of
// a cell rounded to whole pixels, at least one. Its corners are round up to three times that, so the corner
// cells stay inside the round. COMPARTMENT_PAD_PX gives it in pixels for a cell CELLW wide.
#define COMPARTMENT_PAD 0.06
#define COMPARTMENT_PAD_PX(CELLW) ((round ((CELLW) * COMPARTMENT_PAD / pixelW)) max 1)

// ---------------------------------------------------------------------------
// The live camera on the player's soldier (fnc_cameraStart). Starting values - tuned in the game.
// ---------------------------------------------------------------------------

// How far in front of the soldier it stands, in metres, and how close a wall may pull it in.
#define CAMERA_DISTANCE     2.5
#define CAMERA_MIN_DISTANCE 0.9

// How far it stays off a wall it was pulled in front of, in metres.
#define CAMERA_WALL_GAP 0.25

// Its zoom (camSetFov). The soldier is placed on the screen as if this were the tangent of half the
// view's height; should the soldier land off the middle of the look's free space, CAMERA_FOV_SCALE
// corrects that assumption without changing the zoom.
#define CAMERA_FOV       0.7
#define CAMERA_FOV_SCALE 1

// The chest's height in the soldier's model when its bones cannot be read, in metres.
#define CAMERA_CHEST_Z 1.3

// The light it brings along at night: weak, so the soldier is seen but the night stays night.
#define CAMERA_LIGHT_BRIGHTNESS 0.2
#define CAMERA_LIGHT_SUN        0.5
