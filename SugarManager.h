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
#include "common.h"
#import "MI_CircuitElement.h"
#import "MI_SchematicElementChooser.h"
#import "MI_SelectConnectTool.h"
#import "MI_ScaleTool.h"
#import "MI_SubcircuitLibraryManager.h"
#import "MI_Inspector.h"


@interface SugarManager : NSWindowController <NSWindowDelegate>
{
    IBOutlet NSTextField* customSimulatorField;             // "SugarPreferences.nib"
    IBOutlet NSButton* customSimulatorBrowseButton;         // "SugarPreferences.nib"
    IBOutlet NSButtonCell* useSPICEButton;                  // "SugarPreferences.nib"
    IBOutlet NSButtonCell* useCustomSimulatorButton;        // "SugarPreferences.nib"
    IBOutlet NSPanel* preferencesPanel;                     // "SugarPreferences.nib"
    IBOutlet NSWindow* aboutPanel;                          // "About.nib"
    IBOutlet NSTextField* sourceFontNameField;              // "SugarPreferences.nib"
    IBOutlet NSTextField* rawOutputFontNameField;           // "SugarPreferences.nib"
    IBOutlet NSButton* lookForUpdateAtStartupButton;        // "SugarPreferences.nib"
    IBOutlet NSButton* lookForUpdateButton;                 // "SugarPreferences.nib"
    IBOutlet NSButton* showUntitledDocumentAtStartupButton; // "SugarPreferences.nib"
    IBOutlet NSTextField* updateInfoField;                  // "SugarPreferences.nib"
    IBOutlet NSPopUpButton* plotterGraphsLineWidthChooser;  // "SugarPreferences.nib"
    IBOutlet NSPopUpButton* plotterGridLineWidthChooser;    // "SugarPreferences.nib"
    IBOutlet NSPopUpButton* plotterLabelsFontSizeChooser;   // "SugarPreferences.nib"
    IBOutlet NSColorWell* plotterBackgroundColorChooser;    // "SugarPreferences.nib"
    IBOutlet NSColorWell* plotterGridColorChooser;          // "SugarPreferences.nib"
    IBOutlet NSButton* plotterRemembersSettingsButton;      // "SugarPreferences.nib"
    IBOutlet NSButton* plotterClosesOldWindows;             // "SugarPreferences.nib"
    IBOutlet NSButton* plotterAutoShowsGuidesTab;           // "SugarPreferences.nib"
    IBOutlet NSPopUpButton* conversionPolicyChooser;        // "SugarPreferences.nib"
    IBOutlet NSPopUpButton* fileSavingPolicyChooser;        // "SugarPreferences.nib"
    IBOutlet NSPopUpButton* layoutChooser;                  // "SugarPreferences.nib"
    IBOutlet NSButton* openElementsPanelOnStartup;          // "SugarPreferences.nib"
    IBOutlet NSButton* openInfoPanelOnStartup;              // "SugarPreferences.nib"
    IBOutlet NSButton* autoInsertNodeElement;               // "SugarPreferences.nib"
    IBOutlet NSButton* showPlacementGuides;                 // "SugarPreferences.nib"
    BOOL lookForUpdateAtStartup;
    BOOL settingSourceFont;
    BOOL convertToMathML;
    BOOL settingPlotterBackgroundColor;
    BOOL settingPlotterGridColor;
    NSToolbarItem* startupPreferences;                      // for the preferences panel
    NSToolbarItem* simulatorPreferences;                    // for the preferences panel
    NSToolbarItem* fontPreferences;                         // for the preferences panel
    NSToolbarItem* plotterPreferences;                      // for the preferences panel
    NSToolbarItem* generalPreferences;                      // for the preferences panel
    NSToolbarItem* schematicPreferences;                    // for the preferences panel
    IBOutlet NSView* plotterPrefsView;                      // "SugarPreferences.nib"
    IBOutlet NSView* simulatorPrefsView;                    // "SugarPreferences.nib"
    IBOutlet NSView* fontPrefsView;                         // "SugarPreferences.nib"
    IBOutlet NSView* startupPrefsView;                      // "SugarPreferences.nib"
    IBOutlet NSView* generalPrefsView;                      // "SugarPreferences.nib"
    IBOutlet NSView* schematicPrefsView;                    // "SugarPreferences.nib"
    IBOutlet NSTextField* versionField;                     // 'About' panel
    IBOutlet NSTextField* releaseDateField;                 // 'About' panel

    // SCHEMATIC-RELATED VARIABLES
    IBOutlet NSPanel* elementsPanel;
    IBOutlet MI_SchematicElementChooser* resistorChooser;
    IBOutlet MI_SchematicElementChooser* capacitorChooser;
    IBOutlet MI_SchematicElementChooser* inductorChooser;
    IBOutlet MI_SchematicElementChooser* sourceChooser;
    IBOutlet MI_SchematicElementChooser* transistorChooser;
    IBOutlet MI_SchematicElementChooser* diodeChooser;
    IBOutlet MI_SchematicElementChooser* nodeChooser;
    IBOutlet MI_SchematicElementChooser* groundChooser;
    IBOutlet MI_SchematicElementChooser* switchChooser;
    IBOutlet MI_SchematicElementChooser* subcircuitChooser;
    IBOutlet MI_SchematicElementChooser* specialElementChooser;
    IBOutlet NSSlider* panelTransparencyAdjustment;
    IBOutlet NSOutlineView* subcircuitsTable;               // elements panel
    IBOutlet NSColorWell* schematicCanvasBackground;        // "SugarPreferences.nib"
    IBOutlet NSTextField* subcircuitLibraryPathField;       // "SugarPreferences.nib"
    IBOutlet NSTabView* elementCategoryChooser;             // the main tab view in the elements panel
    IBOutlet NSTextField* subcircuitNamespaceField;         // displays the namespace of the selected subcircuit
    MI_Tool* currentTool;                                   // current tool selected by user
    MI_ScaleTool* scaleTool;
    MI_SelectConnectTool* selectTool;                       // the default tool
    MI_SubcircuitLibraryManager* libManager;
    
    MI_Inspector* inspector;
}
+ (SugarManager*) sharedManager;    // returns the instance that controls this session
+ (NSString*) supportFolder;        // returns the user-specific folder which stores cross-session files

- (IBAction) showPreferencesPanel:(id)sender;               // display the preferences window
- (IBAction) showAboutPanel:(id)sender;                     // display the About window
- (IBAction) setCustomSimulator:(id)sender;                 // set the simulator engine to the custom one
- (IBAction) setSourceFont:(id)sender;                      // set font of netlist editor of all documents
- (IBAction) setRawOutputFont:(id)sender;                   // set font of analyisis output area of all documents
- (IBAction) setShowUntitledDocumentAtStartup:(id)sender;   // enable/disable showing an empty document on startup
- (IBAction) setLabelsFontSize:(id)sender;                  // set the size of the font of the plotter's label
- (IBAction) setGraphsLineWidth:(id)sender;                 // set the line widdth of graphs in the plotter
- (IBAction) setGridLineWidth:(id)sender;                   // set the line width of the grid of the plotter
- (IBAction) setPlotterBackgroundColor:(id)sender;          // set the background color of the plotter
- (IBAction) setPlotterGridColor:(id)sender;                // set the color of the grid of the plotter
- (void) changePlotterColors:(id)sender;
- (IBAction) setPlotterFunctionSetting:(id)sender;          // enables/disables remembering of plotter function secttings between sessions
- (IBAction) exportToMathML:(id)sender;                     // exports the analysis results of the active document to MathML
- (IBAction) exportToMatlab:(id)sender;                     // exports the analysis results of the active document to Matlab file format
- (IBAction) exportToTabularText:(id)sender;                // exports the analysis results to a text file with tab characters between numbers
- (IBAction) analyzeCircuit:(id)sender;                     // starts analysis of the netlist in the active document
- (IBAction) plotCircuitAnalysis:(id)sender;                // attempts to plot graphs based on the analysis results in the active document
- (IBAction) switchPreferenceView:(id)sender;               // function for animated transition from one preference category to another in the preference window
- (IBAction) selectSimulator:(id)sender;                    // function which sets the circuit analysis engine to be used
- (IBAction) setConversionPolicy:(id)sender;                // sets the policy for dealing with files that have incompatible line ending characters
- (IBAction) setFileSavingPolicy:(id)sender;                // sets the policy for determining the file format in which documents are saved
- (IBAction) setLayout:(id)sender;                          // sets the layout option to be used for document windows
- (IBAction) makeSubcircuit:(id)sender;                     // creates a subcircuit based on the circuit in the active document
- (IBAction) setSubcircuitLibraryFolder:(id)sender;         // for use in the preferences panel
- (IBAction) goToSubcircuitsFolder:(id)sender;              // "MainMenu.nib"
- (IBAction) refreshSubcircuitsTable:(id)sender;            // target method of the 'refresh' button

// SCHEMATIC-RELATED METHODS
- (IBAction) captureCurrentSchematic:(id)sender;            // calls conversion method of front document
- (IBAction) showPlacementGuides:(id)sender;                // notifies all document windows
- (IBAction) showInfoPanel:(id)sender;                      // sends info panel to front
- (IBAction) showElementsPanel:(id)sender;                  // sends elements panel to front
- (void) prepareElementsPanel;                              // prepares the elements panel for display
- (IBAction) showDeviceModelPanel:(id)sender;
- (IBAction) setElementsPanelTransparency:(id)sender;       // adjusts elements panel transparency
- (IBAction) setNodeAutoInsertion:(id)sender;
- (IBAction) setCanvasBackgroundColor:(id)sender;           // button action for bringing up the color chooser to change the schematics canvas background
- (void) changeCanvasBackgroundColor:(id)sender;            // changes the background color of the schematics canvas
- (MI_Tool*) currentTool;
- (IBAction) schematicToSVG:(id)sender;                     // converts the schematic drawing of the active document to SVG

- (MI_SubcircuitLibraryManager*) subcircuitLibraryManager;
@end
