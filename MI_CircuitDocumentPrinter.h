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

// Used to draw a preview for the printout of the schematic.
// Enables user to resize and move the schematic bounding box
// via mouse actions.
@interface MI_CircuitPrintPreview : NSView
{
    NSPoint schematicCenterPoint;
    NSSize schematicSize;
    BOOL isDragging;
}
@end

// This class is responsible for getting print settings
// from the user and printing the schematic and/or netlist.
// There is a single instance which is handed over the
// circuit document to be printed. The print info is then
// edited according to user input and the print operation
// is finally created when the user accepts the settings (commit).
@interface MI_CircuitDocumentPrinter : NSObject
{
    IBOutlet NSWindow* circuitPrintOptionsSheet;
    IBOutlet MI_CircuitPrintPreview* previewer;
    IBOutlet NSButton* commitButton;
    IBOutlet NSButton* schematicSelectionButton;
    IBOutlet NSButton* netlistSelectionButton;
    IBOutlet NSButton* analysisResultSelectionButton;
    IBOutlet NSSlider* schematicScaler;
}
// Returns a shared instance of the singleton printer
+ (MI_CircuitDocumentPrinter*) sharedPrinter;

// Presents print options to the user.
// Called by an instance of CircuitDocument in response to a print request.
- (void) runPrintSheetForCircuit:(CircuitDocument*)circuit;

// Completes the task by creating a print job according to
// user selections
- (IBAction) commit:(id)sender;

// This is called by the buttons which the user selects selects the type
// of print output with. Possible types are schematic and netlist.
// The type is selected according to the sender of this message.
- (IBAction) selectViewForPrinting:(id)sender;

// This is called when the user sect either portrait or landscape orientation
- (IBAction) selectPortraitOrLandscape:(id)sender;

- (IBAction) setScaleOfSchematic:(id)sender;

@end
