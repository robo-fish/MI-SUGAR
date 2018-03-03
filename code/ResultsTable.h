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
#import <Foundation/Foundation.h>
#import "AnalysisVariable.h"

@interface ResultsTable : NSObject
{
    enum AnalysisType {DC = 0, AC, TRAN, DISTO} type;
    NSMutableArray* variables;
}
/* Gets the analysis variable at the specified index */
- (AnalysisVariable*) variableAtIndex:(long)varIndex;

/* Sets the array that contains the descriptions of the variables */
- (void) addVariable:(AnalysisVariable*)var;

// the name of the results table which will be used to identify the plot based on this results table
@property NSString* name;

/* The title of the results table which is usually a description of the source circuit that produced the results. */
@property NSString* title;

/* Returns the number of variables. */
- (NSUInteger) numberOfVariables;

/* Returns the number of values for each variable. This should equal
    the number of values of the first analysis variable, and all variables
    should be of the same length. */
//- (int) numberOfPoints;

/* Returns YES if the abscissa values are not sorted in descending order.
- (BOOL) needsSorting;
*/
/* Sorts the table by the first variable,
   which gives the abscissa values for the graphs
- (void) sort;
*/
@end
