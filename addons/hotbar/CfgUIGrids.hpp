// The bar can be moved in Arma's layout editor (Options > Game > Layout). The editor keeps the place in
// the profile as IGUI_einv_hotbar_grid_X and _Y, which the bar reads (HUD_X, HUD_Y). Only the position
// is saved - the size follows the interface size.
class CfgUIGrids {
    class IGUI {
        class Presets {
            class Arma3 {
                class Variables {
                    GVAR(grid)[] = {{QUOTE(HUD_DEFAULT_X), QUOTE(HUD_DEFAULT_Y), QUOTE(HUD_W), QUOTE(HUD_H)}, QUOTE(GUI_GRID_W), QUOTE(GUI_GRID_H)};
                };
            };
        };

        class Variables {
            class GVAR(grid) {
                displayName = CSTRING(IGUI_Name);
                description = CSTRING(IGUI_Description);
                preview = "#(argb,8,8,3)color(0,0,0,0.5)";
                saveToProfile[] = {0, 1};
                canResize = 0;
            };
        };
    };
};
