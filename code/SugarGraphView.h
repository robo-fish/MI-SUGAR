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
#import "AnalysisVariable.h"
#import "MI_ViewArea.h"
//#define GRAPHVIEW_WITH_TOOLTIP

/*
 A graphical user interface element, which displays 2D graphs
 of multiple variables, together with abscissa and ordinate axes.
 This widget accepts variables for the abscissa and ordinate.
 The variables (of type AnalysisVariable) have to have the
 same number of sample points so that they can be drawn.
 Furthermore, the variables should all be set before the first
 drawing action.
 */
@interface SugarGraphView : NSView

/* Sets the abscissa values by supplying an array of double numbers
   and a descriptive name. */
- (void) setAbscissa:(AnalysisVariable*)values
                name:(NSString*)label;

/* Adds an ordinate variable by supplying an array of double numbers
   and a descriptive name for the variable. */
- (void) addOrdinate:(AnalysisVariable*)values
                name:(NSString*)label
               color:(NSColor*)color;

/* Returns the color assigned to the ordinate variable at the given index. */
- (NSColor*) colorOfOrdinateAtIndex:(NSInteger)index;

/* Sets the color of the ordinate variable given by its index number. */
- (void) setColor:(NSColor*)newColor
      forOrdinate:(int)ordinateIndex;

/* Returns the number of current ordinate variables */
- (NSUInteger) numberOfOrdinateVariables;

/* Converts the input abscissa value to the x-axis distance */
- (int) xValueToView:(double)xValue;

/* Converts the input ordinate value to the y-axis distance */
- (int) yValueToView:(double)yValue;

/* Converts a point in widget space to a point in value space where
    the width of the widget corresponds to difference between the
    maximum and minimum abscissa points and the height of the widget
    corresponds to the difference between the overall maximum value
    of all ordinate variables and the overall minimum value of all
    ordinate variables. */
- (NSPoint) viewToValue:(NSPoint)viewPoint;

- (void) setViewArea:(MI_ViewArea*)area;

- (MI_ViewArea*) viewArea;

- (void) drawGrid;		// draws the grid

- (void) drawLabels;	// draws the labels

- (void) drawHandles;	// draws the handles of the subregion selector lines

/* Calculates the parameters needed to draw the grid.
    The grid parameters (width, height, start, end) are set
    so that the grid lines are drawn at specific ratios of the
    integer neighborhood of the log10 space of the graph values */
- (void) calculateGridMetrics;

/* Turns grid on if gridOn is YES, and off otherwise. */
- (void) showGrid:(BOOL)gridOn;

/* Displays labels if labelsOn is YES. */
- (void) showLabels:(BOOL)labelsOn;

/* Marks the indexed ordinate variable to be drawn. */
- (void) showVariable:(int)index;

/* Marks the indexed ordinate variable to be skipped while drawing. */
- (void) hideVariable:(int)index;

/* Marks all ordinate variables to be drawn. */
- (void) showAll;

/* Marks all ordinate variables to be skipped while drawing. */
- (void) hideAll;

/* returns true if the variable at the given index is hidden, false otherwise */
- (BOOL) isHidden:(NSInteger)index;

/* Converts the abscissa values to logarithmic scale before drawing if 'logarithmic' is YES*/
- (void) showLogarithmicAbscissa:(BOOL)logarithmic;

/* Converts the ordinate values to logarithmic scale before drawing if 'logarithmic' is YES*/
- (void) showLogarithmicOrdinate:(BOOL)logarithmic;

- (void) setShowLogLabelsForLogScale:(BOOL)logLabels;

- (void) resizeGraph:(NSNotification*)notif;

/* Executed when user settings change notifications are received. */
- (void) changeSettings:(NSNotification*)notification;

/* For internal uses. Gets the user settings from the user defaults and sets the
    member variables. */
- (void) setPreferences;

/* Sets the color of the grid */
- (void) setGridColor:(NSColor*)color;

/* returns the margin by which the graph area is inset from the left */
- (int) leftMargin;

/* returns the margin by which the graph area is inset from the right */
- (int) rightMargin;

/* returns the margin by which the graph area is inset from the top */
- (int) topMargin;

/* returns the margin by which the graph area is inset from the bottom */
- (int) bottomMargin;

@property (nonatomic) NSColor* backgroundColor;

/* resets the view by removing all ordinate variables and the abscissa variable */
- (void) removeAll;

- (double) minimumOrdinateValue; // minimum Y value of the current view area
- (double) maximumOrdinateValue; // maximum Y value of the current view area
- (double) minimumAbscissaValue; // minimum X value
- (double) maximumAbscissaValue; // maximum X value


/* enables or disables the feature that shows the current (X,Y) values for
   the current position of the pointer inside of a tooltip popup whenever
   the pointer is inside the drawing area. */
#ifdef GRAPHVIEW_WITH_TOOLTIP
- (void) setShowsPointerPosition:(BOOL)showPos;
#endif

/* the registered coordinate observer gets mouse position updates */
- (void) setObserver:(id <SugarGraphObserver>)observer;

/* clipboard support */
- (IBAction) copy:(id)sender;
/* lazy pasting of the plot image */
- (void)pasteboard:(NSPasteboard *)sender
provideDataForType:(NSString *)type;

@property NSString* plotDescription; // no description is printed if this property is not set

- (double) leftHandlePosition; // returns the value of the abscissa at the position of the left handle
- (double) rightHandlePosition; // returns the value of the abscissa at the position of the right handle
- (double) topHandlePosition; // returns the value of the ordinate at the position of the top handle
- (double) bottomHandlePosition; // returns the value of the ordinate at the position of the bottom handle

@end
