#define COMPONENT compat_ace_cargo
#define COMPONENT_BEAUTIFIED AIO - ACE Cargo
#include "\z\aio\addons\main\script_mod.hpp"
#include "\z\aio\addons\main\script_macros.hpp"

// The window's measures, copied from gui/defines.hpp under the same names: the cargo section is laid out
// beside the blocks aio_gui_fnc_drawSection draws, so it must use the same units.
#define UNIT (safezoneH / 40)
#define SQUARE(H) ((H) * pixelW / pixelH)
#define TEXT_SLACK 1.3
// The caption line and its pill tab (fnc_drawSection there): the line's height and the tab's text size in TEXT_UNITs, and
// where a line of capitals sits in its box.
#define CAPTION_LINE 0.8
#define TEXT_REF 0.42
#define TEXT_MID 0.66

// The window's words grow with its tiles (aio_gui_fnc_textScale, TEXT_UNIT in gui/defines.hpp): the cards' texts and
// the rows that hold them are measured in it, as the sections above them are.
#define TEXT_UNIT (UNIT * (call aio_gui_fnc_textScale))

// ACE's own number: how close the player has to be to a vehicle to unload it (MAX_LOAD_DISTANCE in
// ace_cargo's script_component.hpp, ACE 3.21.2).
#define MAX_LOAD_DISTANCE 5

// A picture of the gui addon (the unload icon is made by the generator in tools/generate_ui_textures.py).
#define GUI_TEX(NAME) QUOTE(\z\aio\addons\gui\ui\NAME.paa)
