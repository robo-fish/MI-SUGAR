/***************************************************************************
*
*   Copyright 2004, 2005 Berk Ozer (berk@kulfx.com)
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
#import "CircuitDocumentModel.h"

@interface GnucapASCIIOutputReader : NSObject
{
}
/* Scans the analysis output of the circuit, given by its model, and returns
an array of ResultsTable objects, one for each analysis type that was carried
out by Gnucap. */
+ (NSArray*) readFromModel:(CircuitDocumentModel*)model;

@end
