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
//
// Prefix header for all source files of the 'MI-SUGAR' target in the 'MI-SUGAR' project
//
#ifndef MISUGAR_COMMON_H
#define MISUGAR_COMMON_H

#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#endif

// the following definition is needed to track file versions
#define MISUGAR_DOCUMENT_VERSION 5
/*
 History
 document version | application version | Note
 -------------------------------------------------
        1         |       0.5.2         | Introduction of keyed archiving
        2         |       0.5.3         | Introduction of subcircuits
        3         |       0.5.4         | Introduction of mosfet elements with bulk connectors in schematic
        4         |       0.5.5         | Introduction of text element & nonlinear dependent sources in schematic
        5         |       0.5.6         | Introduction of schematic variants
*/

// XML namespace
extern NSString* SUGARML_HEADER; // header for all SUGARML files 
extern NSString* MISUGAR_VERSION; // current application version
extern NSString* MISUGAR_RELEASE_DATE;
extern NSString* MISUGAR_CUSTOM_SIMULATOR_PATH;
extern NSString* MISUGAR_BuiltinSPICEPath;
extern NSString* MISUGAR_SOURCE_VIEW_FONT_NAME;
extern NSString* MISUGAR_SOURCE_VIEW_FONT_SIZE;
extern NSString* MISUGAR_RAW_OUTPUT_VIEW_FONT_NAME;
extern NSString* MISUGAR_RAW_OUTPUT_VIEW_FONT_SIZE;
extern NSString* MISUGAR_SHOW_UNTITLED_DOCUMENT_AT_STARTUP;
extern NSString* MISUGAR_FONT_CHANGE_NOTIFICATION;
extern NSString* MISUGAR_PLOT_GRAPHS_LINE_WIDTH;
extern NSString* MISUGAR_PLOT_GRID_LINE_WIDTH;
extern NSString* MISUGAR_PLOT_LABELS_FONT_SIZE;
extern NSString* MISUGAR_PLOTTER_BACKGROUND_COLOR;
extern NSString* MISUGAR_PLOTTER_GRID_COLOR;
extern NSString* MISUGAR_PLOTTER_LABEL_FONT_CHANGE_NOTIFICATION;
extern NSString* MISUGAR_PLOTTER_GRAPHS_LINE_WIDTH_CHANGE_NOTIFICATION;
extern NSString* MISUGAR_PLOTTER_GRID_LINE_WIDTH_CHANGE_NOTIFICATION;
extern NSString* MISUGAR_PLOTTER_GRID_COLOR_CHANGE_NOTIFICATION;
extern NSString* MISUGAR_PLOTTER_BACKGROUND_CHANGE_NOTIFICATION;
extern NSString* MISUGAR_PLOTTER_REMEMBERS_SETTINGS;
extern NSString* MISUGAR_PLOTTER_CLOSES_OLD_WINDOW;
extern NSString* MISUGAR_PLOTTER_AUTO_SHOW_GUIDES_TAB;
extern NSString* MISUGAR_PLOTTER_SHOWS_GRID;
extern NSString* MISUGAR_PLOTTER_SHOWS_LABELS;
extern NSString* MISUGAR_PLOTTER_HAS_LOGARITHMIC_ABSCISSA;
extern NSString* MISUGAR_PLOTTER_HAS_LOGARITHMIC_ORDINATE;
extern NSString* MISUGAR_PLOTTER_HAS_LOG_LABELS_FOR_LOG_SCALE;
extern NSString* MISUGAR_MATHML_ITEM;
extern NSString* MISUGAR_MATLAB_ITEM;
extern NSString* MISUGAR_TABULAR_TEXT_ITEM;
extern NSString* MISUGAR_SVG_EXPORT_ITEM;
extern NSString* MISUGAR_CAPTURE_ITEM;
extern NSString* MISUGAR_ANALYZE_ITEM;
extern NSString* MISUGAR_MAKE_SUBCIRCUIT_ITEM;
extern NSString* MISUGAR_PLOT_ITEM;
extern NSString* MISUGAR_USE_CUSTOM_SIMULATOR;
extern NSString* MISUGAR_DOCUMENT_WINDOW_FRAME;
extern NSString* MISUGAR_PLOTTER_WINDOW_FRAME;
extern NSString* MISUGAR_ELEMENTS_PANEL_FRAME;
extern NSString* MISUGAR_INFO_PANEL_FRAME;
extern NSString* MISUGAR_DEVICE_MODELS_PANEL_FRAME;
extern NSString* MISUGAR_DOCUMENT_LAYOUT;
extern NSString* MISUGAR_DOCUMENT_FRACTIONAL_SIZE_OF_CANVAS;
extern NSString* MISUGAR_DOCUMENT_FRACTIONAL_HEIGHT_OF_NETLIST_FIELD;
extern NSString* MISUGAR_DOCUMENT_FRACTIONAL_HEIGHT_OF_OUTPUT_FIELD;
extern NSString* MISUGAR_LINE_ENDING_CONVERSION_POLICY;
extern NSString* MISUGAR_FILE_SAVING_POLICY;
// SCHEMATIC-RELATED
extern NSString* MISUGAR_ELEMENTS_PANEL_ALPHA;
extern NSString* MISUGAR_INFO_PANEL_ALPHA;
extern NSString* MISUGAR_SHOW_PLACEMENT_GUIDES;
extern NSString* MISUGAR_AUTOINSERT_NODE_ELEMENT;
extern NSString* MISUGAR_CIRCUIT_DEVICE_MODELS;
extern NSString* MISUGAR_PLACEMENT_GUIDE_VISIBILITY_CHANGE_NOTIFICATION;
extern NSString* MISUGAR_SCHEMATIC_CANVAS_BACKGROUND_COLOR;
extern NSString* MISUGAR_CANVAS_BACKGROUND_CHANGE_NOTIFICATION;

enum handleID { LEFT, RIGHT, TOP, BOTTOM };

// system pasteboard types specific to MI-SUGAR
extern NSString* MI_SchematicElementPboardType; // single element
extern NSString* MI_SchematicElementsPboardType; // collection of elements

// The directions are ordered counterclockwise so that the next direction
// is the current direction plus PI/4 radian.
typedef NS_ENUM(NSInteger,MI_Direction)
{
  MI_DirectionNone = -1,
  MI_DirectionUp,
  MI_DirectionNorthwest,
  MI_DirectionLeft,
  MI_DirectionSouthwest,
  MI_DirectionDown,
  MI_DirectionSoutheast,
  MI_DirectionRight,
  MI_DirectionNortheast
};


typedef NS_ENUM(NSInteger,MI_FileSavingPolicy)
{
  MI_FileSavingPolicyAlwaysPureNetlist,
  MI_FileSavingPolicyAlwaysSugar,
  MI_FileSavingPolicyNetlistWhenNoSchematic
};

// The protocol which must be adopted by classes whose objects
// can be archived in and unarchived from SugarML formatted files.
@protocol MI_SugarML
// Returns a SugarML representation of the receiver.
// The indentation and indentation increment are meant for creating
// tidy content. They can be nil.
- (NSString*) toSugarMLWithIndentation:(NSString*)indent
                  indentationIncrement:(NSString*)increment;
@end

/* This protocol must be implemented by all schematic elements who want to
show an alternative label (e.g., device value) instead of the label. */
@protocol MI_QuickInfoElement
- (NSString*) quickInfo;
@end

// Protocol that must implemented to get events from the graph view.
@protocol SugarGraphObserver
// The point is the position of the mouse in the view.
- (void) processMouseMove:(NSPoint)newCoordinate;
// Called when one of the subregion delimiter handles is dragged.
- (void) processHandleDrag:(enum handleID)selection // the ID of the dragged handle
                  position:(double)handlePosition; // the new handle position
// Called when any of the handles is grabbed.
- (void) processHandleGrabbed;
// Called when all handles are released.
- (void) processHandlesReleased;
// the observer should update its representation of the handle positions after receiving this message
- (void) handlePositionsShouldUpdate;
@end

// Protocol that must be implemented to be notified of drop operations.
// Adoption of this protocol is necessary for file drops on the netlist editor or on the canvas.
@protocol MI_DropHandler
// This method is called by the object on which the drop occured.
- (void) processDrop:(id <NSDraggingInfo>)sender;
@end

// This protocol must be implemented by objects that can be inspected.
@protocol MI_Inspectable
@end

#endif // MISUGAR_COMMON_H
