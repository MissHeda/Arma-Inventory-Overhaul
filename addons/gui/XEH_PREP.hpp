// Taking over from the vanilla inventory
PREP(initUnit);
PREP(onInventoryOpened);
PREP(openVanilla);

// Living persons: the scroll action, who may do what, and their gear changed where they are local
PREP(addPersonAction);
PREP(personActionCondition);
PREP(addAgentAction);
PREP(agentActionCondition);
PREP(openPerson);
PREP(canOpenPerson);
PREP(isHelpless);
PREP(canTouchPerson);
PREP(checkTouch);
PREP(personOf);
PREP(personInReach);
PREP(notifyPerson);
PREP(personGuard);

// The window: opening, building, closing, following the mouse
PREP(open);
PREP(attach);
PREP(startFrame);
PREP(stopFrame);
PREP(build);
PREP(onUnload);
PREP(onKeyDown);
PREP(onFrame);
PREP(updateHover);
PREP(getSignature);
PREP(requestRebuild);
PREP(isCovered);
PREP(isInventoryMode);
PREP(later);
PREP(hook);
PREP(showHint);
PREP(readNearby);
PREP(redrawTiles);

// Moving items with the mouse and keys
PREP(onMouseButton);
PREP(startDrag);
PREP(updateDrag);
PREP(endDrag);
PREP(makeGhost);
PREP(rotateDrag);
PREP(onMouseZ);
PREP(quickMove);
PREP(dropToGround);
PREP(applyMove);
PREP(afterAction);
PREP(quickEquip);
PREP(quickUnequip);

// Moves as transactions: sent, shown under way, answered, and drift reported to the authorities
PREP(sendMoves);
PREP(sendPlan);
PREP(onAnswer);
PREP(drawPending);
PREP(requestNormalize);

// Selecting several: click, Ctrl, Shift and a frame, moved together, Take all and Put all in
PREP(select);
PREP(selectSection);
PREP(clearSelection);
PREP(selectionTiles);
PREP(drawSelection);
PREP(startBand);
PREP(updateBand);
PREP(endBand);
PREP(groupMode);
PREP(quickMoveGroup);
PREP(takeAll);
PREP(putAll);
PREP(putAllTarget);

// The context menu
PREP(openMenu);
PREP(closeMenu);
PREP(contextMenu);
PREP(containerName);
PREP(flashHint);
PREP(doEquip);
PREP(doUnequip);
PREP(canSwap);
PREP(doSwap);
PREP(isShared);
PREP(itemName);

// The CBA item context menu: other mods' choices for an item, in this window's menu
PREP(cbaTileTarget);
PREP(cbaSlotTarget);
PREP(cbaOptions);
PREP(cbaRun);

// Searching loot
PREP(isSearched);
PREP(markHidden);
PREP(learn);
PREP(findTile);
PREP(boxTile);
PREP(showSearch);
PREP(revealTile);
PREP(animateSearch);
PREP(revealFx);
PREP(flashTile);
PREP(openNested);
PREP(playSound);
PREP(drawFilter);
PREP(applyFilter);
PREP(matchesFilter);
PREP(showTargets);
PREP(inspect);
PREP(drawInspect);
PREP(closeInspect);
PREP(toggleSection);
PREP(toggleRows);
PREP(closeNested);
PREP(toggleSearchSound);

// The feel: every kind of gear sounds like itself, others hear the looting, and the soldier looks into his gear
PREP(soundFamily);
PREP(containerFamily);
PREP(soundDef);
PREP(resolveLayers);
PREP(playLayer);
PREP(delay);
PREP(groundSurface);
PREP(soundFile);
PREP(reloadSound);
PREP(playReload);
PREP(sendNoise);
PREP(onNoise);
PREP(feelFor);
PREP(feelAnswer);
PREP(canPose);
PREP(isPoseAnim);
PREP(poseState);
PREP(restState);
PREP(isLowTarget);
PREP(poseStart);
PREP(poseCheck);
PREP(poseEnd);
PREP(gesture);

// Styles and the camera
PREP(themeBase);
PREP(toggleCamera);
PREP(cameraStart);
PREP(cameraStop);

// Weight: what lifting something previews on the weight card, the words for what a pick-up makes of the
// soldier, and the comparison of a vest, uniform, helmet or backpack with the one worn
PREP(previewWeight);
PREP(clearWeightPreview);
PREP(weightText);
PREP(weightColor);
PREP(dragHint);
PREP(infoHint);
PREP(isOwnStorage);
PREP(compareRows);
PREP(drawCompare);

// UI kit
PREP(uiCreate);
PREP(uiPanel);
PREP(uiLabel);
PREP(uiIcon);
PREP(uiPicture);
PREP(safePicture);
PREP(uiFrame);
PREP(uiShape);
PREP(shapeRects);
PREP(uiRing);
PREP(uiPictureTurned);
PREP(uiPictureRounded);
PREP(uiBar);
PREP(uiButton);
PREP(uiKeyHint);
PREP(uiHatch);
PREP(caption);
PREP(fitText);

// Grids and tiles
PREP(getCell);
PREP(createGrid);
PREP(createTile);
PREP(drawTiles);
PREP(loadText);
PREP(drawAttachments);
PREP(gridOrigin);
PREP(slotRect);
PREP(screenToCell);
PREP(spanRect);
PREP(spanInsets);
PREP(hitsHole);
PREP(tileAt);

// Building blocks the layouts share
PREP(drawSlot);
PREP(drawCountBackdrop);
PREP(drawColumn);
PREP(drawHeader);
PREP(drawFooter);

// Floating windows: open kits and pouches
PREP(flowCompartments);
PREP(canvasInsets);
PREP(viewBlocks);
PREP(drawCompartments);
PREP(scrollPixels);
PREP(drawWindows);
PREP(drawWindow);
PREP(clearWindows);
PREP(drawTopLayer);
PREP(openWindow);
PREP(closeWindow);
PREP(raiseWindow);
PREP(placeWindow);
PREP(topAt);
PREP(tileRect);


// The look: Enhanced First Aid Kits' glass, the equipment as cards with every attachment slot
PREP(theme);
PREP(layoutGlass);
PREP(drawEquipmentCards);
PREP(drawEquipmentDoll);
PREP(drawSection);

// Other mods' answers and dialogs: the radios of TFAR and ACRE2 ask the same questions, and open dialogs the window
// cannot stay open over
PREP(compatCollect);
PREP(stepAside);
