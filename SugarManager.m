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
#import "SugarManager.h"
#import "CircuitDocument.h"
#import "SpiceASCIIOutputReader.h"
#import "GnucapASCIIOutputReader.h"
#import "MI_NonlinearElements.h"
#import "MI_LinearElements.h"
#import "MI_MiscellaneousElements.h"
#import "MI_PowerSourceElements.h"
#import "MI_DeviceModelManager.h"
#import "MI_SVGConverter.h"
#import "MI_TextElement.h"
#include <sys/sysctl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <math.h>
#include <CoreFoundation/CFURL.h>

NSString* SUGARML_HEADER = @"<?xml version=\"1.0\"?>\n<SugarData xmlns=\"http://www.macinit.com/misugar\"\nxmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\nxsi:schemaLocation=\"http://www.macinit.com/schemas/sugarml.xsd\" ?>";
NSString* MISUGAR_VERSION = @"0.5.8d";
NSString* MISUGAR_RELEASE_DATE = @"November 13, 2011";
NSString* MISUGAR_CUSTOM_SIMULATOR_PATH = @"SpiceExecutablePath";
NSString* MISUGAR_BuiltinSPICEPath = @"";
NSString* MISUGAR_USE_CUSTOM_SIMULATOR = @"UseCustomSimulator";
NSString* MISUGAR_SOURCE_VIEW_FONT_NAME = @"SourceViewFontName";
NSString* MISUGAR_SOURCE_VIEW_FONT_SIZE = @"SourceViewFontSize";
NSString* MISUGAR_RAW_OUTPUT_VIEW_FONT_NAME = @"RawOutputViewFontName";
NSString* MISUGAR_RAW_OUTPUT_VIEW_FONT_SIZE = @"RawOutputViewFontSize";
NSString* MISUGAR_SHOW_UNTITLED_DOCUMENT_AT_STARTUP = @"ShowUntitledDocumentAtStartup";
NSString* MISUGAR_FONT_CHANGE_NOTIFICATION = @"FontChangeNotification";
NSString* MISUGAR_PLOT_GRAPHS_LINE_WIDTH = @"PlotGraphsLineWidth";
NSString* MISUGAR_PLOT_GRID_LINE_WIDTH = @"PlotGridLineWidth";
NSString* MISUGAR_PLOT_LABELS_FONT_SIZE = @"PlotLabelsFontSize";
NSString* MISUGAR_PLOTTER_BACKGROUND_COLOR = @"PlotterBackgroundColor";
NSString* MISUGAR_PLOTTER_GRID_COLOR = @"PlotterGridColor";
NSString* MISUGAR_PLOT_DEFAULT_COMPLEX_NUMBER_REPRESENTATION = @"DefaultComplexNumberRepresentation";
NSString* MISUGAR_PLOTTER_LABEL_FONT_CHANGE_NOTIFICATION = @"LabelFontChangeNotification";
NSString* MISUGAR_PLOTTER_GRAPHS_LINE_WIDTH_CHANGE_NOTIFICATION = @"GraphLineWidthChangeNotification";
NSString* MISUGAR_PLOTTER_GRID_LINE_WIDTH_CHANGE_NOTIFICATION = @"GridLineWidthChangeNotification";
NSString* MISUGAR_PLOTTER_GRID_COLOR_CHANGE_NOTIFICATION = @"GridColorChangeNotification";
NSString* MISUGAR_PLOTTER_BACKGROUND_CHANGE_NOTIFICATION = @"BackgroundColorChangeNotification";
NSString* MISUGAR_PLOTTER_REMEMBERS_SETTINGS = @"PlotterRemembersSettings";
NSString* MISUGAR_PLOTTER_CLOSES_OLD_WINDOW = @"PlotterClosesOldWindows";
NSString* MISUGAR_PLOTTER_AUTO_SHOW_GUIDES_TAB = @"PlotterAutoShowGuidesTab";
NSString* MISUGAR_PLOTTER_SHOWS_GRID = @"PlotterShowsGrid";
NSString* MISUGAR_PLOTTER_SHOWS_LABELS = @"PlotterShowsLabels";
NSString* MISUGAR_PLOTTER_HAS_LOGARITHMIC_ABSCISSA = @"PlotterHasLogarithmicAbscissa";
NSString* MISUGAR_PLOTTER_HAS_LOGARITHMIC_ORDINATE = @"PlotterHasLogarithmicOrdinate";
NSString* MISUGAR_PLOTTER_HAS_LOG_LABELS_FOR_LOG_SCALE = @"PlotterHasLogLabelsForLogScale";
NSString* MISUGAR_MATHML_ITEM = @"Export Analysis to MathML...";
NSString* MISUGAR_MATLAB_ITEM = @"Export Analysis to Matlab...";
NSString* MISUGAR_TABULAR_TEXT_ITEM = @"Export Analysis to Tabular Text...";
NSString* MISUGAR_SVG_EXPORT_ITEM = @"Export Schematic to SVG...";
NSString* MISUGAR_CAPTURE_ITEM = @"Capture";
NSString* MISUGAR_ANALYZE_ITEM = @"Analyze";
NSString* MISUGAR_PLOT_ITEM = @"Plot";
NSString* MISUGAR_MAKE_SUBCIRCUIT_ITEM = @"Make Subcircuit...";
NSString* MISUGAR_GENERAL_PREFERENCES_ITEM = @"GeneralPrefsToolbarItem";
NSString* MISUGAR_SCHEMATIC_PREFERENCES_ITEM = @"SchematicPrefsToolbarItem";
NSString* MISUGAR_STARTUP_PREFERENCES_ITEM = @"StartupPrefsToolbarItem";
NSString* MISUGAR_FONT_PREFERENCES_ITEM = @"FontPrefsToolbarItem";
NSString* MISUGAR_SIMULATOR_PREFERENCES_ITEM = @"SimulatorPrefsToolbarItem";
NSString* MISUGAR_PLOTTER_PREFERENCES_ITEM = @"PlotterPrefsToolbarItem";
NSString* MISUGAR_LICENSE_KEY = @"Donation Key";
NSString* MISUGAR_DOCUMENT_WINDOW_FRAME = @"DocumentWindowFrame";
NSString* MISUGAR_PLOTTER_WINDOW_FRAME = @"PlotterWindowFrame";
NSString* MISUGAR_DOCUMENT_LAYOUT = @"DocumentLayout";
NSString* MISUGAR_DOCUMENT_FRACTIONAL_SIZE_OF_CANVAS = @"PercentageWidthCanvas";
NSString* MISUGAR_DOCUMENT_FRACTIONAL_HEIGHT_OF_NETLIST_FIELD = @"PercentageHeightNetlist";
NSString* MISUGAR_DOCUMENT_FRACTIONAL_HEIGHT_OF_OUTPUT_FIELD = @"PercentageHeightOutput";
NSString* MISUGAR_LINE_ENDING_CONVERSION_POLICY = @"LineEndingConversionPolicy";
NSString* MISUGAR_FILE_SAVING_POLICY = @"FileSavingPolicy";
// SCHEMATIC-RELATED
NSString* MISUGAR_ELEMENTS_PANEL_ALPHA = @"ElementsPanelAlpha";
NSString* MISUGAR_INFO_PANEL_ALPHA = @"InfoPanelAlpha";
NSString* MISUGAR_SHOW_PLACEMENT_GUIDES = @"ShowPlacementGuides";
NSString* MISUGAR_AUTOINSERT_NODE_ELEMENT = @"AutoInsertNodeElement";
NSString* MI_SchematicElementPboardType = @"MI_SchematicElementPboardType";
NSString* MI_SchematicElementsPboardType = @"MI_SchematicElementsPboardType";
NSString* MISUGAR_CIRCUIT_DEVICE_MODELS = @"Circuit Device Models";
NSString* MISUGAR_PLACEMENT_GUIDE_VISIBILITY_CHANGE_NOTIFICATION = @"PlacementGuideVisibility";
NSString* MISUGAR_ELEMENTS_PANEL_FRAME = @"ElementsPanelFrame";
NSString* MISUGAR_SCHEMATIC_CANVAS_BACKGROUND_COLOR = @"SchematicCanvasBackgroundColor";
NSString* MISUGAR_CANVAS_BACKGROUND_CHANGE_NOTIFICATION = @"CanvasBackgroundNotification";
NSString* MISUGAR_SUBCIRCUIT_LIBRARY_FOLDER = @"SubcircuitLibraryFolderPath";

static SugarManager* managerInstance = nil;

@interface SugarManager () <NSToolbarDelegate>
@end

@implementation SugarManager

- (id) init
{
    if (self = [super init])
    {
        NSFont* defaultFont = [NSFont userFontOfSize:0.0f];
        /* Register defaults */
        NSMutableDictionary* defaultsDictionary = [NSMutableDictionary dictionary];
        [defaultsDictionary setObject:@"Horizontal"
                               forKey:MISUGAR_DOCUMENT_LAYOUT];
        [defaultsDictionary setObject:@""
                               forKey:MISUGAR_CUSTOM_SIMULATOR_PATH];
        [defaultsDictionary setObject:[defaultFont fontName]
                               forKey:MISUGAR_SOURCE_VIEW_FONT_NAME];
        [defaultsDictionary setObject:[NSNumber numberWithFloat:[defaultFont pointSize]]
                               forKey:MISUGAR_SOURCE_VIEW_FONT_SIZE];
        [defaultsDictionary setObject:[defaultFont fontName]
                               forKey:MISUGAR_RAW_OUTPUT_VIEW_FONT_NAME];
        [defaultsDictionary setObject:[NSNumber numberWithFloat:[defaultFont pointSize]]
                               forKey:MISUGAR_RAW_OUTPUT_VIEW_FONT_SIZE];
        [defaultsDictionary setObject:[NSNumber numberWithBool:YES]
                               forKey:MISUGAR_SHOW_UNTITLED_DOCUMENT_AT_STARTUP];
        [defaultsDictionary setObject:[NSNumber numberWithChar:0] // chooser list index
                               forKey:MISUGAR_PLOT_GRAPHS_LINE_WIDTH];
        [defaultsDictionary setObject:[NSNumber numberWithChar:0] // chooser list index
                               forKey:MISUGAR_PLOT_GRID_LINE_WIDTH];
        [defaultsDictionary setObject:[NSNumber numberWithChar:1] // chooser list index
                               forKey:MISUGAR_PLOT_LABELS_FONT_SIZE];
        [defaultsDictionary setObject:[NSKeyedArchiver archivedDataWithRootObject:
                                        [NSColor colorWithDeviceRed:1.0f
                                                              green:1.0f
                                                               blue:1.0f
                                                              alpha:1.0f]] // color well's color
                               forKey:MISUGAR_PLOTTER_BACKGROUND_COLOR];
        [defaultsDictionary setObject:[NSKeyedArchiver archivedDataWithRootObject:
            [NSColor colorWithDeviceWhite:0.8f alpha:1.0f]] // color well's color
                               forKey:MISUGAR_PLOTTER_GRID_COLOR];
        [defaultsDictionary setObject:[NSNumber numberWithChar:0] // chooser list index
                               forKey:MISUGAR_PLOT_DEFAULT_COMPLEX_NUMBER_REPRESENTATION];
        [defaultsDictionary setObject:[NSNumber numberWithBool:NO]
                               forKey:MISUGAR_USE_CUSTOM_SIMULATOR];
        [defaultsDictionary setObject:[NSNumber numberWithBool:NO]
                               forKey:MISUGAR_PLOTTER_REMEMBERS_SETTINGS];
        [defaultsDictionary setObject:[NSNumber numberWithBool:NO]
                               forKey:MISUGAR_PLOTTER_CLOSES_OLD_WINDOW];
        [defaultsDictionary setObject:[NSNumber numberWithBool:YES]
                               forKey:MISUGAR_PLOTTER_AUTO_SHOW_GUIDES_TAB];
        [defaultsDictionary setObject:[NSNumber numberWithBool:YES]
                               forKey:MISUGAR_PLOTTER_SHOWS_GRID];
        [defaultsDictionary setObject:[NSNumber numberWithBool:YES]
                               forKey:MISUGAR_PLOTTER_SHOWS_LABELS];
        [defaultsDictionary setObject:[NSNumber numberWithBool:NO]
                               forKey:MISUGAR_PLOTTER_HAS_LOGARITHMIC_ABSCISSA];
        [defaultsDictionary setObject:[NSNumber numberWithBool:NO]
                               forKey:MISUGAR_PLOTTER_HAS_LOGARITHMIC_ORDINATE];
        [defaultsDictionary setObject:[NSNumber numberWithBool:NO]
                               forKey:MISUGAR_PLOTTER_HAS_LOG_LABELS_FOR_LOG_SCALE];
        [defaultsDictionary setObject:@"Ask"
                               forKey:MISUGAR_LINE_ENDING_CONVERSION_POLICY];
        [defaultsDictionary setObject:[NSNumber numberWithInt:MI_SaveAsPureNetlistIfNoSchematic]
                               forKey:MISUGAR_FILE_SAVING_POLICY];
        [defaultsDictionary setObject:[NSNumber numberWithFloat:0.90f]
                               forKey:MISUGAR_ELEMENTS_PANEL_ALPHA];
        [defaultsDictionary setObject:[NSNumber numberWithFloat:0.85f]
                               forKey:MISUGAR_INFO_PANEL_ALPHA];
        [defaultsDictionary setObject:[NSNumber numberWithBool:YES]
                               forKey:MISUGAR_SHOW_PLACEMENT_GUIDES];
        [defaultsDictionary setObject:[NSNumber numberWithBool:YES]
                               forKey:MISUGAR_AUTOINSERT_NODE_ELEMENT];
        [defaultsDictionary setObject:[NSNumber numberWithFloat:0.6f]
                               forKey:MISUGAR_DOCUMENT_FRACTIONAL_SIZE_OF_CANVAS];
        [defaultsDictionary setObject:[NSNumber numberWithFloat:0.5f]
                               forKey:MISUGAR_DOCUMENT_FRACTIONAL_HEIGHT_OF_NETLIST_FIELD];
        [defaultsDictionary setObject:[NSNumber numberWithFloat:0.4f]
                               forKey:MISUGAR_DOCUMENT_FRACTIONAL_HEIGHT_OF_OUTPUT_FIELD];
        [defaultsDictionary setObject:[NSKeyedArchiver archivedDataWithRootObject:
            [NSColor colorWithDeviceRed:1.0f
                                  green:1.0f
                                   blue:1.0f
                                  alpha:1.0f]] // color well's color
                               forKey:MISUGAR_SCHEMATIC_CANVAS_BACKGROUND_COLOR];
        [defaultsDictionary setObject:[MI_SubcircuitLibraryManager defaultSubcircuitLibraryPath]
                               forKey:MISUGAR_SUBCIRCUIT_LIBRARY_FOLDER];
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDictionary];
        settingSourceFont = YES;
        settingPlotterBackgroundColor = NO;
        settingPlotterGridColor = NO;
        managerInstance = self;
        elementsPanel = nil;
        selectTool = [[MI_SelectConnectTool alloc] init];
        scaleTool = [[MI_ScaleTool alloc] init];
        currentTool = selectTool;
        inspector = [MI_Inspector sharedInspector];
    }
    return self;
}


+ (SugarManager*) sharedManager
{
    return managerInstance;
}


- (void) awakeFromNib
{
    NSToolbar *toolbar;

    // Set the circuit simulator tool
    MISUGAR_BuiltinSPICEPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/spice"] retain];

    /* Build the toolbar of the preferences window */
    toolbar = [[NSToolbar alloc] initWithIdentifier:@"PreferencesToolbar"];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [toolbar setDelegate:self];
    [preferencesPanel setToolbar:toolbar];
    [toolbar release];

    // The device model manager must already exist when the subcircuit
    // library manager is created in order to add the device models,
    // found in the subcircuits, to the device model library
    
    [MI_DeviceModelManager sharedManager];
    
    libManager = [[MI_SubcircuitLibraryManager alloc]
        initWithChooserView:subcircuitChooser
                  tableView:subcircuitsTable
              namespaceView:subcircuitNamespaceField];
    
}


- (BOOL) applicationShouldOpenUntitledFile:(NSApplication*)sender
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:MISUGAR_SHOW_UNTITLED_DOCUMENT_AT_STARTUP] boolValue];
}


- (IBAction) showPreferencesPanel:(id)sender
{
    if (!preferencesPanel)
    {
        NSUserDefaults* userdefs = [NSUserDefaults standardUserDefaults];
        NSFont* sourceFont =
            [NSFont fontWithName:[userdefs objectForKey:MISUGAR_SOURCE_VIEW_FONT_NAME]
                            size:[[userdefs objectForKey:MISUGAR_SOURCE_VIEW_FONT_SIZE] floatValue]];
        NSFont* rawOutputFont =
            [NSFont fontWithName:[userdefs objectForKey:MISUGAR_RAW_OUTPUT_VIEW_FONT_NAME]
                            size:[[userdefs objectForKey:MISUGAR_RAW_OUTPUT_VIEW_FONT_SIZE] floatValue]];
        [NSBundle loadNibNamed:@"SugarPreferences.nib"
                        owner:self];

        if ([[userdefs objectForKey:MISUGAR_USE_CUSTOM_SIMULATOR] boolValue])
        {
            [useCustomSimulatorButton setState:NSOnState];
            [useSPICEButton setState:NSOffState];
            [customSimulatorField setEnabled:YES];
            [customSimulatorBrowseButton setEnabled:YES];
        }
        else
        {
          [useCustomSimulatorButton setState:NSOffState];
            {
                [useSPICEButton setState:NSOnState];
            }
            [customSimulatorField setEnabled:NO];
            [customSimulatorBrowseButton setEnabled:NO];
        }
        [layoutChooser selectItemWithTitle:[userdefs objectForKey:MISUGAR_DOCUMENT_LAYOUT]];
        [customSimulatorField setStringValue:(NSString*)[userdefs objectForKey:MISUGAR_CUSTOM_SIMULATOR_PATH]];
        [sourceFontNameField setStringValue:[[sourceFont displayName] stringByAppendingFormat:@" %2.1f", [sourceFont pointSize]]];
        [rawOutputFontNameField setStringValue:[[rawOutputFont displayName] stringByAppendingFormat:@" %2.1f", [rawOutputFont pointSize]]];
        [lookForUpdateAtStartupButton setState:lookForUpdateAtStartup];
        [showUntitledDocumentAtStartupButton setState:([[userdefs objectForKey:MISUGAR_SHOW_UNTITLED_DOCUMENT_AT_STARTUP] boolValue] ? NSOnState : NSOffState)];
        [plotterGraphsLineWidthChooser selectItemAtIndex:(int)[[userdefs objectForKey:MISUGAR_PLOT_GRAPHS_LINE_WIDTH] charValue]];
        [plotterGridLineWidthChooser selectItemAtIndex:(int)[[userdefs objectForKey:MISUGAR_PLOT_GRID_LINE_WIDTH] charValue]];
        [plotterLabelsFontSizeChooser selectItemAtIndex:(int)[[userdefs objectForKey:MISUGAR_PLOT_LABELS_FONT_SIZE] charValue]];
        [NSColorPanel setPickerMode:NSColorPanelModeHSB];
        [plotterBackgroundColorChooser setColor:
            [NSKeyedUnarchiver unarchiveObjectWithData:
                [userdefs objectForKey:MISUGAR_PLOTTER_BACKGROUND_COLOR]]];
        [plotterGridColorChooser setColor:
            [NSKeyedUnarchiver unarchiveObjectWithData:
                [userdefs objectForKey:MISUGAR_PLOTTER_GRID_COLOR]]];
        [plotterRemembersSettingsButton setState:([[userdefs objectForKey:MISUGAR_PLOTTER_REMEMBERS_SETTINGS] boolValue] ? NSOnState : NSOffState)];
        [plotterClosesOldWindows setState:([[userdefs objectForKey:MISUGAR_PLOTTER_CLOSES_OLD_WINDOW] boolValue] ? NSOnState : NSOffState)];
        [plotterAutoShowsGuidesTab setState:([[userdefs objectForKey:MISUGAR_PLOTTER_AUTO_SHOW_GUIDES_TAB] boolValue] ? NSOnState : NSOffState)];
        [conversionPolicyChooser selectItemWithTitle:[userdefs objectForKey:MISUGAR_LINE_ENDING_CONVERSION_POLICY]];
        [fileSavingPolicyChooser selectItemAtIndex:[[userdefs objectForKey:MISUGAR_FILE_SAVING_POLICY] intValue]];
        [autoInsertNodeElement setState:([[userdefs objectForKey:MISUGAR_AUTOINSERT_NODE_ELEMENT] boolValue] ? NSOnState : NSOffState)];
        [showPlacementGuides setState:([[userdefs objectForKey:MISUGAR_SHOW_PLACEMENT_GUIDES] boolValue] ? NSOnState : NSOffState)];
        [schematicCanvasBackground setColor:[NSUnarchiver unarchiveObjectWithData:[userdefs objectForKey:MISUGAR_SCHEMATIC_CANVAS_BACKGROUND_COLOR]]];
        [subcircuitLibraryPathField setStringValue:[userdefs objectForKey:MISUGAR_SUBCIRCUIT_LIBRARY_FOLDER]];
        [preferencesPanel setContentSize:[generalPrefsView frame].size];
        [preferencesPanel setContentView:generalPrefsView];
        [preferencesPanel setTitle:@"MI-SUGAR General Preferences"];
    }
    [preferencesPanel orderFront:self];
    [preferencesPanel makeKeyWindow];
}


- (IBAction) showAboutPanel:(id)sender
{
    [NSBundle loadNibNamed:@"About.nib" owner:self];
    [versionField setStringValue:MISUGAR_VERSION];
    [releaseDateField setStringValue:MISUGAR_RELEASE_DATE];        
    [aboutPanel makeKeyAndOrderFront:self];
}


- (IBAction) setCustomSimulator:(id)sender
{
    NSOpenPanel* op = [NSOpenPanel openPanel];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
    [op setRepresentedFilename:@"spice"];
    [op beginSheetModalForWindow:preferencesPanel completionHandler:^(NSInteger result) {
      if ( result == NSModalResponseOK )
      {
        [customSimulatorField setStringValue:[[op URL] path]];
        [[NSUserDefaults standardUserDefaults] setObject:[[op URL] path] forKey:MISUGAR_CUSTOM_SIMULATOR_PATH];
      }
    }];
}


- (IBAction) setSubcircuitLibraryFolder:(id)sender
{
    NSOpenPanel* op = [NSOpenPanel openPanel];
    [op setCanChooseFiles:NO];
    [op setCanChooseDirectories:YES];
    [op setPrompt:@"Select"];
    [op setDirectoryURL:[NSURL fileURLWithPath:[subcircuitLibraryPathField stringValue]]];
    [op beginSheetModalForWindow:preferencesPanel completionHandler:^(NSInteger result) {
      if ( result == NSModalResponseOK )
      {
        [subcircuitLibraryPathField setStringValue:[[op URL] path]];
        [[NSUserDefaults standardUserDefaults]
         setObject:[[op URL] path]
         forKey:MISUGAR_SUBCIRCUIT_LIBRARY_FOLDER];
        [libManager refreshAll];        
      }
    }];
}


/* Delegate method. Called when the user presses enter in a text field. */
- (void) controlTextDidEndEditing:(NSNotification*)aNotification
{
    if ([aNotification object] == customSimulatorField)
    {
        // user has set the new path to the simulator tool
        [[NSUserDefaults standardUserDefaults] setObject:[customSimulatorField stringValue]
                                                forKey:MISUGAR_CUSTOM_SIMULATOR_PATH];
    }
}


#pragma mark -
///////////////////////////////////////////////////////////////////
// Setting Fonts
///////////////////////////////////////////////////////////////////

- (IBAction) setSourceFont:(id)sender
{
    NSUserDefaults* userdefs = [NSUserDefaults standardUserDefaults];
    NSFontManager* fmanager = [NSFontManager sharedFontManager];
    NSFont* oldFont =
        [NSFont fontWithName:[userdefs objectForKey:MISUGAR_SOURCE_VIEW_FONT_NAME]
                        size:[[userdefs objectForKey:MISUGAR_SOURCE_VIEW_FONT_SIZE] floatValue]];
    [fmanager setDelegate:self];
    [fmanager setSelectedFont:oldFont
                   isMultiple:NO];
    [[fmanager fontPanel:YES] makeFirstResponder:self];
    settingSourceFont = YES;
    [fmanager orderFrontFontPanel:self];
}


- (IBAction) setRawOutputFont:(id)sender
{
    NSUserDefaults* userdefs = [NSUserDefaults standardUserDefaults];
    NSFontManager* fmanager = [NSFontManager sharedFontManager];
    NSFont* oldFont =
        [NSFont fontWithName:[userdefs objectForKey:MISUGAR_RAW_OUTPUT_VIEW_FONT_NAME]
                        size:[[userdefs objectForKey:MISUGAR_RAW_OUTPUT_VIEW_FONT_SIZE] floatValue]];
    settingSourceFont = NO;
    [fmanager setDelegate:self];
    [fmanager setSelectedFont:oldFont
                   isMultiple:NO];
    [[fmanager fontPanel:YES] makeFirstResponder:self];
    [fmanager orderFrontFontPanel:self];
}


- (void) changeFont:(id)sender
{
    NSFontManager* fmanager = [NSFontManager sharedFontManager];
    NSFont* newFont = [fmanager convertFont:[fmanager selectedFont]];
    NSUserDefaults* userdefs = [NSUserDefaults standardUserDefaults];
    if (settingSourceFont)
    {
        [sourceFontNameField setStringValue:[[newFont displayName] stringByAppendingFormat:@" %2.1f", [newFont pointSize]]];
        [userdefs setObject:[newFont fontName]
                     forKey:MISUGAR_SOURCE_VIEW_FONT_NAME];
        [userdefs setObject:[NSNumber numberWithFloat:[newFont pointSize]]
                     forKey:MISUGAR_SOURCE_VIEW_FONT_SIZE];
    }
    else
    {
        [rawOutputFontNameField setStringValue:[[newFont displayName] stringByAppendingFormat:@" %2.1f", [newFont pointSize]]];
        [userdefs setObject:[newFont fontName]
                     forKey:MISUGAR_RAW_OUTPUT_VIEW_FONT_NAME];
        [userdefs setObject:[NSNumber numberWithFloat:[newFont pointSize]]
                     forKey:MISUGAR_RAW_OUTPUT_VIEW_FONT_SIZE];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:MISUGAR_FONT_CHANGE_NOTIFICATION
                                                        object:[NSNumber numberWithBool:settingSourceFont]];
}


#pragma mark -

/* This method is used for the proper function of the font panel */
- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
    if ([[aNotification name] isEqualToString:NSWindowDidBecomeKeyNotification])
        if ([[[NSFontManager sharedFontManager] fontPanel:YES] isVisible])
            [preferencesPanel makeFirstResponder:self];
}

#pragma mark -
///////////////////////////////////////////////////////////////////
// Plotter settings
///////////////////////////////////////////////////////////////////

- (IBAction) setLabelsFontSize:(id)sender
{
    [[NSUserDefaults standardUserDefaults]
        setObject:[NSNumber numberWithChar:[sender indexOfSelectedItem]]
           forKey:MISUGAR_PLOT_LABELS_FONT_SIZE];
    [[NSNotificationCenter defaultCenter]
        postNotificationName:MISUGAR_PLOTTER_LABEL_FONT_CHANGE_NOTIFICATION
                      object:self];
}


- (IBAction) setGraphsLineWidth:(id)sender
{
    [[NSUserDefaults standardUserDefaults]
        setObject:[NSNumber numberWithChar:[sender indexOfSelectedItem]]
           forKey:MISUGAR_PLOT_GRAPHS_LINE_WIDTH];
    [[NSNotificationCenter defaultCenter]
        postNotificationName:MISUGAR_PLOTTER_GRAPHS_LINE_WIDTH_CHANGE_NOTIFICATION
                      object:self];
}


- (IBAction) setGridLineWidth:(id)sender
{
    [[NSUserDefaults standardUserDefaults]
        setObject:[NSNumber numberWithChar:[sender indexOfSelectedItem]]
           forKey:MISUGAR_PLOT_GRID_LINE_WIDTH];
    [[NSNotificationCenter defaultCenter]
        postNotificationName:MISUGAR_PLOTTER_GRID_LINE_WIDTH_CHANGE_NOTIFICATION
                      object:self];
}


- (void) changePlotterColors:(id)sender;
{
    if (settingPlotterBackgroundColor)
    {
        [plotterBackgroundColorChooser setColor:[sender color]];
        [[NSUserDefaults standardUserDefaults]
            setObject:[NSKeyedArchiver archivedDataWithRootObject:[sender color]]
            forKey:MISUGAR_PLOTTER_BACKGROUND_COLOR];
        [[NSNotificationCenter defaultCenter]
            postNotificationName:MISUGAR_PLOTTER_BACKGROUND_CHANGE_NOTIFICATION
                        object:self];
    }
    else if (settingPlotterGridColor)
    {
        [plotterGridColorChooser setColor:[sender color]];
        [[NSUserDefaults standardUserDefaults]
            setObject:[NSKeyedArchiver archivedDataWithRootObject:[sender color]]
            forKey:MISUGAR_PLOTTER_GRID_COLOR];
        [[NSNotificationCenter defaultCenter]
            postNotificationName:MISUGAR_PLOTTER_GRID_COLOR_CHANGE_NOTIFICATION
                        object:self];
    }
}


- (IBAction) setPlotterBackgroundColor:(id)sender
{
    NSColorPanel* cp = [NSColorPanel sharedColorPanel];
    settingPlotterBackgroundColor = YES;
    settingPlotterGridColor = NO;
    [cp setTarget:self];
    [cp setAction:@selector(changePlotterColors:)];
    [cp setDelegate:self];
    [cp makeFirstResponder:nil];
    [cp setColor:[plotterBackgroundColorChooser color]];
    [NSColorPanel setPickerMode:NSColorPanelModeHSB];
    [cp makeKeyAndOrderFront:self];
}


- (IBAction) setPlotterGridColor:(id)sender
{
    NSColorPanel* cp = [NSColorPanel sharedColorPanel];
    settingPlotterBackgroundColor = NO;
    settingPlotterGridColor = YES;
    [cp setTarget:self];
    [cp setAction:@selector(changePlotterColors:)];
    [cp setDelegate:self];
    [cp makeFirstResponder:nil];
    [cp setColor:[plotterGridColorChooser color]];
    [NSColorPanel setPickerMode:NSColorPanelModeHSB];
    [cp makeKeyAndOrderFront:self];
}


- (IBAction) setPlotterFunctionSetting:(id)sender
{
    if (sender == plotterRemembersSettingsButton)
        [[NSUserDefaults standardUserDefaults]
            setObject:[NSNumber numberWithBool:([plotterRemembersSettingsButton state] == NSOnState)]
               forKey:MISUGAR_PLOTTER_REMEMBERS_SETTINGS];
    else if (sender == plotterClosesOldWindows)
        [[NSUserDefaults standardUserDefaults]
            setObject:[NSNumber numberWithBool:([plotterClosesOldWindows state] == NSOnState)]
               forKey:MISUGAR_PLOTTER_CLOSES_OLD_WINDOW];
    else /* if (sender == plotterAutoShowsGuidesTab) */
        [[NSUserDefaults standardUserDefaults]
            setObject:[NSNumber numberWithBool:([plotterAutoShowsGuidesTab state] == NSOnState)]
               forKey:MISUGAR_PLOTTER_AUTO_SHOW_GUIDES_TAB];
}

#pragma mark -

- (IBAction) setShowUntitledDocumentAtStartup:(id)sender
{
    [[NSUserDefaults standardUserDefaults]
        setObject:[NSNumber numberWithBool:([showUntitledDocumentAtStartupButton state] == NSOnState)]
           forKey:MISUGAR_SHOW_UNTITLED_DOCUMENT_AT_STARTUP];    
}


- (IBAction) selectSimulator:(id)sender
{
    BOOL useCustomSim = ([sender selectedCell] == useCustomSimulatorButton);
    [[NSUserDefaults standardUserDefaults]
        setObject:[NSNumber numberWithBool:useCustomSim]
           forKey:MISUGAR_USE_CUSTOM_SIMULATOR];
    if (useCustomSim)
    {
        [customSimulatorField setEnabled:YES];
        [customSimulatorBrowseButton setEnabled:YES];
    }
    else
    {
        [customSimulatorField setEnabled:NO];
        [customSimulatorBrowseButton setEnabled:NO];
    }
}

/* ------------ Export functions ------------------------------ */


- (IBAction) exportToMathML:(id)sender
{
    NSWindow* documentWindow = [NSApp mainWindow];
    convertToMathML = YES;
    if (documentWindow && [[documentWindow delegate] isKindOfClass:[CircuitDocument class]])
    {
      NSSavePanel* savePanel = [NSSavePanel savePanel];
      [savePanel setRepresentedFilename:[[documentWindow title] stringByAppendingString:@".mml"]];
      [savePanel beginSheetModalForWindow:documentWindow completionHandler:^(NSInteger result) {
        if ( (result == NSModalResponseOK) && [[[NSApp mainWindow] delegate] isKindOfClass:[CircuitDocument class]] )
        {
          [(CircuitDocument*)[[NSApp mainWindow] delegate] export:@"MathML" toFile:[[[savePanel URL] path] stringByDeletingPathExtension]];
        }
      }];
    }
}


- (IBAction) exportToMatlab:(id)sender
{
    NSWindow* documentWindow = [NSApp mainWindow];
    convertToMathML = NO;
    if (documentWindow && [[documentWindow delegate] isKindOfClass:[CircuitDocument class]])
    {
      NSSavePanel* savePanel = [NSSavePanel savePanel];
      [savePanel setRepresentedFilename:[[documentWindow title] stringByAppendingString:@".m"]];
      [savePanel beginSheetModalForWindow:documentWindow completionHandler:^(NSInteger result) {
        if ( (result == NSModalResponseOK) && [[[NSApp mainWindow] delegate] isKindOfClass:[CircuitDocument class]] )
        {
          [(CircuitDocument*)[[NSApp mainWindow] delegate] export:@"Matlab" toFile:[[[savePanel URL] path] stringByDeletingPathExtension]];
        }
      }];
    }
}


- (IBAction) exportToTabularText:(id)sender
{
    NSWindow* documentWindow = [NSApp mainWindow];
    if (documentWindow && [[documentWindow delegate] isKindOfClass:[CircuitDocument class]])
    {
      NSSavePanel* savePanel = [NSSavePanel savePanel];
      [savePanel setRepresentedFilename:[[documentWindow title] stringByAppendingString:@".txt"]];
      [savePanel beginSheetModalForWindow:documentWindow completionHandler:^(NSInteger result) {
        if ( (result == NSModalResponseOK) && [[[NSApp mainWindow] delegate] isKindOfClass:[CircuitDocument class]] )
        {
          [(CircuitDocument*)[[NSApp mainWindow] delegate] export:@"Tabular" toFile:[[[savePanel URL] path] stringByDeletingPathExtension]];
        }        
      }];
    }
}


- (BOOL) validateMenuItem:(NSMenuItem*)item
{
    if ([[item title] isEqualToString:MISUGAR_MATHML_ITEM] ||
        [[item title] isEqualToString:MISUGAR_MATLAB_ITEM] ||
        [[item title] isEqualToString:MISUGAR_TABULAR_TEXT_ITEM] ||
        [[item title] isEqualToString:MISUGAR_CAPTURE_ITEM] ||
        [[item title] isEqualToString:MISUGAR_ANALYZE_ITEM] ||
        [[item title] isEqualToString:MISUGAR_MAKE_SUBCIRCUIT_ITEM] ||
        [[item title] isEqualToString:MISUGAR_PLOT_ITEM] ||
        [[item title] isEqualToString:MISUGAR_SVG_EXPORT_ITEM])
    {
        NSWindow* win;
        if ((win = [NSApp mainWindow]) &&
            ([[win delegate] isKindOfClass:[CircuitDocument class]])) // This check is necessary to avoid infinite loops due to the use of the font panel
            return [(CircuitDocument*)[win delegate] validateMenuItem:item];
        else
            return NO;
    }
    else
        return YES;
}

/* -------------------------------------------------------------------- */

- (IBAction) analyzeCircuit:(id)sender
{
    NSWindow* documentWindow = [NSApp mainWindow];
    if (documentWindow &&
        [[documentWindow delegate] isKindOfClass:[CircuitDocument class]] &&
        [(CircuitDocument*)[documentWindow delegate] model])
        [(CircuitDocument*)[documentWindow delegate] runSimulator:nil];
}

- (IBAction) plotCircuitAnalysis:(id)sender
{
    NSWindow* documentWindow = [NSApp mainWindow];
    if (documentWindow &&
        [[documentWindow delegate] isKindOfClass:[CircuitDocument class]] &&
        [(CircuitDocument*)[documentWindow delegate] model])
        [(CircuitDocument*)[documentWindow delegate] plotResults:nil];
}


- (IBAction) makeSubcircuit:(id)sender
{
    NSWindow* documentWindow = [NSApp mainWindow];
    if (documentWindow &&
        [[documentWindow delegate] isKindOfClass:[CircuitDocument class]] &&
        [(CircuitDocument*)[documentWindow delegate] model])
        [(CircuitDocument*)[documentWindow delegate] makeSubcircuit];
}


- (IBAction) schematicToSVG:(id)sender
{
    NSWindow* documentWindow = [NSApp mainWindow];
    if (documentWindow &&
        [[documentWindow delegate] isKindOfClass:[CircuitDocument class]])
    {
        NSSavePanel* sp = [NSSavePanel savePanel];
        [sp setAllowedFileTypes:[NSArray arrayWithObject:@"svg"]];
        [sp setCanCreateDirectories:YES];
        [sp setCanSelectHiddenExtension:NO];
        [sp setRepresentedFilename:[documentWindow title]];
        [sp beginSheetModalForWindow:documentWindow completionHandler:^(NSInteger returnCode) {
          if (returnCode == NSModalResponseOK)
          {
            if ( [[[NSApp mainWindow] delegate] isKindOfClass:[CircuitDocument class]] )
            {
              MI_Schematic* s = [[(CircuitDocument*)[[NSApp mainWindow] delegate] model] schematic];
              [(NSString*)[MI_SVGConverter schematicToSVG:s] writeToURL:[sp URL] atomically:YES encoding:NSASCIIStringEncoding error:NULL];
            }
          }
        }];
    }
}


/* -------- Toolbar methods ------------------------------------------- */


/* toolbar delegate method */
- (NSArray*) toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        MISUGAR_GENERAL_PREFERENCES_ITEM, MISUGAR_SCHEMATIC_PREFERENCES_ITEM,
        MISUGAR_STARTUP_PREFERENCES_ITEM, MISUGAR_SIMULATOR_PREFERENCES_ITEM,
        MISUGAR_PLOTTER_PREFERENCES_ITEM, MISUGAR_FONT_PREFERENCES_ITEM, nil];
}

/* toolbar delegate method */
- (NSArray*) toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        MISUGAR_GENERAL_PREFERENCES_ITEM, MISUGAR_SCHEMATIC_PREFERENCES_ITEM,
        MISUGAR_STARTUP_PREFERENCES_ITEM, MISUGAR_SIMULATOR_PREFERENCES_ITEM,
        MISUGAR_PLOTTER_PREFERENCES_ITEM, MISUGAR_FONT_PREFERENCES_ITEM, nil];
}

/* toolbar delegate method */
- (NSToolbarItem *)toolbar:(NSToolbar*)toolbar
     itemForItemIdentifier:(NSString*)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
    if ([itemIdentifier isEqualToString:MISUGAR_GENERAL_PREFERENCES_ITEM])
    {
        generalPreferences = [[NSToolbarItem alloc] initWithItemIdentifier:MISUGAR_GENERAL_PREFERENCES_ITEM];
        [generalPreferences setLabel:@"General"];
        [generalPreferences setAction:@selector(switchPreferenceView:)];
        [generalPreferences setTarget:self];
        [generalPreferences setToolTip:@"General preferences"];
        [generalPreferences setImage:[[NSImage alloc] initWithContentsOfFile:
            [[NSBundle mainBundle] pathForResource:@"general_pref_button"
                                            ofType:@"png"]]];
        return generalPreferences;
    }
    if ([itemIdentifier isEqualToString:MISUGAR_SCHEMATIC_PREFERENCES_ITEM])
    {
        schematicPreferences = [[NSToolbarItem alloc] initWithItemIdentifier:MISUGAR_GENERAL_PREFERENCES_ITEM];
        [schematicPreferences setLabel:@"Schematic"];
        [schematicPreferences setAction:@selector(switchPreferenceView:)];
        [schematicPreferences setTarget:self];
        [schematicPreferences setToolTip:@"Schematic preferences"];
        [schematicPreferences setImage:[[NSImage alloc] initWithContentsOfFile:
            [[NSBundle mainBundle] pathForResource:@"schematic_pref_button"
                                            ofType:@"png"]]];
        return schematicPreferences;
    }
    else if ([itemIdentifier isEqualToString:MISUGAR_STARTUP_PREFERENCES_ITEM])
    {
        startupPreferences = [[NSToolbarItem alloc] initWithItemIdentifier:MISUGAR_STARTUP_PREFERENCES_ITEM];
        [startupPreferences setLabel:@"Startup"];
        [startupPreferences setAction:@selector(switchPreferenceView:)];
        [startupPreferences setTarget:self];
        [startupPreferences setToolTip:@"Startup preferences"];
        [startupPreferences setImage:[[NSImage alloc] initWithContentsOfFile:
            [[NSBundle mainBundle] pathForResource:@"startup_pref_button"
                                            ofType:@"png"]]];
        return startupPreferences;
    }
    else if ([itemIdentifier isEqualToString:MISUGAR_FONT_PREFERENCES_ITEM])
    {
        fontPreferences = [[NSToolbarItem alloc] initWithItemIdentifier:MISUGAR_FONT_PREFERENCES_ITEM];
        [fontPreferences setLabel:@"Fonts"];
        [fontPreferences setAction:@selector(switchPreferenceView:)];
        [fontPreferences setTarget:self];
        [fontPreferences setToolTip:@"Font preferences"];
        [fontPreferences setImage:[[NSImage alloc] initWithContentsOfFile:
            [[NSBundle mainBundle] pathForResource:@"fonts_pref_button"
                                            ofType:@"png"]]];
        return fontPreferences;
    }
    if ([itemIdentifier isEqualToString:MISUGAR_SIMULATOR_PREFERENCES_ITEM])
    {
        simulatorPreferences = [[NSToolbarItem alloc] initWithItemIdentifier:MISUGAR_SIMULATOR_PREFERENCES_ITEM];
        [simulatorPreferences setLabel:@"Simulator"];
        [simulatorPreferences setAction:@selector(switchPreferenceView:)];
        [simulatorPreferences setTarget:self];
        [simulatorPreferences setToolTip:@"Simulator preferences"];
        [simulatorPreferences setImage:[[NSImage alloc] initWithContentsOfFile:
            [[NSBundle mainBundle] pathForResource:@"simulator_pref_button"
                                            ofType:@"png"]]];
        return simulatorPreferences;
    }
    else if ([itemIdentifier isEqualToString:MISUGAR_PLOTTER_PREFERENCES_ITEM])
    {
        plotterPreferences = [[NSToolbarItem alloc] initWithItemIdentifier:MISUGAR_PLOTTER_PREFERENCES_ITEM];
        [plotterPreferences setLabel:@"Plotter"];
        [plotterPreferences setAction:@selector(switchPreferenceView:)];
        [plotterPreferences setTarget:self];
        [plotterPreferences setToolTip:@"Plotter preferences"];
        [plotterPreferences setImage:[[NSImage alloc] initWithContentsOfFile:
            [[NSBundle mainBundle] pathForResource:@"plotter_pref_button"
                                            ofType:@"png"]]];
        return plotterPreferences;
    }
    else
        return nil;
}

/* protocol implementation */
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    return YES;
}


- (void) windowWillClose:(NSNotification *)aNotification
{
    id p = [aNotification object];
    if ([p isKindOfClass:[NSColorPanel class]] ||
        [p isKindOfClass:[NSFontPanel class]])
        [p setTarget:nil];
}


- (IBAction) switchPreferenceView:(id)sender
{
    float newHeight, newWidth;
    NSRect newFrame;
    float toolbarHeight;

    [preferencesPanel setTitle:@""];
    NSView* emptyView = [[NSView alloc] init];
    newFrame = [NSWindow contentRectForFrameRect:[preferencesPanel frame]
                                       styleMask:[preferencesPanel styleMask]];
    toolbarHeight =
        NSHeight(newFrame) - NSHeight([[preferencesPanel contentView] frame]);

    if ( (sender == generalPreferences) &&
         ([preferencesPanel contentView] != generalPrefsView) )
    {
        newHeight = [generalPrefsView bounds].size.height;
        newWidth = [generalPrefsView bounds].size.width;
    }
    else if ( (sender == schematicPreferences) &&
              ([preferencesPanel contentView] != schematicPrefsView) )
    {
        newHeight = [schematicPrefsView bounds].size.height;
        newWidth = [schematicPrefsView bounds].size.width;
    }
    else if ( (sender == startupPreferences) &&
         ([preferencesPanel contentView] != startupPrefsView) )
    {
        newHeight = [startupPrefsView bounds].size.height;
        newWidth = [startupPrefsView bounds].size.width;
    }
    else if  ( (sender == simulatorPreferences) &&
               ([preferencesPanel contentView] != simulatorPrefsView) )
    {
        newHeight = [simulatorPrefsView bounds].size.height;
        newWidth = [simulatorPrefsView bounds].size.width;
    }
    else if ( (sender == fontPreferences) &&
              ([preferencesPanel contentView] != fontPrefsView) )
    {
        newHeight = [fontPrefsView bounds].size.height;
        newWidth = [fontPrefsView bounds].size.width;
    }
    else if ( (sender == plotterPreferences) &&
              ([preferencesPanel contentView] != plotterPrefsView) )
    {
        newHeight = [plotterPrefsView bounds].size.height;
        newWidth = [plotterPrefsView bounds].size.width;
    }
    else
        return;
    
    [preferencesPanel setContentView:emptyView];
    newFrame.origin.y += newFrame.size.height - toolbarHeight - newHeight;
    newFrame.size.height = newHeight + toolbarHeight;
    //newFrame.size.width = newWidth;
    newFrame =
        [NSWindow frameRectForContentRect:newFrame
                                styleMask:[preferencesPanel styleMask]];
    [preferencesPanel setFrame:newFrame
                       display:YES
                       animate:YES];

    if (sender == generalPreferences) {
        [preferencesPanel setContentView:generalPrefsView];
        [preferencesPanel setTitle:@"MI-SUGAR General Preferences"];
    }
    else if (sender == schematicPreferences) {
        [preferencesPanel setContentView:schematicPrefsView];
        [preferencesPanel setTitle:@"MI-SUGAR Schematic Preferences"];
    }
    else if (sender == startupPreferences) {
        [preferencesPanel setContentView:startupPrefsView];
        [preferencesPanel setTitle:@"MI-SUGAR Startup Preferences"];
    }
    else if (sender == simulatorPreferences) {
        [preferencesPanel setContentView:simulatorPrefsView];
        [preferencesPanel setTitle:@"MI-SUGAR Simulator Preferences"];
    }
    else if (sender == fontPreferences) {
        [preferencesPanel setContentView:fontPrefsView];
        [preferencesPanel setTitle:@"MI-SUGAR Font Preferences"];
    }
    else if (sender == plotterPreferences) {
        [preferencesPanel setContentView:plotterPrefsView];
        [preferencesPanel setTitle:@"MI-SUGAR Plotter Preferences"];
    }
}


/**************************** File Policies *********************/

- (IBAction) setConversionPolicy:(id)sender
{
    [[NSUserDefaults standardUserDefaults]
        setObject:[conversionPolicyChooser titleOfSelectedItem]
           forKey:MISUGAR_LINE_ENDING_CONVERSION_POLICY];
}

- (IBAction) setFileSavingPolicy:(id)sender
{
    [[NSUserDefaults standardUserDefaults]
        setObject:[NSNumber numberWithInteger:[fileSavingPolicyChooser indexOfSelectedItem]]
           forKey:MISUGAR_FILE_SAVING_POLICY];
}

/************************ License-related methods *********************/

- (IBAction) setLayout:(id)sender
{
    [[NSUserDefaults standardUserDefaults]
        setObject:[[layoutChooser selectedItem] title]
           forKey:MISUGAR_DOCUMENT_LAYOUT];
}

/*************** NSApplication delegate method *******************/

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication*)sender
{
    // save the size of the key document window (if any)
    [[NSDocumentController sharedDocumentController]
        closeAllDocumentsWithDelegate:nil
                  didCloseAllSelector:nil
                          contextInfo:nil];
    if (elementsPanel != nil)
    {
        [elementsPanel saveFrameUsingName:MISUGAR_ELEMENTS_PANEL_FRAME];
        [[NSUserDefaults standardUserDefaults]
            setObject:[NSNumber numberWithFloat:[elementsPanel alphaValue]]
               forKey:MISUGAR_ELEMENTS_PANEL_ALPHA];
    }

    [[MI_DeviceModelManager sharedManager] release]; // automatically saves device models
    
    [inspector release]; // this will save the size and position of the info panel

    return NSTerminateNow;
}

/***************************************** SCHEMATIC-RELATED METHODS ********/

- (IBAction) captureCurrentSchematic:(id)sender
{
  NSWindow* documentWindow = [NSApp mainWindow];
  if (documentWindow && [[documentWindow delegate] isKindOfClass:[CircuitDocument class]])
  {
    [[documentWindow delegate] performSelector:@selector(convertSchematicToNetlist:) withObject:sender];
  }
}


- (IBAction) goToSubcircuitsFolder:(id)sender
{
  NSString* libPath = [[NSUserDefaults standardUserDefaults] objectForKey:MISUGAR_SUBCIRCUIT_LIBRARY_FOLDER];
  [[NSWorkspace sharedWorkspace] openFile:libPath withApplication:@"Finder"];
  /* This dead code uses AppleScript and Core Foundation to open the subcircuit folder
  // Using Core Foundation URL functions to convert the subcircuit folder path from Unix to HFS representation
  CFURLRef ref = CFURLCreateWithFileSystemPath(NULL,
      CFStringCreateWithCString(NULL, [libPath cString], kCFStringEncodingUTF8),
      kCFURLPOSIXPathStyle, 1);
  CFStringRef hfs = CFURLCopyFileSystemPath(ref, kCFURLHFSPathStyle);
  CFIndex bufferSize = 4 * CFStringGetLength(hfs) + 1;
  char* hfsString = (char*) malloc((int)bufferSize);
  if (!CFStringGetCString(hfs, hfsString, bufferSize, kCFStringEncodingUTF8))
      NSLog(@"Error occured during conversion of subcircuit folder path from POSIX format to HFS format.");
  else
  {
    libPath = [NSString stringWithUTF8String:(const char*)hfsString];
    // Use AppleScript to open the Finder and direct it to the subcircuits folder
    NSDictionary** errorDict = NULL;
    NSString* command = [NSString stringWithFormat:
        @"tell application \"Finder\"\nreveal folder \"%@\"\nactivate\nend tell", libPath];
    NSAppleScript* subcktFolderOpenScript = [[NSAppleScript alloc] initWithSource:command];
    [subcktFolderOpenScript compileAndReturnError:errorDict];
    [subcktFolderOpenScript executeAndReturnError:errorDict];
    [subcktFolderOpenScript release];
  }
  free(hfsString);
  */
}


- (IBAction) refreshSubcircuitsTable:(id)sender
{
    [libManager refreshAll];
}


- (IBAction) showPlacementGuides:(id)sender
{
    [[NSNotificationCenter defaultCenter]
        postNotificationName:MISUGAR_PLACEMENT_GUIDE_VISIBILITY_CHANGE_NOTIFICATION
                      object:[NSNumber numberWithBool:([showPlacementGuides state] == NSOnState)]];
    [[NSUserDefaults standardUserDefaults]
            setObject:[NSNumber numberWithBool:([sender state] == NSOnState)]
               forKey:MISUGAR_SHOW_PLACEMENT_GUIDES];
}


- (IBAction) showInfoPanel:(id)sender
{
    [inspector toggleInfoPanel];
}


- (IBAction) showElementsPanel:(id)sender
{
    if (elementsPanel == nil)
        [self prepareElementsPanel];
    if ([elementsPanel isVisible])
        [elementsPanel orderOut:self];
    else
        [elementsPanel orderFront:self];
}


- (void) prepareElementsPanel
{
    float alpha = [[[NSUserDefaults standardUserDefaults] objectForKey:MISUGAR_ELEMENTS_PANEL_ALPHA] floatValue];
    NSArray* transistorArray = [NSArray arrayWithObjects:
        [[[MI_NPNTransistorElement alloc] init] autorelease],
        [[[MI_PNPTransistorElement alloc] init] autorelease],
        [[[MI_NJFETTransistorElement alloc] init] autorelease],
        [[[MI_PJFETTransistorElement alloc] init] autorelease],
        [[[MI_EnhancementNMOSTransistorElement alloc] init] autorelease],
        [[[MI_EnhancementPMOSTransistorElement alloc] init] autorelease],
        [[[MI_DepletionNMOSTransistorElement alloc] init] autorelease],
        [[[MI_DepletionPMOSTransistorElement alloc] init] autorelease],
        [[[MI_EnhancementNMOSwBulkTransistorElement alloc] init] autorelease],
        [[[MI_EnhancementPMOSwBulkTransistorElement alloc] init] autorelease],
        [[[MI_DepletionNMOSwBulkTransistorElement alloc] init] autorelease],
        [[[MI_DepletionPMOSwBulkTransistorElement alloc] init] autorelease],
        nil];
    NSArray* diodeArray = [NSArray arrayWithObjects:
        [[[MI_DiodeElement alloc] init] autorelease],
        [[[MI_ZenerDiodeElement alloc] init] autorelease],
        [[[MI_LightEmittingDiodeElement alloc] init] autorelease],
        [[[MI_PhotoDiodeElement alloc] init] autorelease],
        nil];
    NSArray* resistorArray = [NSArray arrayWithObjects:
        [[[MI_Resistor_US_Element alloc] init] autorelease],
        [[[MI_Resistor_IEC_Element alloc] init] autorelease],
        [[[MI_Rheostat_US_Element alloc] init] autorelease],
        [[[MI_Rheostat_IEC_Element alloc] init] autorelease],
        nil];
    NSArray* inductorArray = [NSArray arrayWithObjects:
        [[[MI_Inductor_US_Element alloc] init] autorelease],
        [[[MI_Inductor_IEC_Element alloc] init] autorelease],
        nil];
    NSArray* capacitorArray = [NSArray arrayWithObjects:
        [[[MI_CapacitorElement alloc] init] autorelease],
        [[[MI_PolarizedCapacitorElement alloc] init] autorelease],
        nil];
    NSArray* nodeArray = [NSArray arrayWithObjects:
        [[[MI_NodeElement alloc] init] autorelease],
        [[[MI_SpikyNodeElement alloc] init] autorelease],
        nil];
    NSArray* switchArray = [NSArray arrayWithObjects:
        [[[MI_VoltageControlledSwitchElement alloc] init] autorelease],
        [[[MI_Transformer_US_Element alloc] init] autorelease],
        [[[MI_Transformer_IEC_Element alloc] init] autorelease],
        [[[MI_TransmissionLineElement alloc] init] autorelease],
        nil];
    NSArray* groundArray = [NSArray arrayWithObjects:
        [[[MI_GroundElement alloc] init] autorelease],
        [[[MI_PlainGroundElement alloc] init] autorelease],
        nil];
    NSArray* powerSourceArray = [NSArray arrayWithObjects:
        [[[MI_DCVoltageSourceElement alloc] init] autorelease],
        [[[MI_ACVoltageSourceElement alloc] init] autorelease],
        [[[MI_PulseVoltageSourceElement alloc] init] autorelease],
        [[[MI_SinusoidalVoltageSourceElement alloc] init] autorelease],
        [[[MI_CurrentSourceElement alloc] init] autorelease],
        [[[MI_PulseCurrentSourceElement alloc] init] autorelease],
        [[[MI_VoltageControlledCurrentSource alloc] init] autorelease],
        [[[MI_VoltageControlledVoltageSource alloc] init] autorelease],
        [[[MI_CurrentControlledCurrentSource alloc] init] autorelease],
        [[[MI_CurrentControlledVoltageSource alloc] init] autorelease],
        [[[MI_NonlinearDependentSource alloc] init] autorelease],
        nil];
    MI_TextElement* te = [[MI_TextElement alloc] init];
    [te setFont:[NSFont fontWithName:@"Lucida Grande"
                                size:14.0f]];
    [te lock];
    NSArray* specialsArray = [NSArray arrayWithObjects:
        [te autorelease],
        nil];
    [NSBundle loadNibNamed:@"SchematicElementsPanel" owner:self];
    [transistorChooser setSchematicElementList:transistorArray];
    [diodeChooser setSchematicElementList:diodeArray];
    [resistorChooser setSchematicElementList:resistorArray];
    [inductorChooser setSchematicElementList:inductorArray];
    [capacitorChooser setSchematicElementList:capacitorArray];
    [nodeChooser setSchematicElementList:nodeArray];
    [groundChooser setSchematicElementList:groundArray];
    [sourceChooser setSchematicElementList:powerSourceArray];
    [switchChooser setSchematicElementList:switchArray];
    [specialElementChooser setSchematicElementList:specialsArray];

    [subcircuitsTable setDataSource:libManager];
    [subcircuitsTable setDelegate:libManager];
    [subcircuitsTable setTarget:libManager];
    [subcircuitsTable setDoubleAction:@selector(showDefinitionOfSelectedSubcircuit:)];
    [subcircuitsTable setBackgroundColor:[NSColor windowBackgroundColor]];

    [elementsPanel setBecomesKeyOnlyIfNeeded:YES];
    [elementsPanel setFloatingPanel:YES];
    [elementsPanel setAlphaValue:alpha];
    [panelTransparencyAdjustment setFloatValue:alpha];
    //[elementsPanel setMovableByWindowBackground:YES]; // causes havoc on drag & drop
    [elementsPanel setFrameUsingName:MISUGAR_ELEMENTS_PANEL_FRAME];
}


- (IBAction) showDeviceModelPanel:(id)sender
{
    [[MI_DeviceModelManager sharedManager] togglePanel];
}


- (IBAction) setElementsPanelTransparency:(id)sender
{
    float value = [sender floatValue];
    if (value > 1.0f)
        value = 1.0f;
    else if (value < 0.5f)
        value = 0.5f;
    [elementsPanel setAlphaValue:value];
}


- (IBAction) setNodeAutoInsertion:(id)sender
{
    [[NSUserDefaults standardUserDefaults]
        setObject:[NSNumber numberWithBool:([sender state] == NSOnState)]
           forKey:MISUGAR_AUTOINSERT_NODE_ELEMENT];
}


- (IBAction) setCanvasBackgroundColor:(id)sender
{
    NSColorPanel* cp = [NSColorPanel sharedColorPanel];
    [cp setTarget:self];
    [cp setAction:@selector(changeCanvasBackgroundColor:)];
    [cp makeFirstResponder:nil];
    [cp setDelegate:self];
    [cp setColor:[schematicCanvasBackground color]];
    [NSColorPanel setPickerMode:NSColorPanelModeHSB];
    [cp makeKeyAndOrderFront:self];
}


- (void) changeCanvasBackgroundColor:(id)sender
{
    [schematicCanvasBackground setColor:[sender color]];
    [[NSUserDefaults standardUserDefaults]
        setObject:[NSKeyedArchiver archivedDataWithRootObject:[sender color]]
           forKey:MISUGAR_SCHEMATIC_CANVAS_BACKGROUND_COLOR];
    // Notify all windows
    [[NSNotificationCenter defaultCenter]
        postNotificationName:MISUGAR_CANVAS_BACKGROUND_CHANGE_NOTIFICATION
                      object:[sender color]];
}


- (MI_Tool*) currentTool
{
    return currentTool;
}


- (MI_SubcircuitLibraryManager*) subcircuitLibraryManager
{
    return libManager;
}


/**************************************************************************/

// The delegate method of the tab view in the elements panel.
// Causes the elements panel to be stretched when showing the subcircuit list.
- (void)tabView:(NSTabView *)tabView
willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if (tabView == elementCategoryChooser)
    {
        float oldHeight = [elementsPanel frame].size.height;
        float newHeight = [[tabViewItem identifier] isEqualToString:@"basic"] ? 300.0f : 450.0f;
        
        [elementCategoryChooser setHidden:YES];
        
        [elementsPanel setFrame:NSMakeRect([elementsPanel frame].origin.x,
                                           [elementsPanel frame].origin.y + oldHeight - newHeight,
                                           [elementsPanel frame].size.width,
                                           newHeight)
                        display:YES
                        animate:YES];
        
        [elementCategoryChooser setHidden:NO];
    }
}


+ (NSString*) supportFolder
{
    NSString* theSupportFolder = nil;
    
    NSArray* appSupportDirectories = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    if ( [appSupportDirectories count] > 0 )
    {
        theSupportFolder = [[appSupportDirectories objectAtIndex:0] stringByAppendingPathComponent:@"Volta"];
    }
    else
    {
        theSupportFolder = NSHomeDirectory();
    }
    return theSupportFolder;
}


- (void) dealloc
{
    [MISUGAR_BuiltinSPICEPath release];
    [selectTool release];
    [scaleTool release];
    [libManager release];
    managerInstance = nil;
    [super dealloc];
}

@end

