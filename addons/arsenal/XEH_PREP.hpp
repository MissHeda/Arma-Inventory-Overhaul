// Arsenal boxes: telling them apart, opening one from the inventory window
PREP(isArsenalBox);
PREP(canOpen);
PREP(open);

// Adding in ACE's own window: what has no room on the grid comes back out
PREP(getCargo);
PREP(rememberCargo);
PREP(onCargoChanged);

// Whole loadouts in ACE's own window: telling the player what does not fit
PREP(checkOverflow);
PREP(reportOverflow);

// The session: opening, handing over from ACE's display, closing, Eden, the window's hooks, keys, header
PREP(openWindow);
PREP(handOver);
PREP(open3DEN);
PREP(onLoad);
PREP(onUnload);
PREP(sessionStart);
PREP(readSupply);
PREP(sessionEnd);
PREP(edenStart);
PREP(edenEnd);
PREP(hooks);
PREP(keepOpen);
PREP(theme);
PREP(context);
PREP(drawHeader);
PREP(footerKeys);
PREP(onKey);
PREP(toggleHidden);
PREP(onFrame);
PREP(afterBuild);
PREP(onBoxRefresh);
PREP(onBoxRemoved);
PREP(compatCheck);
PREP(close);
PREP(openAce);
PREP(isOpen);
PREP(message);

// The camera round the soldier and its mouse
PREP(cameraStart);
PREP(cameraStop);
PREP(cameraFrame);
PREP(cameraRect);
PREP(cameraReset);
PREP(onMouseDown);
PREP(onMouseUp);
PREP(onWheel);

// The catalog: categories, rows, the list shown, the column and its cards
PREP(layout);
PREP(drawColumn);
PREP(drawCatalogBar);
PREP(drawCatalog);
PREP(bindCatalog);
PREP(categories);
PREP(categoryForSlot);
PREP(catalogRow);
PREP(catalogList);
PREP(catalogFrame);
PREP(catalogWheel);
PREP(showCategory);
PREP(refreshCatalog);
PREP(onFilter);
PREP(carriedCounts);
PREP(toggleFavorite);
PREP(openChoices);

// Adding and equipping: dropping, quick adds, swaps, trimming to the grid
PREP(onDrop);
PREP(dragCheck);
PREP(addItem);
PREP(quickAdd);
PREP(equipItem);
PREP(swapWeapon);
PREP(swapContainer);
PREP(storeAway);
PREP(trimToFit);
PREP(fill);
PREP(stepCount);

// Giving back, clicks, menus and marks
PREP(onClick);
PREP(onSlotClick);
PREP(menu);
PREP(giveBack);
PREP(giveBackAll);
PREP(emptyContainer);
PREP(freeKits);
PREP(isUnique);
PREP(arm);
PREP(tileBadge);
PREP(hintParts);
PREP(drawTargets);
PREP(aceCargoEvent);
PREP(weaponEvents);
PREP(applyIdentity);
PREP(copyClass);

// Loadouts: the view, saving and loading, the clipboard
PREP(drawLoadouts);
PREP(loadoutsData);
PREP(loadoutsFrame);
PREP(verifyStep);
PREP(loadoutSave);
PREP(loadoutLoad);
PREP(loadoutRename);
PREP(loadoutDelete);
PREP(loadoutShare);
PREP(loadoutCopy);
PREP(loadoutMakeDefault);
PREP(loadoutImport);
PREP(loadoutExport);
PREP(applyLoadout);
PREP(clipboardRead);
PREP(clipboardWrite);
PREP(onSubmit);

// The vanilla Virtual Arsenal: the wrapper's helpers, the block screen, the safety net
PREP(biInit);
PREP(biCountHandlers);
PREP(biMissionHooks);
PREP(handleBIOpen);
PREP(biItems);
PREP(isBIBox);
PREP(canOpenBI);
PREP(showBlocked);
PREP(onBlockedLoad);
PREP(onBlockedKey);
PREP(biSafetyNet);
PREP(biLeaveAlone);
PREP(checkBIOverride);

// The inspect card's rows, and what ACE adds to the catalog's sorts and the slots' menus
PREP(inspectRows);
PREP(aceSorts);
PREP(aceActions);

// The soldier on show, the view, the way over from ACE's window and out of Arsenal.VR, ACRE's notifications
PREP(cycleVision);
PREP(showItem);
PREP(aceButton);
PREP(leaveVR);
PREP(acreDisplay);
