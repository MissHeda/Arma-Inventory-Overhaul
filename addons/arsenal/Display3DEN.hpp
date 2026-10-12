class ctrlMenu;

// Eden's Arsenal submenu on a unit: the Enhanced Arsenal first, ACE's and BI's own after it. ACE turned BI's
// single entry into this submenu; this list replaces ACE's, which loads first.
class Display3DEN {
    class ContextMenu: ctrlMenu {
        class Items {
            class Arsenal {
                items[] = {"einv_arsenal_enhanced", "aceArsenal", "virtualArsenal"};
            };
            class virtualArsenal;
            class einv_arsenal_enhanced: virtualArsenal {
                text = "$STR_einv_arsenal_Eden_Enhanced";
                action = "call (missionNamespace getVariable ['einv_arsenal_fnc_open3DEN', {}])";
            };
        };
    };
};
