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
#include "common.h"
#import "CircuitDocument.h"
#import "SpiceASCIIOutputReader.h"
#import "SugarPlotter.h"
#import "ResultsTable.h"
#import "Converter.h"
#import "SugarManager.h"
#import "MI_DeviceModelManager.h"
#import "MI_CircuitElementDeviceModel.h"
#import "MI_SubcircuitDocumentModel.h"
#import "MI_SubcircuitCreator.h"
#import "MI_CircuitDocumentPrinter.h"
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

#define PLOT_CUSTOM_SIMULATOR_RESULTS
// above define is needed for allowing plotting of results from custom simulators

NSString* MISUGAR_RunItem                        = @"Analyze";
NSString* MISUGAR_PlotItem                       = @"Plot";
NSString* MISUGAR_Schematic2NetlistItem          = @"Capture";
NSString* MISUGAR_ElementsPanelItem              = @"ShowElementsPanel";
NSString* MISUGAR_InfoPanelItem                  = @"ShowInfoPanel";
NSString* MISUGAR_CanvasScaleSliderItem          = @"canvas scale";
NSString* MISUGAR_CanvasZoomInItem               = @"canvas zoom in";
NSString* MISUGAR_CanvasZoomOutItem              = @"canvas zoom out";
NSString* MISUGAR_SchematicVariantDisplayerItem  = @"schematic variant";
NSString* MISUGAR_SchematicHomePositionItem      = @"schematic home position";
NSString* MISUGAR_FitToViewItem                  = @"fit to view";
NSString* MISUGAR_SubcircuitIndicatorItem        = @"subcircuit indicator";
NSString* NETLIST                                = @"circuit description file type";
NSString* SUGAR_FILE_TYPE                        = @"SugarFileType";
NSString* SPICE_Raw                              = @"SPICE raw output";

@implementation CircuitDocument

- (instancetype) init
{
    if (self = [super init]) {
        // If an error occurs here, send a [self dealloc] message and return nil.
        myModel = [[CircuitDocumentModel alloc] init];
        textEdited = NO;
        hasVerticalLayout = YES;
        printAttributes = nil;
        commentAttributes = nil;
        analysisCommandAttributes = nil;
        printAttributes = nil;
        modelAttributes = nil;
        subcircuitAttributes = nil;
        highlightingAttributesCreated = NO;
        [self setFileType:SUGAR_FILE_TYPE];
        simulationTask = nil;
        run = nil;
        plot = nil;
        schematic2Netlist = nil;
        canvasScaler = nil;
        elementsPanelShortcut = nil;
        infoPanelShortcut = nil;
        variantDisplayer = nil;
        analysisProgressIndicator = nil;
        fitToView = nil;
        home = nil;
        subcircuitIndicator = nil;
        zoomIn = zoomOut = nil;
        scaleHasChanged = NO;
    }
    return self;
}


- (instancetype) initWithContentsOfFile:(NSString *)fileName ofType:(NSString *)docType
{
  self = [self init];
  if ( ([[fileName pathExtension] caseInsensitiveCompare:@"cir"] == NSOrderedSame) ||
       ([[fileName pathExtension] caseInsensitiveCompare:@"ckt"] == NSOrderedSame) )
      [self readFromFile:fileName
                  ofType:NETLIST];
  else if ([[fileName pathExtension] caseInsensitiveCompare:@"sugar"] == NSOrderedSame)
      [self readFromFile:fileName
                  ofType:SUGAR_FILE_TYPE];
  return self;
}


- (NSString*) windowNibName
{
    /* Override returning the nib file name of the document
       If you need to use a subclass of NSWindowController or if your document
       supports multiple NSWindowControllers, you should remove this method and
       override -makeWindowControllers instead. */
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:MISUGAR_DOCUMENT_LAYOUT] isEqualToString:@"Vertical"])
        return @"CircuitDocument";
    else
        return @"CircuitDocument2";
}


- (void) windowControllerDidLoadNib:(NSWindowController*)aController
{
    // Note: The window is not visible yet. This method prepares it for display.
    // This method is called after the opened file is read.
    NSToolbar* toolbar;
    MI_Window* myWindow = (MI_Window*)[[[self windowControllers] objectAtIndex:0] window];
    NSUserDefaults* userdefs = [NSUserDefaults standardUserDefaults];
    [super windowControllerDidLoadNib:aController];
    /* Register with inputView as drop handler */
    [inputView setDropHandler:self];
    [myWindow setDropHandler:self];
    /* Build toolbar */
    variantSelectionViewer = [[MI_VariantSelectionView alloc] init];
    [variantSelectionViewer setSelectedVariant:0];
    toolbar = [[NSToolbar alloc] initWithIdentifier:@"SugarMainDocumentWindowToolbar"];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [toolbar setDelegate:self];
    [myWindow setToolbar:toolbar];
    /* Get the window size of the last session */
    [myWindow setFrameUsingName:MISUGAR_DOCUMENT_WINDOW_FRAME];
    // text view settings
    [inputView setAllowsUndo:YES];
    [inputView setRichText:YES];
    [inputView setUsesFontPanel:NO];
    //[[inputView textContainer] setLineFragmentPadding:10.0f];

    // no line wrapping in netlist editor
    [[inputView textContainer] setWidthTracksTextView:NO];
    [[inputView textContainer] setHeightTracksTextView:NO];
    [[inputView textContainer] setContainerSize:NSMakeSize(20000, 10000000)];
    [inputView setHorizontallyResizable:YES];
    [inputView setVerticallyResizable:YES];
    [inputView setMaxSize:NSMakeSize(100000, 100000)];
    [inputView setMinSize:[[inputView enclosingScrollView] contentSize]];
    
    [self updateViews];
    // Set text fonts
    [inputView setFont:
        [NSFont fontWithName:[userdefs objectForKey:MISUGAR_SOURCE_VIEW_FONT_NAME]
                        size:[[userdefs objectForKey:MISUGAR_SOURCE_VIEW_FONT_SIZE] floatValue]]];
    [shellOutputView setFont:
        [NSFont fontWithName:[userdefs objectForKey:MISUGAR_RAW_OUTPUT_VIEW_FONT_NAME]
                        size:[[userdefs objectForKey:MISUGAR_RAW_OUTPUT_VIEW_FONT_SIZE] floatValue]]];
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(setFont:) name:MISUGAR_FONT_CHANGE_NOTIFICATION object:nil];
    [nc addObserver:self selector:@selector(placementGuideVisibilityChanged:) name:MISUGAR_PLACEMENT_GUIDE_VISIBILITY_CHANGE_NOTIFICATION object:nil];
    [nc addObserver:self selector:@selector(canvasBackgroundChanged:) name:MISUGAR_CANVAS_BACKGROUND_CHANGE_NOTIFICATION object:nil];
    
    // Schematic initialization

    //[canvasScaleAdjustment setMaxValue:MI_SCHEMATIC_CANVAS_MAX_SCALE];
    //[canvasScaleAdjustment setMinValue:MI_SCHEMATIC_CANVAS_MIN_SCALE];
    //[canvasScaleAdjustment setFloatValue:1.0f];

    [canvas setFrameSize:NSMakeSize(1600, 1200)];
    [canvas setController:self];
    [canvas setBackgroundColor:[NSKeyedUnarchiver unarchiveObjectWithData:[userdefs objectForKey:MISUGAR_SCHEMATIC_CANVAS_BACKGROUND_COLOR]]];
    
    // Set sizes of splitter's subviews.
    hasVerticalLayout = [[userdefs objectForKey:MISUGAR_DOCUMENT_LAYOUT] isEqualToString:@"Vertical"];
    if (hasVerticalLayout)
    {
        // For vertical layout
        NSRect tmpFrame;
        float netHeight = [splitter frame].size.height - 2 * [splitter dividerThickness];
        float fraction = [[userdefs objectForKey:MISUGAR_DOCUMENT_FRACTIONAL_SIZE_OF_CANVAS] floatValue];
        tmpFrame = [canvas frame];
        tmpFrame.size.height = (fraction < 0.1f) ? 0.0f : netHeight * fraction;
        [canvas setFrame:tmpFrame];
        tmpFrame = [[[inputView enclosingScrollView] superview] frame];
        fraction = [[userdefs objectForKey:MISUGAR_DOCUMENT_FRACTIONAL_HEIGHT_OF_NETLIST_FIELD] floatValue];
        tmpFrame.size.height = (fraction < 0.1f) ? 0.0f : netHeight * fraction;
        [[[inputView enclosingScrollView] superview] setFrame:tmpFrame];
        tmpFrame = [[shellOutputView enclosingScrollView] frame];
        fraction = [[userdefs objectForKey:MISUGAR_DOCUMENT_FRACTIONAL_HEIGHT_OF_OUTPUT_FIELD] floatValue];
        tmpFrame.size.height = (fraction < 0.1f) ? 0.0f : netHeight * fraction;
        [[shellOutputView enclosingScrollView] setFrame:tmpFrame];
        [splitter adjustSubviews];
        [splitter setNeedsDisplay:YES];
    }
    else 
    {
        // For horizontal layout
        NSRect tmpFrame;
        float netWidth = [verticalSplitter frame].size.width - [verticalSplitter dividerThickness];
        float netHeight = [horizontalSplitter frame].size.height - [horizontalSplitter dividerThickness];
        float fraction = [[userdefs objectForKey:MISUGAR_DOCUMENT_FRACTIONAL_SIZE_OF_CANVAS] floatValue];
        tmpFrame = [canvas frame];
        tmpFrame.size.width = (fraction < 0.1f) ? 0.0f : netWidth * fraction;
        [canvas setFrame:tmpFrame];
        tmpFrame = [[[shellOutputView enclosingScrollView] superview] frame];
        tmpFrame.size.width = (fraction < 0.1f) ? netWidth : (netWidth - netWidth * fraction);
        [[[shellOutputView enclosingScrollView] superview] setFrame:tmpFrame];
        tmpFrame = [[[inputView enclosingScrollView] superview] frame];
        fraction = [[userdefs objectForKey:MISUGAR_DOCUMENT_FRACTIONAL_HEIGHT_OF_NETLIST_FIELD] floatValue];
        tmpFrame.size.height = (fraction < 0.1f) ? 0.0f : netHeight * fraction;
        [[[inputView enclosingScrollView] superview] setFrame:tmpFrame];
        tmpFrame = [[shellOutputView enclosingScrollView] frame];
        fraction = [[userdefs objectForKey:MISUGAR_DOCUMENT_FRACTIONAL_HEIGHT_OF_OUTPUT_FIELD] floatValue];
        tmpFrame.size.height = (fraction < 0.1f) ? 0.0f : netHeight * fraction;
        [[shellOutputView enclosingScrollView] setFrame:tmpFrame];
        [horizontalSplitter adjustSubviews];
        [verticalSplitter adjustSubviews];
        [horizontalSplitter setNeedsDisplay: YES];
        [verticalSplitter setNeedsDisplay: YES];
    }

    // Start listening to changes in the new schematic
    [[NSNotificationCenter defaultCenter]
                    addObserver:self
                       selector:@selector(processSchematicChange:)
                           name:MI_SCHEMATIC_MODIFIED_NOTIFICATION
                         object:[myModel schematic]];
}


- (CircuitDocumentModel*) model
{
    return myModel;
}


- (void) setModel:(CircuitDocumentModel*)newModel
{
    myModel = newModel;
    [self updateViews];
}


- (void) updateViews
{
    if ([myModel source] != nil)
    {
        [inputView setString:[myModel source]];
        [self highlightInput];
    }
    else
        [inputView setString:@""];
    
    [canvas setScale:[myModel schematicScale]];
    [canvasScaleSlider setFloatValue:[myModel schematicScale]];
    [canvas setViewportOffset:[myModel schematicViewportOffset]];
    [canvas setNeedsDisplay:YES];
    
    // update schematic variant view
    [variantSelectionViewer setSelectedVariant:[myModel activeSchematicVariant]];
}


- (BOOL) writeToURL:(NSURL *)absoluteURL
             ofType:(NSString *)typeName
              error:(NSError **)outError
{
  if ([absoluteURL isFileURL])
  {
    /*
     The document type set for the target was changed from "SugarFileType" to
     "DocumentType" when upgrading to Xcode 2. This broke file saving.
     When I introduced the workaround below I was not aware that correcting
     the registered document type in the target info properties dialog would
     equally fix the problem. The code is still here, just in case, but should
     be removed.
     */
    if ([typeName isEqualToString:@"DocumentType"])
    {
      typeName = SUGAR_FILE_TYPE;
    }
    return [self _writeToFile:[absoluteURL path] ofType:typeName];
  }
  return NO;
}


- (BOOL) _writeToFile:(NSString*)filename ofType:(NSString*)aType
{
  if ([aType isEqualToString:SUGAR_FILE_TYPE])
  {
    NSMutableData* data = [NSMutableData data];
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    BOOL success;
    if (![myModel circuitName] || [[myModel circuitName] length] == 0)
        [myModel setCircuitName:[[filename stringByDeletingPathExtension] lastPathComponent]];
    [myModel setSchematicViewportOffset:[canvas viewportOffset]];
    [archiver encodeObject:[NSNumber numberWithInt:MISUGAR_DOCUMENT_VERSION] forKey:@"Version"];
    [archiver encodeObject:myModel forKey:@"MI-SUGAR Document Model"];
    [archiver encodeObject:[myModel circuitDeviceModels] forKey:@"MI-SUGAR Circuit Device Models"];
    [archiver finishEncoding];
    success = [data writeToFile:filename atomically:YES];
    [[myModel schematic] markAsModified:!success];
    [self markWindowContentAsModified:!success];
    if (success)
    {
        textEdited = NO;
        scaleHasChanged = NO;
    }
    return success;
  }
  else if ([aType isEqualToString:NETLIST])
  {
    [[myModel source] writeToFile:filename atomically:YES encoding:NSASCIIStringEncoding error:NULL];
    textEdited = NO;
    return YES;
  }
  else if ([aType isEqualToString:SPICE_Raw])
  {
    [[myModel rawOutput] writeToFile:filename atomically:YES encoding:NSASCIIStringEncoding error:NULL];
    return YES;
  }
  return NO;
}


- (BOOL) readFromFile:(NSString*)fileName
               ofType:(NSString*)aType
{
    if ([aType isEqualToString:NETLIST])
    {
        NSDictionary* fileAttribs = [[NSFileManager defaultManager]
            fileAttributesAtPath:fileName
                    traverseLink:YES];
        if (fileAttribs != nil)
        {
            if ([[fileAttribs objectForKey:NSFileSize] intValue] < 262144 /* = 256 KB */)
            {
                NSUInteger f1, f2;
                NSString* fileContent = [NSString stringWithContentsOfFile:fileName];
                NSMutableString* filteredContent =
                    [NSMutableString stringWithCapacity:[fileContent length]];
                [filteredContent setString:fileContent];
                // Replace CR+LF combinations with LF
                f1 = [filteredContent replaceOccurrencesOfString:@"\r\n"
                                                      withString:@"\n"
                                                         options:0
                                                           range:NSMakeRange(0, [filteredContent length])];
                // Replace remaining Windows-style CRs with LFs
                f2 = [filteredContent replaceOccurrencesOfString:@"\r"
                                                      withString:@"\n"
                                                         options:0
                                                           range:NSMakeRange(0, [filteredContent length])];
                if (f1 || f2)
                {
                    BOOL convertTheFile = NO;
                    NSString* policy = [[NSUserDefaults standardUserDefaults] objectForKey:MISUGAR_LINE_ENDING_CONVERSION_POLICY];
                    if ([policy isEqualToString:@"Ask"])
                        convertTheFile = (NSRunInformationalAlertPanel(@"Incompatible Character(s) Found",
                            @"This file contains Windows-style line ending characters that may produce errors when running SPICE. The content has been converted for this session. Do you want me to save the converted version to the original file?",
                            @"Yes", @"No", nil) == NSAlertDefaultReturn);
                    else if ([policy isEqualToString:@"Always"])
                        convertTheFile = YES;
                    if (convertTheFile)
                    {
                        if (![filteredContent writeToFile:fileName
                                               atomically:NO])
                            NSRunInformationalAlertPanel(@"File Save Error",
                                @"An error occured while attempting to save the converted version to the original file.", nil, nil, nil);
                    }
                }
                [myModel setSource:[NSString stringWithString:filteredContent]];
                [myModel setRawOutput:nil];
                [self setFileName:fileName];
                [self setFileType:NETLIST];
                // Add this file to the list of recent files
                [[NSDocumentController sharedDocumentController]
                    noteNewRecentDocumentURL:[NSURL fileURLWithPath:fileName]];
                return YES;
            }
            else
                NSBeginAlertSheet(nil, nil, nil, nil, window, nil, nil, nil,
                    nil, @"The file is too large to be a circuit description!");
        }
        else
            NSBeginAlertSheet(nil, nil, nil, nil, window, nil,  nil, nil,
                nil, @"The file does not exist!");
    }
    else if ([aType isEqualToString:SUGAR_FILE_TYPE])
    {
        CircuitDocumentModel* newModel;
        int fileVersion;
        NSArray* deviceModels;
    NS_DURING
        NSMutableData* data = [NSData dataWithContentsOfFile:fileName];
        if (data == nil)
            return NO;
        NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        
        // Convert or purge deprecated classes
        [unarchiver setClass:[MI_MOSDeviceModel class]
                forClassName:@"MI_BSIM3_MOSDeviceModel"];
        [unarchiver setClass:[MI_MOSDeviceModel class]
                forClassName:@"MI_BSIM4_NMOSDeviceModel"];
        [unarchiver setClass:[MI_MOSDeviceModel class]
                forClassName:@"MI_BSIM4_PMOSDeviceModel"];
        
        fileVersion = [[unarchiver decodeObjectForKey:@"Version"] intValue];
        newModel = [unarchiver decodeObjectForKey:@"MI-SUGAR Document Model"];
        deviceModels = [unarchiver decodeObjectForKey:@"MI-SUGAR Circuit Device Models"];
        [unarchiver finishDecoding];
    NS_HANDLER
        NSBeginInformationalAlertSheet(@"Invalid or corrupt file.",
            nil, nil, nil, window, nil, nil, nil, nil,
            @"Could not load %@. It was probably created by a newer version of MI-SUGAR and contains objects unknown to this version. It may also have been corrupted or maybe it's not a MI-SUGAR file at all.", fileName);
        return NO;
    NS_ENDHANDLER
        if ([newModel isKindOfClass:[CircuitDocumentModel class]])
        {
            if (fileVersion > MISUGAR_DOCUMENT_VERSION)
            {
                if (NSRunAlertPanel(@"Encountered newer file version.",
                    @"%@ has been created by a newer version of MI-SUGAR. You may experience problems with this file.",
                     @"Abort", @"Open Anyway", nil, fileName) == NSOKButton)
                    return NO;
            }
            [self setModel:newModel];
            [myModel setRawOutput:nil];
            // If the opened file includes new device models they are added to the local repository
            [[MI_DeviceModelManager sharedManager] importDeviceModels:deviceModels];
            [self setFileType:SUGAR_FILE_TYPE];
            [self setFileName:fileName];
            // Add this file to the list of recent files
            [[NSDocumentController sharedDocumentController]
                    noteNewRecentDocumentURL:[NSURL fileURLWithPath:fileName]];
            // Go on to open the document NIB file
            return YES;
        }
        else
            NSBeginInformationalAlertSheet(@"Invalid file format.",
                nil, nil, nil, window, nil, nil, nil, nil,
                @"This file is not in a format which MI-SUGAR understands.");
    }
    return NO;
}


- (void) processDrop:(id <NSDraggingInfo>)sender
{
  // A file is dropped onto the document window
  NSString *pathToDroppedFile = [[[sender draggingPasteboard] propertyListForType:@"NSFilenamesPboardType"] objectAtIndex:0];
  if ( ([[pathToDroppedFile pathExtension] caseInsensitiveCompare:@"cir"] == NSOrderedSame) ||
       ([[pathToDroppedFile pathExtension] caseInsensitiveCompare:@"ckt"] == NSOrderedSame) )
  {
    [self readFromURL:[NSURL fileURLWithPath:pathToDroppedFile] ofType:NETLIST error:NULL];
  }
  else if ([[pathToDroppedFile pathExtension] caseInsensitiveCompare:@"sugar"] == NSOrderedSame)
  {
    [self readFromURL:[NSURL fileURLWithPath:pathToDroppedFile] ofType:SUGAR_FILE_TYPE error:NULL];
  }
}


// NSTextView delegate method
- (void) textDidChange:(NSNotification*)aNotification
{
    [myModel setSource:[inputView string]];
    [self highlightInput];
    if (![run isEnabled]) [run setEnabled:YES];
    textEdited = YES;
}


- (BOOL) isDocumentEdited
{
    return [[myModel schematic] hasBeenModified] || textEdited || scaleHasChanged;
}


- (IBAction) convertSchematicToNetlist:(id)sender
{
    NSString* myNetlist = [myModel source];
    NSString *line, *lcline;
    NSMutableString* dotLines = [NSMutableString stringWithCapacity:100];
    NSUInteger lineStart = 0, nextLineStart, lineEnd;
    NSUInteger limit = [myNetlist length];
    
    if ([myModel isKindOfClass:[MI_SubcircuitDocumentModel class]])
    {
        // This is a subcircuit - no analysis commands are used
        NSMutableString* newNetlist = [NSMutableString stringWithCapacity:100];
        // Preserve comment lines - lump them together and put on top
        if ([[myModel source] length] > 0)
        {
            while (lineStart < limit)
            {
                [myNetlist getLineStart:&lineStart
                                    end:&nextLineStart
                            contentsEnd:&lineEnd
                               forRange:NSMakeRange(lineStart, 1)];
                line = [myNetlist substringWithRange:NSMakeRange(lineStart, lineEnd - lineStart)];
                lineStart = nextLineStart;
                if ([line hasPrefix:@"*"])
                    [newNetlist appendFormat:@"%@\n", line];
            }
        }
        if ([newNetlist length] == 0)
            [newNetlist appendFormat:@"* %@\n", [[NSDate date] description]];
        [newNetlist appendString:[Converter schematicToNetlist:myModel]];
        [myModel setSource:[NSString stringWithString:newNetlist]];
    }
    else
    {
        // Update netlist without modifying the control lines
        NSMutableString* newContent = [NSMutableString stringWithCapacity:200];
        
        if ([[myModel source] length] > 0)
        {
            // Preserve all control lines
            while (lineStart < limit)
            {
                [myNetlist getLineStart:&lineStart
                                    end:&nextLineStart
                            contentsEnd:&lineEnd
                               forRange:NSMakeRange(lineStart, 1)];
                line = [myNetlist substringWithRange:NSMakeRange(lineStart, lineEnd - lineStart)];
                if (lineStart == 0)
                    [newContent appendFormat:@"%@\n", line];
                lineStart = nextLineStart;

                lcline = [line lowercaseString];
                if ([lcline hasPrefix:@".op"] ||
                    [lcline hasPrefix:@".dc"] ||
                    [lcline hasPrefix:@".nodeset"] ||
                    [lcline hasPrefix:@".ic"] ||
                    [lcline hasPrefix:@".tf"] ||
                    [lcline hasPrefix:@".ac"] ||
                    [lcline hasPrefix:@".disto"] ||
                    [lcline hasPrefix:@".noise"] ||
                    [lcline hasPrefix:@".tran"] ||
                    [lcline hasPrefix:@".pz"] ||
                    [lcline hasPrefix:@".four"] ||
                    [lcline hasPrefix:@".print"] ||
                    [lcline hasPrefix:@".include"]
                    )
                    [dotLines appendFormat:@"%@\n", line];
            }
            [newContent appendString:dotLines];
        }
        else
            [newContent appendFormat:@"* %@\n", [[NSDate date] description]];

        [newContent appendString:[Converter schematicToNetlist:myModel]];
        [newContent appendString:@"\n.end\n"];
        [myModel setSource:newContent];
    }
    [inputView setString:[myModel source]];
    [self highlightInput];
    textEdited = YES;
}


/*
 This implementation uses POSIX system calls for interprocess communication
 instead of Cocoa's object-oriented wrappers (NSTask, NSPipe, etc.).
*/
- (IBAction) runSimulator:(id)sender
{
  if ([simulationTask isRunning])
  {
    [self abortSimulation:nil];
  }
  else
  {
    NSString *simulatorPath, *simulatorInput;
    BOOL usingCustomSimulator, usingGnucap;
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

    simulationDataPipe = [[NSPipe alloc] init];

    // Start animating the progress indicator
    [NSThread detachNewThreadSelector:@selector(startAnimation)
                             toTarget:analysisProgressIndicator
                           withObject:nil];

    // Get the SPICE command
    usingGnucap = NO;
    usingCustomSimulator = [[defaults objectForKey:MISUGAR_USE_CUSTOM_SIMULATOR] boolValue];
    simulatorPath = usingCustomSimulator ? (NSString*)[defaults objectForKey:MISUGAR_CUSTOM_SIMULATOR_PATH] : MISUGAR_BuiltinSPICEPath;

    // Clear the output view
    [shellOutputView setString:@""];
    if (!usingCustomSimulator && usingGnucap)
        simulatorInput = [myModel gnucapFilteredSource];
    else
        simulatorInput = [myModel spiceFilteredSource];

    /* Creating a temporary file with the contents of the text area... */
    NSString* tmpFile = [NSString stringWithFormat:@"/tmp/%d.misugar.in", [[NSProcessInfo processInfo] processIdentifier]];
    [simulatorInput writeToFile:tmpFile atomically:NO encoding:NSASCIIStringEncoding error:NULL];

    simulationTask = [[NSTask alloc] init];
    [simulationTask setLaunchPath:simulatorPath];
    if (usingCustomSimulator || !usingGnucap)
    {
        // Execute SPICE command
        [simulationTask setArguments:[NSArray arrayWithObjects:
                                    @"-b", // batch mode
                                    //@"-r", // generate raw output file
                                    //@"/tmp/misugar.out" // output file
                                    tmpFile, // input file
                                    nil]];
        /*
            perror("Error while trying to execute SPICE (or a SPICE-compatible simulator).");
            fprintf(stderr, "Check the path to the custom simulator in the preferences panel!\n");
            fprintf(stderr, "command: %s\n", (const char*)[[simulatorPath dataUsingEncoding:NSASCIIStringEncoding] bytes]);
        */
    }
    else
    {
        // Execute Gnucap command
        [simulationTask setArguments:[NSArray arrayWithObjects:
                                     @"-b", // batch mode
                                     tmpFile, // input file
                                     nil]];
        /*
            perror("Error while trying to execute Gnucap");
        */
    }
    // Set up the environment for unbuffered data piping
    NSMutableDictionary* environment = [NSMutableDictionary dictionaryWithDictionary:
        [[NSProcessInfo processInfo] environment]];
    [environment setObject:@"YES"
                    forKey:@"NSUnbufferedIO"];
    [simulationTask setEnvironment:environment];
    // Redirect standard output and standard error to the pipe input
    [simulationTask setStandardError:[simulationDataPipe fileHandleForWriting]];
    [simulationTask setStandardOutput:[simulationDataPipe fileHandleForWriting]];
    // Set up simulation output handler
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(simulationOutputAvailable:)
               name:NSFileHandleReadCompletionNotification
             object:[simulationDataPipe fileHandleForReading]];
    // Set up simulation end handler
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(endSimulation:)
               name:NSTaskDidTerminateNotification
             object:simulationTask];
    simulationAborted = NO;
    // Launch sub-process
    [simulationTask launch];
    [[simulationDataPipe fileHandleForReading] readInBackgroundAndNotify];
  }
}


- (void) simulationOutputAvailable:(NSNotification*)aNotification
{
    if (simulationAborted)
        return;
    
    NSString* readData = [[NSString alloc] initWithData:[[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem]
                                                encoding:NSASCIIStringEncoding];
    if (readData && [readData length])
        [shellOutputView replaceCharactersInRange:NSMakeRange([[shellOutputView textStorage] length], 0)
                                       withString:readData];
    else if (![simulationTask isRunning])
    {
      simulationDataPipe = nil;
      return;
    }
    [[simulationDataPipe fileHandleForReading] readInBackgroundAndNotify];
}


- (void) endSimulation:(NSNotification*)aNotification
{
  if (simulationTask == [aNotification object])
  {
    [self _cleanUpSimulationInputFile];
    [analysisProgressIndicator stopAnimation];
    [myModel setOutput:[shellOutputView string]];
    [plot setEnabled:YES];
  }
}


- (IBAction) abortSimulation:(id)sender
{
  if (simulationTask)
  {
    [simulationTask terminate];
  }
  simulationAborted = YES;

  [self _cleanUpSimulationInputFile];

  // Stop animating the progress indicator
  [analysisProgressIndicator stopAnimation];
  [shellOutputView setString:@"Simulation aborted."];

  [plot setEnabled:NO];
}

- (void) _cleanUpSimulationInputFile
{
  NSString* inputFilePath = [NSString stringWithFormat:@"/tmp/%d.misugar.in", [[NSProcessInfo processInfo] processIdentifier]];
  [[NSFileManager defaultManager] removeItemAtPath:inputFilePath error:NULL];
}


- (void) nothingToPlotAlertDidEnd:(NSAlert*)alert
                       returnCode:(int)returnCode
                      contextInfo:(void*)contextInfo
{
    [[alert window] orderOut:self];
}


- (IBAction) plotResults:(id)sender
{
    SugarPlotter* plotter;
    NSMutableArray *filteredResults;
    NSUserDefaults* userdefs = [NSUserDefaults standardUserDefaults];
    int k;
#ifndef PLOT_CUSTOM_SIMULATOR_RESULTS
    if ([[userdefs objectForKey:MISUGAR_USE_CUSTOM_SIMULATOR] boolValue])
        return;
    else
#endif
    NSArray* analysisResults = [SpiceASCIIOutputReader readFromModel:myModel];
    // Remove analyses with less than 2 points (operating points, for example)
    filteredResults = [NSMutableArray arrayWithCapacity:1];
    for (k = 0; k < (int)[analysisResults count]; k++)
    {
        if ([[[analysisResults objectAtIndex:k] variableAtIndex:0] numberOfValuesPerSet] > 1)
            [filteredResults addObject:[analysisResults objectAtIndex:k]];
    }

    if ( [filteredResults count] > 0 )
    {
        // Create new SugarPlotter object with current results table array
        plotter = [[SugarPlotter alloc] initWithPlottingData:filteredResults];

        // Check settings to see if old plot windows must be removed
        if ([[userdefs objectForKey:MISUGAR_PLOTTER_CLOSES_OLD_WINDOW] boolValue])
        {
            NSArray* wcs = [self windowControllers];
            if ([wcs count] > 1)
            {
              for (long a = [wcs count] - 1; a > 0; --a)
              {
                [[((NSWindowController*)[wcs objectAtIndex:a]) window] performClose:self];
              }
            }
        }

        /* The plots should not be part of the document - disabled since version 0.5.6
         NSWindowController* wcont = [[NSWindowController alloc] initWithWindow:[plotter window]];
         [self addWindowController:wcont];
         // The plotter is aware of this document window so we get notified
         // when the plot window is closed and can remove it from the window
         // controller list
         [plotter setWindowController:wcont];
         */
    }
    else
    {
      // Notify user
      NSAlert* nothingToPlotAlert = [NSAlert alertWithMessageText:@"Nothing to plot." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The plotter needs at least two data points. DC analysis results, for example, consist of a single value for which plotting makes no sense."];
      NSWindow* hostWindow = [[[self windowControllers] objectAtIndex:0] window];
      [nothingToPlotAlert beginSheetModalForWindow:hostWindow modalDelegate:self didEndSelector:@selector(nothingToPlotAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    }
}


- (void) setFont:(NSNotification*)notification
{
    NSUserDefaults* userdefs = [NSUserDefaults standardUserDefaults];
    if ([[notification object] boolValue])
    {
        // Set the font of the source view
        [inputView setFont:
            [NSFont fontWithName:[userdefs objectForKey:MISUGAR_SOURCE_VIEW_FONT_NAME]
                            size:[[userdefs objectForKey:MISUGAR_SOURCE_VIEW_FONT_SIZE] floatValue]]];
        [self highlightInput];
    }
    else
    {
        // Also set the font of the shell output view
        [shellOutputView setFont:
            [NSFont fontWithName:[userdefs objectForKey:MISUGAR_RAW_OUTPUT_VIEW_FONT_NAME]
                            size:[[userdefs objectForKey:MISUGAR_RAW_OUTPUT_VIEW_FONT_SIZE] floatValue]]];
    }
}


- (void) highlightInput
{
    NSString* tmp; // the input string
    NSString* line; // a single line
    NSUInteger lineStart = 0, nextLineStart, lineEnd;
    NSDictionary* previousAttributes = nil;
    if (!highlightingAttributesCreated)
    {
      //NSColor* darkGreen = [NSColor colorWithDeviceRed:0.0 green:0.4 blue:0.0 alpha:1.0];
      NSColor* darkRed = [NSColor colorWithDeviceRed:0.4 green:0.0 blue:0.0 alpha:1.0];
      NSColor* darkBlue = [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.4 alpha:1.0];
      NSColor* lightGrey = [NSColor colorWithDeviceRed:0.7 green:0.7 blue:0.7 alpha:1.0];
      NSColor* darkYellow = [NSColor colorWithDeviceRed:0.5 green:0.4 blue:0.0 alpha:1.0];
      NSColor* orange = [NSColor colorWithDeviceRed:0.81 green:0.45 blue:0.14 alpha:1.0];
      analysisCommandAttributes = @{ NSForegroundColorAttributeName: darkRed };
      commentAttributes = @{ NSForegroundColorAttributeName: lightGrey };
      modelAttributes = @{ NSForegroundColorAttributeName: darkYellow };
      printAttributes = @{ NSForegroundColorAttributeName: orange };
      subcircuitAttributes = @{ NSForegroundColorAttributeName: [NSColor blueColor] };
      defaultAttributes = @{ NSForegroundColorAttributeName: darkBlue };
      highlightingAttributesCreated = YES;
    }

    // Scan all lines
    tmp = [[inputView string] uppercaseString];
    [[inputView textStorage] beginEditing];
    while (lineStart < [tmp length])
    {
          [tmp getLineStart:&lineStart
                        end:&nextLineStart
                contentsEnd:&lineEnd
                   forRange:NSMakeRange(lineStart, 1)];
        line = [[tmp substringWithRange:NSMakeRange(lineStart, lineEnd - lineStart)]
            stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([line hasPrefix:@"*>"])
            line = [line substringFromIndex:2];
        
        if (lineStart == 0)
            [[inputView textStorage] setAttributes:commentAttributes
                                             range:NSMakeRange(lineStart, lineEnd - lineStart)];
        else if (([line hasPrefix:@".TRAN "] || [line isEqualToString:@".TRAN"]) ||
                 ([line hasPrefix:@".OP "] || [line isEqualToString:@".OP"]) ||
                 ([line hasPrefix:@".AC "] || [line isEqualToString:@".AC"]) ||
                 [line hasPrefix:@".NOISE "] ||
                 [line hasPrefix:@".DISTO "] ||
                 [line hasPrefix:@".FOUR "] ||
                 [line hasPrefix:@".DC "]  ||
                 [line hasPrefix:@".TF "] ||
                 [line hasPrefix:@".NODESET "] ||
                 [line hasPrefix:@".IC"] ||
                 [line hasPrefix:@".OPTIONS "])
        {
            [[inputView textStorage] setAttributes:analysisCommandAttributes
                                             range:NSMakeRange(lineStart, lineEnd - lineStart)];
            previousAttributes = analysisCommandAttributes;
        }
        else if ([line hasPrefix:@".MODEL"])
        {
            [[inputView textStorage] setAttributes:modelAttributes
                                             range:NSMakeRange(lineStart, lineEnd - lineStart)];
            previousAttributes = modelAttributes;
        }
        else if ([line hasPrefix:@".END"] || [line hasPrefix:@"*"])
        {
            [[inputView textStorage] setAttributes:commentAttributes
                                             range:NSMakeRange(lineStart, lineEnd - lineStart)];
        }
        else if ([line hasPrefix:@".PRINT"])
        {
            [[inputView textStorage] setAttributes:printAttributes
                                             range:NSMakeRange(lineStart, lineEnd - lineStart)];
            previousAttributes = printAttributes;
        }
        else if ([line hasPrefix:@".SUBCKT "])
        {
            [[inputView textStorage] setAttributes:subcircuitAttributes
                                             range:NSMakeRange(lineStart, lineEnd - lineStart)];
        }
        else if ([line hasPrefix:@"+"])
            [[inputView textStorage] setAttributes:previousAttributes
                                             range:NSMakeRange(lineStart, lineEnd - lineStart)];
        else
        {
            [[inputView textStorage] setAttributes:defaultAttributes
                                             range:NSMakeRange(lineStart, nextLineStart - lineStart)];
            previousAttributes = defaultAttributes;
        }
        lineStart = nextLineStart;
    }
    [[inputView textStorage] endEditing];
    [inputView setFont:
        [NSFont fontWithName:[[NSUserDefaults standardUserDefaults] objectForKey:MISUGAR_SOURCE_VIEW_FONT_NAME]
                        size:[[[NSUserDefaults standardUserDefaults] objectForKey:MISUGAR_SOURCE_VIEW_FONT_SIZE] floatValue]]];
}

/**************** SplitView delegate methods *****************/

- (float)    splitView:(NSSplitView *)sender
constrainMinCoordinate:(float)proposedMin
           ofSubviewAt:(int)offset
{
    if (!hasVerticalLayout)
    {
        if (sender == verticalSplitter)
            return 200.0f;
        else /* if (sender = horizontalSplitter) */
            return 100.0f;
    }
    else
        return 0.0f;
}

- (float)    splitView:(NSSplitView *)sender
constrainMaxCoordinate:(float)proposedMax
           ofSubviewAt:(int)offset
{
    if (!hasVerticalLayout)
    {
        if (sender == verticalSplitter)
            return [sender bounds].size.width - 200.0f;
        else /* if (sender == horizontalSplitter) */
            return [sender bounds].size.height - 100.0f;
    }
    else
        return [sender frame].size.height;
}

- (BOOL) splitView:(NSSplitView*)sv
canCollapseSubview:(NSView*)view
{
    if (!hasVerticalLayout)
        return YES;
    else
        return NO;
}


- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification
{
    if ([aNotification object] == verticalSplitter && !hasVerticalLayout)
    {
        NSScrollView* s = [inputView enclosingScrollView];
        float newScrollerWidth = [verticalSplitter frame].size.width -
            [verticalSplitter dividerThickness] -
            [[inputView lineNumberingView] frame].size.width;
        if (![verticalSplitter isSubviewCollapsed:canvas])
            newScrollerWidth -= [canvas frame].size.width;
        [s setFrameSize:NSMakeSize(newScrollerWidth,[s frame].size.height)];
        [s setNeedsDisplay:YES];
    }
}


/***********************************************************/
/* Toolbar methods                                         */
/***********************************************************/

/* toolbar delegate method */
- (NSArray*) toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    NSMutableArray* toolbarLayout = [NSMutableArray arrayWithCapacity:10];
    [toolbarLayout addObject:MISUGAR_Schematic2NetlistItem];
    if (![myModel isKindOfClass:[MI_SubcircuitDocumentModel class]])
    {
        [toolbarLayout addObject:MISUGAR_RunItem];
        [toolbarLayout addObject:MISUGAR_PlotItem];
    }
    [toolbarLayout addObject:NSToolbarSeparatorItemIdentifier];
    [toolbarLayout addObject:MISUGAR_ElementsPanelItem];
    [toolbarLayout addObject:MISUGAR_InfoPanelItem];
    [toolbarLayout addObject:NSToolbarSeparatorItemIdentifier];
    [toolbarLayout addObject:MISUGAR_SchematicVariantDisplayerItem];
    [toolbarLayout addObject:NSToolbarSeparatorItemIdentifier];
    [toolbarLayout addObject:MISUGAR_CanvasZoomOutItem];
    [toolbarLayout addObject:MISUGAR_CanvasScaleSliderItem];
    [toolbarLayout addObject:MISUGAR_CanvasZoomInItem];
    [toolbarLayout addObject:NSToolbarSeparatorItemIdentifier];
    [toolbarLayout addObject:MISUGAR_FitToViewItem];
//    [toolbarLayout addObject:MISUGAR_SchematicHomePositionItem];
    [toolbarLayout addObject:NSToolbarSeparatorItemIdentifier];
    if ([myModel isKindOfClass:[MI_SubcircuitDocumentModel class]])
    {
        [toolbarLayout addObject:NSToolbarFlexibleSpaceItemIdentifier];
        [toolbarLayout addObject:MISUGAR_SubcircuitIndicatorItem];
    }
    return toolbarLayout;
}

/* toolbar delegate method */
- (NSArray*) toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [self toolbarDefaultItemIdentifiers:toolbar];
}

/* toolbar delegate method */
- (NSToolbarItem *)toolbar:(NSToolbar*)toolbar
     itemForItemIdentifier:(NSString*)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
  if ([itemIdentifier isEqualToString:MISUGAR_Schematic2NetlistItem])
  {
    if (schematic2Netlist == nil)
    {
      schematic2Netlist = [[NSToolbarItem alloc] initWithItemIdentifier:MISUGAR_Schematic2NetlistItem];
      [schematic2Netlist setLabel:@"Capture"];
      [schematic2Netlist setAction:@selector(convertSchematicToNetlist:)];
      [schematic2Netlist setTarget:self];
      [schematic2Netlist setToolTip:@"Convert Schematic to Netlist"];
      [schematic2Netlist setImage:[NSImage imageNamed:@"schematic2netlist"]];
    }
    return schematic2Netlist;
  }
  else if ([itemIdentifier isEqualToString:MISUGAR_RunItem])
  {
    if (run == nil)
    {
      run = [[MI_CustomViewToolbarItem alloc] initWithItemIdentifier:MISUGAR_RunItem];
      analysisProgressIndicator = [[MI_AnalysisButton alloc] init];
      [analysisProgressIndicator setAction:@selector(runSimulator:)];
      [analysisProgressIndicator setTarget:self];
      [run setView:analysisProgressIndicator];
      [run setLabel:@"Analyze"];
      [run setToolTip:@"Analyze the Netlist"];
      [run setMinSize:NSMakeSize(34.0f, 32.0f)];
      [run setMaxSize:NSMakeSize(34.0f, 32.0f)];
    }
    return run;
  }
  else if ([itemIdentifier isEqualToString:MISUGAR_PlotItem])
  {
    if (plot == nil)
    {
      plot = [[NSToolbarItem alloc] initWithItemIdentifier:MISUGAR_PlotItem];
      [plot setLabel:@"Plot"];
      [plot setAction:@selector(plotResults:)];
      [plot setTarget:self];
      [plot setToolTip:@"Plot Analysis Results"];
      [plot setImage:[NSImage imageNamed:@"plotImage"]];
    }
    return plot;
  }
  else if ([itemIdentifier isEqualToString:MISUGAR_SchematicVariantDisplayerItem])
  {
    if (variantDisplayer == nil)
    {
      variantDisplayer = [[NSToolbarItem alloc] initWithItemIdentifier:MISUGAR_SchematicVariantDisplayerItem];
      [variantDisplayer setLabel:@"Variants"];
      [variantDisplayer setToolTip:@"Schematic variants. Click on schematic and press 1,2,3 or 4 to switch. Press Command + 1,2,3,4 to replace variant with current schematic."];
      [variantDisplayer setView:variantSelectionViewer];
      [variantDisplayer setTarget:self];
      [variantDisplayer setAction:@selector(switchToSchematicVariant:)];
      [variantDisplayer setMinSize:NSMakeSize(64.0f, 32.0f)];
      [variantDisplayer setMaxSize:NSMakeSize(64.0f, 32.0f)];
    }
    return variantDisplayer;
  }
  else if ([itemIdentifier isEqualToString:MISUGAR_CanvasScaleSliderItem])
  {
    if (canvasScaler == nil)
    {
      canvasScaler = [[MI_CustomViewToolbarItem alloc] initWithItemIdentifier:MISUGAR_CanvasScaleSliderItem];
      [canvasScaler setLabel:@"Scale"];
      [canvasScaler setToolTip:@"set the view scale"];
      canvasScaleSlider = [[NSSlider alloc] init];
      [canvasScaleSlider setMaxValue:MI_SCHEMATIC_CANVAS_MAX_SCALE];
      [canvasScaleSlider setMinValue:MI_SCHEMATIC_CANVAS_MIN_SCALE];
      [canvasScaleSlider setAltIncrementValue:0.1];
      [canvasScaleSlider setDoubleValue:1.0];
      //[canvasScaleSlider setNumberOfTickMarks:5];
      //[canvasScaleSlider setTickMarkPosition:NSTickMarkAbove];
      [canvasScaleSlider setAction:@selector(setCanvasScale:)];
      [canvasScaleSlider setTarget:self];
      [canvasScaler setView:canvasScaleSlider];
      [canvasScaler setMinSize:NSMakeSize(75.0f, 25.0f)];
      [canvasScaler setMaxSize:NSMakeSize(75.0f, 25.0f)];
    }
    return canvasScaler;
  }
  else if ([itemIdentifier isEqualToString:MISUGAR_CanvasZoomInItem])
  {
    if (zoomIn == nil)
    {
      zoomIn = [[NSToolbarItem alloc] initWithItemIdentifier:MISUGAR_CanvasZoomInItem];
      [zoomIn setLabel:@""];
      [zoomIn setAction:@selector(zoomInCanvas:)];
      [zoomIn setTarget:self];
      [zoomIn setToolTip:@"zoom in"];
      [zoomIn setImage:[NSImage imageNamed:@"zoom_in_toolbar_image"]];
    }
    return zoomIn;
  }
  else if ([itemIdentifier isEqualToString:MISUGAR_CanvasZoomOutItem])
  {
    if (zoomOut == nil)
    {
      zoomOut = [[NSToolbarItem alloc] initWithItemIdentifier:MISUGAR_CanvasZoomOutItem];
      [zoomOut setLabel:@""];
      [zoomOut setAction:@selector(zoomOutCanvas:)];
      [zoomOut setTarget:self];
      [zoomOut setToolTip:@"zoom out"];
      [zoomOut setImage:[NSImage imageNamed:@"zoom_out_toolbar_image"]];
    }
    return zoomOut;
  }
  else if ([itemIdentifier isEqualToString:MISUGAR_ElementsPanelItem])
  {
    if (elementsPanelShortcut == nil)
    {
      elementsPanelShortcut = [[NSToolbarItem alloc] initWithItemIdentifier:MISUGAR_ElementsPanelItem];
      [elementsPanelShortcut setLabel:@"Elements"];
      [elementsPanelShortcut setAction:@selector(showElementsPanel:)];
      [elementsPanelShortcut setTarget:[SugarManager sharedManager]];
      [elementsPanelShortcut setToolTip:@"Show Elements"];
      [elementsPanelShortcut setImage:[NSImage imageNamed:@"show_elements_button"]];
    }
    return elementsPanelShortcut;
  }
  else if ([itemIdentifier isEqualToString:MISUGAR_InfoPanelItem])
  {
    if (infoPanelShortcut == nil)
    {
      infoPanelShortcut = [[NSToolbarItem alloc] initWithItemIdentifier:MISUGAR_InfoPanelItem];
      [infoPanelShortcut setLabel:@"Info"];
      [infoPanelShortcut setAction:@selector(showInfoPanel:)];
      [infoPanelShortcut setTarget:[SugarManager sharedManager]];
      [infoPanelShortcut setToolTip:@"Show Info"];
      [infoPanelShortcut setImage:[NSImage imageNamed:@"show_info_panel_button"]];
    }
    return infoPanelShortcut;
  }
  else if ([itemIdentifier isEqualToString:MISUGAR_SchematicHomePositionItem])
  {
    if (home == nil)
    {
      home = [[NSToolbarItem alloc] initWithItemIdentifier:MISUGAR_SchematicHomePositionItem];
      [home setLabel:@""];
      [home setAction:@selector(moveSchematicViewportToOrigin:)];
      [home setTarget:self];
      [home setToolTip:@"Home Position"];
      [home setImage:[NSImage imageNamed:@"home_toolbar_item"]];
    }
    return home;
  }
  else if ([itemIdentifier isEqualToString:MISUGAR_FitToViewItem])
  {
    if (fitToView == nil)
    {
      fitToView = [[MI_CustomViewToolbarItem alloc] initWithItemIdentifier:MISUGAR_FitToViewItem];
      fitButton = [[MI_FitToViewButton alloc] init];
      [fitButton setAction:@selector(fitSchematicToView:)];
      [fitButton setTarget:self];
      [fitToView setView:fitButton];
      [fitToView setLabel:@"Fit to View"];
      [fitToView setToolTip:@"scale and position the schematic so it fills the viewable area"];
      [fitToView setMinSize:NSMakeSize(24.0f, 24.0f)];
      [fitToView setMaxSize:NSMakeSize(24.0f, 24.0f)];
    }
    return fitToView;
  }
  else if ([itemIdentifier isEqualToString:MISUGAR_SubcircuitIndicatorItem])
  {
    if (subcircuitIndicator == nil)
    {
      subcircuitIndicator = [[NSToolbarItem alloc] initWithItemIdentifier:MISUGAR_SubcircuitIndicatorItem];
      [subcircuitIndicator setLabel:(@"")];
      [subcircuitIndicator setTarget:[SugarManager sharedManager]];
      [subcircuitIndicator setAction:@selector(goToSubcircuitsFolder:)];
      if ([myModel isKindOfClass:[MI_SubcircuitDocumentModel class]])
      {
        [subcircuitIndicator setImage:[NSImage imageNamed:@"subcircuit_toolbar_item"]];
        [subcircuitIndicator setToolTip:@"This circuit is a subcircuit."];
      }
    }
    return subcircuitIndicator;
  }
  else
      return nil;
}


/* protocol implementation */
- (BOOL) validateToolbarItem:(NSToolbarItem *)theItem
{
    BOOL valid = NO;
    if ( theItem == schematic2Netlist ||
         theItem == infoPanelShortcut ||
         theItem == fitToView ||
         theItem == zoomIn ||
         theItem == zoomOut )
    {
        valid = [[myModel schematic] numberOfElements] > 0;
        [canvasScaleSlider setEnabled:valid];
        [fitToView setEnabled:valid];
    }
    else if (theItem == run)
    {
        valid = [[inputView string] length] > 0;
        [run setEnabled:valid];
    }
    else if (theItem == plot)
        valid = (![analysisProgressIndicator isAnimating] && ([[myModel output] length] > 0)
#ifndef PLOT_CUSTOM_SIMULATOR_RESULTS
                && ![[[NSUserDefaults standardUserDefaults] objectForKey:MISUGAR_USE_CUSTOM_SIMULATOR] boolValue]
#endif
            );
    else if ( theItem == subcircuitIndicator ||
         theItem == variantDisplayer )
        valid = YES;
    
    return valid;
}


/***********************************************************/
/* AppleScript support                                     */
/***********************************************************/

- (id) analyze_scriptCommand:(NSScriptCommand*)command
{
    [self runSimulator:nil];
    return nil;
}


- (id) plot_scriptCommand:(NSScriptCommand*)command
{
    [self plotResults:nil];
    return nil;
}

- (id) export_scriptCommand:(NSScriptCommand*)command
{
    NSDictionary* argsDict = [command evaluatedArguments];
    [self export:(NSString*)[argsDict objectForKey:@"format"]
          toFile:(NSString*)[argsDict objectForKey:@"file"]];
    return nil;
}

- (void) export:(NSString*)format
         toFile:(NSString*)fileName
{
    int i;
    NSString* output;
    NSArray* results = [SpiceASCIIOutputReader readFromModel:myModel];

    NSString* fileExtension = nil;
    if ([format isEqualToString:@"MathML"])
        fileExtension = @".mml";
    else if ([format isEqualToString:@"Matlab"])
        fileExtension = @".m";
    else if ([format isEqualToString:@"Tabular"])
        fileExtension = @".txt";

    for (i = 0; i < (int)[results count]; i++)
    {
        ResultsTable* currentTable = (ResultsTable*) [results objectAtIndex:i];
        
        if ([format isEqualToString:@"MathML"])
            output = [Converter resultsToMathML:currentTable];
        else if ([format isEqualToString:@"Matlab"])
            output = [Converter resultsToMatlab:currentTable];
        else if ([format isEqualToString:@"Tabular"])
            output = [Converter resultsToTabularText:currentTable];
        else
            return;
        
        if ([results count] > 1)
            fileName = [fileName stringByAppendingFormat:@"%d", i];
        fileName = [fileName stringByAppendingString:fileExtension];
        if (![output writeToFile:fileName atomically:YES encoding:NSASCIIStringEncoding error:NULL])
        {
          NSLog(@"Error while writing to file \"%@\".", fileName);
        }
    }
}


- (void) makeSubcircuit
{
    [[MI_SubcircuitCreator sharedCreator]
        createSubcircuitForCircuitDocument:self];
}


- (BOOL) validateMenuItem:(NSMenuItem*) item
{
    if ([[item title] isEqualToString:MISUGAR_CAPTURE_ITEM] ||
        [[item title] isEqualToString:MISUGAR_SVG_EXPORT_ITEM] ||
        [[item title] isEqualToString:MISUGAR_MAKE_SUBCIRCUIT_ITEM]) // <- one can create subcircuits from existing ones
        return [[myModel schematic] numberOfElements] > 0;
    else if ([[item title] isEqualToString:@"Save"])
        return [self isDocumentEdited];
    else if ( [[item title] isEqualToString:MISUGAR_MATHML_ITEM] ||
              [[item title] isEqualToString:MISUGAR_MATLAB_ITEM] ||
              [[item title] isEqualToString:MISUGAR_TABULAR_TEXT_ITEM])
        return ( [myModel output] != nil ) &&
            ![myModel isKindOfClass:[MI_SubcircuitDocumentModel class]];
    else if ( [[item title] isEqualToString:MISUGAR_PLOT_ITEM] )
        return ([myModel output] != nil) &&
            ![myModel isKindOfClass:[MI_SubcircuitDocumentModel class]];
    else if ([[item title] isEqualToString:MISUGAR_ANALYZE_ITEM])
        return ([[myModel source] length] > 0) &&
            ![myModel isKindOfClass:[MI_SubcircuitDocumentModel class]];
    else
        return [super validateMenuItem:item];
}

/************* Printing methods *****************/

- (void) printShowingPrintPanel:(BOOL)showPanels
{
    [[MI_CircuitDocumentPrinter sharedPrinter] runPrintSheetForCircuit:self];
}


/***** Window delegate methods *************************/

- (BOOL) windowShouldClose:(id)sender
{
    return YES;
}

- (void) windowWillClose:(NSNotification *)aNotification
{
    NSUserDefaults* userdefs = [NSUserDefaults standardUserDefaults];
    NSWindow* theWindow = [[[self windowControllers] objectAtIndex:0] window];
    float netHeight, netWidth, fraction;
    if (hasVerticalLayout)
    {
        netHeight = [splitter frame].size.height - 2 * [splitter dividerThickness];
        fraction = [canvas frame].size.height/netHeight;
        [userdefs setObject:[NSNumber numberWithFloat:fraction]
                    forKey:MISUGAR_DOCUMENT_FRACTIONAL_SIZE_OF_CANVAS];
    }
    else
    {
        netWidth = [verticalSplitter frame].size.width - [verticalSplitter dividerThickness];
        netHeight = [horizontalSplitter frame].size.height - [horizontalSplitter dividerThickness];
        fraction = [canvas frame].size.width/netWidth;
        [userdefs setObject:[NSNumber numberWithFloat:fraction]
                    forKey:MISUGAR_DOCUMENT_FRACTIONAL_SIZE_OF_CANVAS];
    }
    fraction = [[[inputView enclosingScrollView] superview] frame].size.height/netHeight;
    [userdefs setObject:[NSNumber numberWithFloat:fraction]
                 forKey:MISUGAR_DOCUMENT_FRACTIONAL_HEIGHT_OF_NETLIST_FIELD];
    fraction = [[shellOutputView enclosingScrollView] frame].size.height/netHeight;
    [userdefs setObject:[NSNumber numberWithFloat:fraction]
                 forKey:MISUGAR_DOCUMENT_FRACTIONAL_HEIGHT_OF_OUTPUT_FIELD];
    
    [theWindow saveFrameUsingName:MISUGAR_DOCUMENT_WINDOW_FRAME];
    /*if ([theWindow isMainWindow] || [theWindow isKeyWindow])*/
        [[MI_Inspector sharedInspector] inspectElement:nil];
}

/********************************************** SCHEMATIC VARIANT ********/

- (void) switchToSchematicVariant:(NSNumber*)variant
{
    [[self undoManager]
        registerUndoWithTarget:self
                      selector:@selector(switchToSchematicVariant:)
                        object:[NSNumber numberWithInt:[myModel activeSchematicVariant]]];
    [[self undoManager] setActionName:@"Switch to Schematic Variant"];

    // Stop listening to changes in the old schematic
    [[NSNotificationCenter defaultCenter]
        removeObserver:self
                  name:MI_SCHEMATIC_MODIFIED_NOTIFICATION
                object:[myModel schematic]];
    
    // Switch schematic
    [myModel setActiveSchematicVariant:[variant intValue]];

    // Start listening to changes in the new schematic
    [[NSNotificationCenter defaultCenter]
                    addObserver:self
                       selector:@selector(processSchematicChange:)
                           name:MI_SCHEMATIC_MODIFIED_NOTIFICATION
                         object:[myModel schematic]];
    // Mark as modified so the switch counts as modifications
    [[myModel schematic] markAsModified:YES];
    
    [variantSelectionViewer setSelectedVariant:[variant intValue]];
    [canvas setNeedsDisplay:YES];
}


- (void) copySchematicToVariant:(NSArray*)schematicAndVariant
{
    int currentVariant = [myModel activeSchematicVariant];
    
    MI_CircuitSchematic* newSchematic = [schematicAndVariant objectAtIndex:0];
    int variant = [[schematicAndVariant objectAtIndex:1] intValue];
    [myModel setActiveSchematicVariant:variant];

    MI_CircuitSchematic* oldSchematic = [myModel schematic];
    
    [[self undoManager]
        registerUndoWithTarget:self
                      selector:@selector(copySchematicToVariant:)
                        object:[NSArray arrayWithObjects:oldSchematic, [NSNumber numberWithInt:variant], nil]];

    [[self undoManager] setActionName:@"Set Schematic Variant"];

    [myModel setSchematic:[newSchematic copy]];

    // return to current variant
    [myModel setActiveSchematicVariant:currentVariant];
    
    // provide user feedback
    [variantSelectionViewer flashVariant:variant];
}

/********************************************** SAVING TO FILE ********/

- (void) setFileTypeAccordingToPolicy
{
    int policy = [[[NSUserDefaults standardUserDefaults] objectForKey:MISUGAR_FILE_SAVING_POLICY] intValue];
    if ( (policy == MI_AlwaysSaveAsPureNetlist) ||
         ((policy == MI_SaveAsPureNetlistIfNoSchematic) && ([[myModel schematic] numberOfElements] == 0)) )
        [self setFileType:NETLIST];
    else
        [self setFileType:SUGAR_FILE_TYPE];        
}


- (IBAction) saveDocument:(id)sender
{
    [self setFileTypeAccordingToPolicy];
    [super saveDocument:sender];
    // If this is a subcircuit refresh the library 
    if ([myModel isKindOfClass:[MI_SubcircuitDocumentModel class]])
        [[[SugarManager sharedManager] subcircuitLibraryManager] refreshAll];
}

- (IBAction) saveDocumentAs:(id)sender
{
    [self setFileTypeAccordingToPolicy];
    [super saveDocumentAs:sender];
    // If this is a subcircuit refresh the library 
    if ([myModel isKindOfClass:[MI_SubcircuitDocumentModel class]])
        [[[SugarManager sharedManager] subcircuitLibraryManager] refreshAll];
}

- (IBAction) saveDocumentTo:(id)sender
{
    [self setFileTypeAccordingToPolicy];
    [super saveDocumentTo:sender];
}



- (BOOL) prepareSavePanel:(NSSavePanel*)savePanel
{
    [savePanel setCanSelectHiddenExtension:YES];
    // Set the file extension according to the selected file saving policy
    if ( [[self fileType] isEqualToString:NETLIST] )
    {
        [savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"cir"]];
        [savePanel setRequiredFileType:@"cir"];
    }
    else
    {
        [savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"sugar"]];
        [savePanel setRequiredFileType:@"sugar"];
    }
    return YES;
}


- (NSTextView*) netlistEditor
{
    return inputView;
}

- (NSTextView*) analysisResultViewer
{
    return shellOutputView;
}

// **************************************************** SCHEMATIC - RELATED *****


- (MI_SchematicsCanvas*) canvas
{
    return canvas;
}


// Called by the scale adjustment widget
- (IBAction) setCanvasScale:(id)sender
{
    float s = [sender floatValue];
    [myModel setSchematicScale:s];
    [canvas setScale:s];
    scaleHasChanged = YES;
    [self markWindowContentAsModified:YES];
}


// Called by the canvas as a response to user interaction.
// The actual canvas scaling is performed by this method.
- (void) scaleShouldChange:(float)newScale
{
    [canvas setScale:newScale];
    // The canvas object may have restrained the scale value when we set it.
    // That's why we now ask the canvas for the scale value it uses.
    [canvasScaleSlider setFloatValue:[canvas scale]];
    [myModel setSchematicScale:newScale];
    scaleHasChanged = YES;
    [self markWindowContentAsModified:YES];
}


- (IBAction) zoomInCanvas:(id)sender
{
    [self scaleShouldChange:([canvas scale] * 1.2f)];
}


- (IBAction) zoomOutCanvas:(id)sender
{
    [self scaleShouldChange:([canvas scale] / 1.2f)];
}



- (IBAction) showPlacementGuides:(id)sender
{
    [canvas showGuides:([sender state] == NSOnState)];
}

- (void) placementGuideVisibilityChanged:(NSNotification*)notif
{
    [canvas showGuides:[[notif object] boolValue]];
}

- (void) canvasBackgroundChanged:(NSNotification*)notif
{
    [canvas setBackgroundColor:[notif object]];
}

- (IBAction) moveSchematicViewportToOrigin:(id)sender
{
    [canvas setViewportOffset:NSMakePoint(0, 0)];
    [canvas setNeedsDisplay:YES];
}


- (void) toggleDetailsView
{
    BOOL newState = ![[myModel schematic] showsQuickInfo];
    [[myModel schematic] setShowsQuickInfo:newState];
    [[myModel schematic] setShowsNodeNumbers:newState];
    [canvas setNeedsDisplay:YES];
}


- (IBAction) fitSchematicToView:(id)sender
{
    NSRect bbox = [[myModel schematic] boundingBox];
    NSRect viewRect = [canvas frame];
    NSPoint center = NSMakePoint(
        -bbox.origin.x + -bbox.size.width/2.0f + viewRect.size.width/2.0f,
        -bbox.origin.y + -bbox.size.height/2.0f + viewRect.size.height/2.0f
    );
    [canvas setViewportOffset:center];
    float newScale = 0.95f * fmin(viewRect.size.width / bbox.size.width,
                                  viewRect.size.height / bbox.size.height);

    [myModel setSchematicScale:newScale];
    scaleHasChanged = YES;
    [self markWindowContentAsModified:YES];
    [canvas setScale:newScale];
    [canvasScaleSlider setFloatValue:newScale];
}


- (void) markWindowContentAsModified:(BOOL)modified
{
    [[[[self windowControllers] objectAtIndex:0] window] setDocumentEdited:modified];
}


- (void) processSchematicChange:(NSNotification*)notification
{
    [self markWindowContentAsModified:[[myModel schematic] hasBeenModified]];
}


- (void) createSchematicUndoPointForModificationType:(NSString*)type
{
    if ([[[self undoManager] undoActionName] isEqualToString:MI_SCHEMATIC_MOVE_CHANGE]
        && [type isEqualToString:MI_SCHEMATIC_MOVE_CHANGE])
        return;
    [[self undoManager]
        registerUndoWithTarget:self
                      selector:@selector(restoreSchematic:)
                        object:[NSKeyedArchiver archivedDataWithRootObject:[myModel schematic]]];
    [[self undoManager] setActionName:type];
}


- (void) restoreSchematic:(NSData*)archivedSchematic
{
    if (![[self undoManager] canUndo])
        return;

    [[MI_Inspector sharedInspector] inspectElement:nil];
    
    // Set the undo of this undo - which is a redo
    [[self undoManager]
        registerUndoWithTarget:self
                      selector:@selector(restoreSchematic:)
                        object:[NSKeyedArchiver archivedDataWithRootObject:[myModel schematic]]];
    NS_DURING
        MI_CircuitSchematic* s = [NSKeyedUnarchiver unarchiveObjectWithData:archivedSchematic];
        [[NSNotificationCenter defaultCenter]
            removeObserver:self
                      name:MI_SCHEMATIC_MODIFIED_NOTIFICATION
                    object:[myModel schematic]];
        [myModel setSchematic:s];
        [[NSNotificationCenter defaultCenter]
                        addObserver:self
                           selector:@selector(processSchematicChange:)
                               name:MI_SCHEMATIC_MODIFIED_NOTIFICATION
                             object:s];
    NS_HANDLER
        NSLog(@"Undo to invalid state.");
    NS_ENDHANDLER
    
    //if ([s numberOfSelectedElements] == 1)
        //[[MI_Inspector sharedInspector] inspectElement:[s firstSelectedElement]];
    
    [canvas setNeedsDisplay:YES];
}


// NSWindow delegate method
- (NSUndoManager*) windowWillReturnUndoManager:(NSWindow *)sender
{
    return [self undoManager];
}

/*****************************************************************/


- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
