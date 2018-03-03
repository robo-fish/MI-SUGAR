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
#import "ResultsTable.h"
#import "CircuitDocumentModel.h"
#import "MI_ElementConnector.h"


extern NSString* MATHML_PREAMBLE;
extern NSString* MATHML_ENDING;

/* Utility class for all kinds of conversion tasks */
@interface Converter : NSObject
{
}
// Converts the data of a ResultsTable object to a MathML expression.
+ (NSString*) resultsToMathML:(ResultsTable*)results;

// Converts the data of a ResultsTable object to a Matlab expression.
+ (NSString*) resultsToMatlab:(ResultsTable*)results;

// Converts the data of a ResultsTable object to a text with one column
// for each variable. Columns are separated by tab characters.
+ (NSString*) resultsToTabularText:(ResultsTable*)results;

/* If "mathml" is YES, this method converts the given SPICE analysis
   variable name to a Mathematica-compatible variable name, otherwise
   it's converted to Matlab-compatible name */
+ (NSString*) convertVariableName:(NSString*)spiceName
                         toMathML:(BOOL)mathml;

/* Internal convenience method */
+ (NSString*) convertFloatingPointToMathML:(double)number;

/*
 Converts a schematic of an electrical circuit to a netlist.
 Uses a different algorithm for subcircuit document models.
*/
+ (NSString*) schematicToNetlist:(CircuitDocumentModel*)circuit;

@end
