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

@interface MI_ViewArea : NSObject
{
    double minX, maxX, minY, maxY;
}
- (instancetype) initWithMinX:(double)minx
               maxX:(double)maxx
               minY:(double)miny
               maxY:(double)maxy;

- (double) minX;
- (double) maxX;
- (double) minY;
- (double) maxY;
- (void) setMinX:(double)minx;
- (void) setMaxX:(double)maxx;
- (void) setMinY:(double)miny;
- (void) setMaxY:(double)maxy;
@end
