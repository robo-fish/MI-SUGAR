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

// Parser for MI-SUGAR's Schematic Element Shape Definition Language (SESDL).
// SESDL is described in the XML Schema file http://www.macinit.com/schemas/sesdl.xsd

#import "MI_PathShape.h"


@interface MI_SESDLParser : NSObject
{

}
// Constructs a MI_PathShape object from the given SESDL file.
// Returns nil if an error occurs during parsing.
+ (MI_PathShape*) parseSESDL:(NSString*)sesdlFile;

@end
