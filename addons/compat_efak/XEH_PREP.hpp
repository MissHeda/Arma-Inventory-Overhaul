// What a kit is, what it is called and what it weighs
PREP(isKit);
PREP(getName);
PREP(getMass);
PREP(hintParts);
PREP(inspectRows);
PREP(hideCbaOption);

// A kit's room: that mod's capacity, or the cells of a grid a rule or its config gives it
PREP(roomMode);
PREP(capacity);
PREP(kitBlocks);
PREP(hasCells);
PREP(cellFree);
PREP(fillState);

// Kits in windows of their own inside the inventory
PREP(onWindowOpen);
PREP(getSections);
PREP(kitSection);
PREP(discard);
PREP(arsenalSections);
PREP(getEntries);
PREP(toggle);
PREP(open);
PREP(close);
PREP(canOpen);
PREP(mayReach);
PREP(menuChoices);
PREP(signature);
PREP(requestRebuild);

// Moving into and out of kits
PREP(canDrop);
PREP(canPack);
PREP(canPackNew);
PREP(packNew);
PREP(contains);
PREP(snapshot);
PREP(repackable);
PREP(drop);
PREP(changeKit);
PREP(equip);
PREP(takeOut);
PREP(unpackAll);
PREP(removeIfEmpty);
PREP(takeRounds);
PREP(payloadFor);
PREP(ownTargets);

// Kits in the storage's transactions: where a kit's root is, and its ops, run by that root's authority
// (einv_storage_ops, einv_storage_holderTypes "kit")
PREP(holderRoot);
PREP(holderVerify);
PREP(opKitTake);
PREP(opKitPut);
PREP(opKitPlace);
PREP(opKitMove);
PREP(opKitRemoveIfEmpty);

// Where a kit lies, and moving things into and out of it where it is written
PREP(isPlayerGear);
PREP(locate);
PREP(takeFromKit);
PREP(putIntoKit);
PREP(notReady);

// A living person's gear: kits in it and their containers change as the window's settings for them say,
// on the machine where the person is local (einv_gui_fnc_personGuard)
PREP(checkTouch);
PREP(checkTile);
