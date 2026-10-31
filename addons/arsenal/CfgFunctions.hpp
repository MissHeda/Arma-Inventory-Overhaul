// The vanilla Virtual Arsenal's function, BIS_fnc_arsenal, with "Open" asked first whether this mod takes it
// (aio_arsenal_fnc_handleBIOpen) - see functions\fnc_biArsenal.inc.sqf. BI's library loads that file in
// place of its own. Everything but "Open" runs BI's code untouched.
class CfgFunctions {
    class A3_Bootcamp {
        class Inventory {
            class arsenal {
                // The leading backslash is required: BI's function library ignores a custom file for a BIS
                // function unless its path starts with one or with a3 (functions_f\initFunctions.sqf:352-357).
                file = QPATHTOF(functions\fnc_biArsenal.inc.sqf);
            };
        };
    };
};
