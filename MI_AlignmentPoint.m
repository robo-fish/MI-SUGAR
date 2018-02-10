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
#import "MI_AlignmentPoint.h"

@implementation MI_AlignmentPoint

- (id) initWithPosition:(NSPoint)pos
       alignsVertically:(BOOL)valign
     alignsHorizontally:(BOOL)halign
{
    if (self = [super init])
    {
        p = pos;
        verticalAlignment = valign;
        horizontalAlignment = halign;
    }
    return self;
}


- (void) setPosition:(NSPoint)pos { p = pos; }

- (NSPoint) position {return p;}

- (void) setAlignsVertically:(BOOL)alignsVertically
{ verticalAlignment = alignsVertically; }

- (BOOL) alignsVertically { return verticalAlignment; }

- (void) setAlignsHorizontally:(BOOL)alignsHorizontally
{ horizontalAlignment = alignsHorizontally; }

- (BOOL) alignsHorizontally {return horizontalAlignment; }

@end
