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

+ (MI_SubcircuitCreator*) sharedCreator;

// Creates a subcircuit based on given CircuitDocument
// Returns YES if successful, NO otherwise.
- (void) createSubcircuitForCircuitDocument:(CircuitDocument*)doc;

// Called when the user is done with the creation sheet
- (IBAction) finishUserInput:(id)sender;

// Called when the user chooses the number of pins for the DIP shape
- (IBAction) setNumberOfDIPPins:(id)sender;

- (void) setNumberOfConnectionPoints:(NSInteger)number;

- (IBAction) loadShapeDefinitionFile:(id)sender;

// Convenience method which initializes the pin assignment matrix
// according to the number of pins.
- (void) resetPinMapping;

// Called when the user sets the node name assigned to a pin
- (IBAction) setNodeNameForPin:(id)sender;

- (IBAction) selectShapeType:(id)sender;

@end
