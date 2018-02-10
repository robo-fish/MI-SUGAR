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
#import "MI_ViewArea.h"

@implementation MI_ViewArea

- (id) initWithMinX:(double)minx
               maxX:(double)maxx
               minY:(double)miny
               maxY:(double)maxy
{
    if (self = [super init])
    {
        minX = minx;
        maxX = maxx;
        minY = miny;
        maxY = maxy;
    }
    return self;
}


- (double) minX { return minX; }
- (double) maxX { return maxX; }
- (double) minY { return minY; }
- (double) maxY { return maxY; }


- (void) setMinX:(double)minx
{
    minX = minx;
}


- (void) setMaxX:(double)maxx
{
    maxX = maxx;
}


- (void) setMinY:(double)miny
{
    minY = miny;
}


- (void) setMaxY:(double)maxy
{
    maxY = maxy;
}


- (void) dealloc
{
    [super dealloc];
}

@end
