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
#import "CircuitDocument.h"
#import "MI_ShapePreviewer.h"

// A singleton object which manages the task of creating new subcircuits.
@interface MI_SubcircuitCreator : NSObject
{
    IBOutlet NSTableView* pinAssignmentTable;       // displays the pin to node assignment matrix
    IBOutlet NSTableColumn* nodeNameColumn;         // will be populated with popup button cells
    IBOutlet NSTextField* subcircuitNameField;      // for entering the name of the subcircuit
    IBOutlet NSTextField* subcircuitNamespaceField; // for entering the namespace of the subcircuit
    IBOutlet NSTextField* revisionField;            // for entering the revision of the subcircuit
    IBOutlet NSWindow* creatorSheet;                // the panel which contains the widgets
    IBOutlet NSPopUpButton* pinChooser;             // presents choice of number of pins
    IBOutlet NSButton* createButton;                // user presses this button to finalize creation
    IBOutlet MI_ShapePreviewer* shapePreviewer;
    IBOutlet NSButton* dipShapeSelectionButton;
    IBOutlet NSButton* customShapeSelectionButton;
    IBOutlet NSButton* customShapeFileBrowseButton;
    BOOL usesCustomShape;
    NSPopUpButtonCell* nodeNameChooser;             // cell object in the node name column
    int numberOfConnectionPoints;                   // the number of pins of the selected shape
    CircuitDocument* currentDoc;
    NSMutableDictionary* pinMapping;                // maps external port names to internal node names
    NSMutableArray* customShapeConnectionPointNames;
}
+ (MI_SubcircuitCreator*) sharedCreator;

// Creates a subcircuit based on given CircuitDocument
// Returns YES if successful, NO otherwise.
- (void) createSubcircuitForCircuitDocument:(CircuitDocument*)doc;

// Called when the user is done with the creation sheet
- (IBAction) finishUserInput:(id)sender;

// Called when the user chooses the number of pins for the DIP shape
- (IBAction) setNumberOfDIPPins:(id)sender;

- (void) setNumberOfConnectionPoints:(int)number;

- (IBAction) loadShapeDefinitionFile:(id)sender;

// Convenience method which initializes the pin assignment matrix
// according to the number of pins.
- (void) resetPinMapping;

// Called when the user sets the node name assigned to a pin
- (IBAction) setNodeNameForPin:(id)sender;

- (IBAction) selectShapeType:(id)sender;

@end
