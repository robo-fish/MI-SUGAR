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

// This class contains methods which are used to solve problems
// such as Cocoa bugs.
@interface MI_TroubleShooter : NSObject
{
}
// This solves a Cocoa string drawing problem
// which causes text to be clipped after an affine transform
// when drawing outside of the pre-transform clipping region.
+ (void) drawString:(NSString*)string
         attributes:(NSDictionary*)stringAttribs
            atPoint:(NSPoint)point
           rotation:(float)rot;

@end
