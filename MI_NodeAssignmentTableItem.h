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

/* Support class for schematic to netlist conversion */
@interface MI_NodeAssignmentTableItem : NSObject <NSCoding>

- (instancetype) initWithElement:(NSString*)identifier connectionPoint:(NSString*)pointName;
@property int node; // The index of the node. A negative number means the connection point is unassigned.
@property NSString* nodeName; // The name of the assigned node, if it has one.
@property (readonly, nonatomic) NSString* elementID;
@property (readonly, nonatomic) NSString* pointName;

@end
