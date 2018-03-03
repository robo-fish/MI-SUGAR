/***************************************************************************
*
*   Copyright Kai Özer, 2003-2018
*
*   This file is part of MI-SUGAR.
*
*   MI-SUGAR is free software; you can redistribute it and/or modify
*   it under the terms of the GNU General Public License as published by
*   the Free Software Foundation; either version 2 of the License, or
*   (at your option) any later version.
*
*   MI-SUGAR is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License
*   along with MI-SUGAR; if not, write to the Free Software Foundation, Inc.,
*   51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*
****************************************************************************/
#import <Cocoa/Cocoa.h>
#import "CircuitDocumentModel.h"
#import "MI_TextView.h"
#import "MI_Window.h"
#import "MI_SchematicsCanvas.h"
#import "MI_Schematic.h"
#import "MI_VariantSelectionView.h"
#import "MI_AnalysisButton.h"
#import "MI_CustomViewToolbarItem.h"
#import "MI_FitToViewButton.h"

@class MI_SchematicsCanvas;


@interface CircuitDocument : NSDocument <MI_DropHandler>

- (void) processDrop:(id <NSDraggingInfo>)sender;

- (IBAction) runSimulator:(id)sender; // creates the simulation thread and waits for output

- (void) simulationOutputAvailable:(NSNotification*)aNotification;

- (void) endSimulation:(NSNotification*)aNotification;

- (IBAction) abortSimulation:(id)sender;

- (IBAction) plotResults:(id)sender;

- (IBAction) convertSchematicToNetlist:(id)sender;

- (void) makeSubcircuit; // prompts the user for information to convert the circuit to a subcircuit

@property (nonatomic) CircuitDocumentModel* model;

/* Checks the model and sets the contents of the text views */
- (void) updateViews;

- (void) setFont:(NSNotification*)notification;

/* AppleScript commands */
- (id) analyze_scriptCommand:(NSScriptCommand*)command;
- (id) export_scriptCommand:(NSScriptCommand*)command;
- (id) plot_scriptCommand:(NSScriptCommand*)command;

// Exports analysis results to file.
// The following file format are supported: MathML, Matlab, Tabular.
- (void) export:(NSString*)format
         toFile:(NSString*)filename;

/* to validate the "Export to MathML..." menu item */
- (BOOL) validateMenuItem:(NSMenuItem*)item;

- (void) highlightInput;

- (void) setFileTypeAccordingToPolicy;

- (void) markWindowContentAsModified:(BOOL)modified;

- (NSTextView*) netlistEditor; // returns the netlist viewer/editor widget

- (NSTextView*) analysisResultViewer; // the widget which shows the analysis results

// SCHEMATIC - RELATED *******************************************
- (MI_SchematicsCanvas*) canvas;
- (IBAction) setCanvasScale:(id)sender;
- (void) scaleShouldChange:(float)newScale; // called by the schematic canvas
- (IBAction) zoomInCanvas:(id)sender;
- (IBAction) zoomOutCanvas:(id)sender;
- (IBAction) showPlacementGuides:(id)sender;
- (void) placementGuideVisibilityChanged:(NSNotification*)notif;
- (IBAction) moveSchematicViewportToOrigin:(id)sender;
- (void) toggleDetailsView;
- (IBAction) fitSchematicToView:(id)sender;

// Called AFTER the schematic is modified. Updates the 'edited' status.
- (void) processSchematicChange:(NSNotification*)notification;

// Should be called BEFORE the schematic is modified.
// Registers the current state of the schematic with the undo manager.
- (void) createSchematicUndoPointForModificationType:(NSString*)type;

// Used in the undo mechanism to restore a previous state of the schematic.
// Brute force & easy approach: Archive the whole schematic instead of the changes.
- (void) restoreSchematic:(NSData*)archivedSchematic;

// Switches to given schematic variants
- (void) switchToSchematicVariant:(NSNumber*)variant;

// Copies given schematic to given variant.
// The array has two elements:
// 0 -> the MI_CircuitSchematic object that will be copied
// 1 -> the variant into which to copy
- (void) copySchematicToVariant:(NSArray*)schematicAndvariant;

//*****************************************************************

@end
