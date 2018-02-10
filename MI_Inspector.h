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
#import "MI_SchematicElement.h"
#import "MI_DirectionChooser.h"

// Click-through widgets for easier editing
@interface MI_ClickThroughTextField : NSTextField {} @end
@interface MI_ClickThroughTableView : NSTableView {} @end

// this custom table column is used to show a popup button for the "Model" parameter of an element
@interface MI_DeviceModelAwareInspectionTableColumn : NSTableColumn {} @end

// This is a singleton controller object. It's responsible for showing
// information about inspected objects. Depending on the inspected element
// it chooses a suitable inspection view from its palette of views and
// uses that view in the info panel to present the inspected element to
// the user.
@interface MI_Inspector : NSObject <NSWindowDelegate>
{
    // Common fields
    IBOutlet NSPanel* infoPanel;
    IBOutlet NSSlider* infoPanelTransparencyAdjustment;
    IBOutlet MI_ClickThroughTextField* labelField;
    IBOutlet NSTextField* elementNameField;
    IBOutlet NSTextField* revisionField;
    IBOutlet NSTextField* commentArea;
    IBOutlet NSTabView* inspectionViewContainer;
    IBOutlet MI_DirectionChooser* labelPositionChooser;

    // fields specific to the inspected element
    IBOutlet MI_ClickThroughTableView* analysisTasksTable;
    IBOutlet MI_ClickThroughTableView* circuitElementInspectionView;
    IBOutlet MI_DeviceModelAwareInspectionTableColumn* circuitInspectionValueColumn;
    IBOutlet NSTableView* subcircuitElementInspectionView;
    IBOutlet NSTextField* subcircuitNamespaceField;
    IBOutlet NSColorWell* textColorChooser; // for MI_TextElement
    IBOutlet NSButton* textFontChooser; // for MI_TextElement
    IBOutlet NSButton* textFrameSetter; // for MI_TextElement
    
    NSView* currentInspectionView;

    // the currently inspected element
    MI_SchematicElement* inspectedElement;
    
    // The currently edited element
    // Normally this object and the inspectedElement should be the same
    // but if the inspectedElement is set to point to another element
    // while editing is still going on then we have to resolve this problem.
    MI_SchematicElement* editedElement;
}
// Puts the inspection view of the inspected object into the info panel.
- (void) inspectElement:(NSObject <MI_Inspectable>*)inspectable;

// Allows the user to simultaneously set the properties of multiple elements
- (void) inspectElements:(NSArray*)elements;

+ (MI_Inspector*) sharedInspector; // returns the singleton object

// Constructs info panel if it doesn't exist already and shows it.
- (void) showInfoPanel;
- (void) hideInfoPanel;
- (void) toggleInfoPanel;

// Sets the label of the element that's currently shown in the info panel.
- (IBAction) setLabelOfInspectedElement:(id)sender;

// adjusts info panel transparency
- (IBAction) setInfoPanelTransparency:(id)sender;

// Method for use when inspecting circuit elements with model parameter.
// Called when the selection in the popup button changes.
- (IBAction) assignNewModel:(id)sender;

// clears all inspection views - for internal use
- (void) reset;

- (IBAction) setComment:(id)sender;

- (IBAction) setTextColor:(id)sender;

- (IBAction) setTextFont:(id)sender;

- (IBAction) toggleTextFrame:(id)sender;

- (IBAction) rotateSelectionCCW:(id)sender;                 // adds 90 degrees to the selected elements' rotation

- (IBAction) flipHorizontally:(id)sender;                   // flips selected elements

- (void) setLabelPosition:(MI_DirectionChooser*)chooser;    // sets the label position of the selected elements

@end
