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

#import "MI_TroubleShooter.h"


@implementation MI_TroubleShooter

+ (void) drawString:(NSString*)string
         attributes:(NSDictionary*)stringAttribs
            atPoint:(NSPoint)point
           rotation:(float)rot
{
    // Solution posted by Erez Anzel to Apple's Cocoa development mailing list
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithString:string
                                                            attributes:stringAttribs];
    NSLayoutManager *layoutManager = [NSLayoutManager new];
    NSTextContainer *textContainer = [NSTextContainer new];
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    
    // Note that usedRectForTextContainer: does not force layout, so it must
    // be called after glyphRangeForTextContainer:, which does force layout.
    NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];

    NSPoint loc = [layoutManager locationForGlyphAtIndex:0];
    loc.y += [[stringAttribs objectForKey:NSFontAttributeName] descender]; // descender is a negative number

    [layoutManager drawGlyphsForGlyphRange:glyphRange 
                                   atPoint:NSMakePoint(point.x - loc.x,
                                                       point.y + 1.0f - loc.y)];

    /*
    NSRect usedRect = [layoutManager usedRectForTextContainer:textContainer];
    unsigned glyphIndex;
	NSGraphicsContext *context = nil;
	NSRect lineFragmentRect;
	NSPoint viewLocation;
	NSPoint layoutLocation;
	NSAffineTransform *transform = nil;
	
	for (glyphIndex = glyphRange.location; glyphIndex < NSMaxRange(glyphRange); glyphIndex++)
    {
		context = [NSGraphicsContext currentContext];
		lineFragmentRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex
                                                           effectiveRange:NULL];
		layoutLocation = [layoutManager locationForGlyphAtIndex:glyphIndex];
		transform = [NSAffineTransform transform];
		
		// Here layoutLocation is the location (in container coordinates) where the glyph was laid out.
        layoutLocation.x += lineFragmentRect.origin.x;
		layoutLocation.y += lineFragmentRect.origin.y;
		
		viewLocation.x = point.x;
		viewLocation.y = point.y + layoutLocation.x;
		
		// We use a different affine transform for each glyph, to position and
        //  rotate it based on its calculated position around the circle.
        [transform translateXBy:viewLocation.x
                            yBy:viewLocation.y];
		[transform rotateByDegrees:rot];
		
		// We save and restore the graphics state so that the transform applies only to this glyph.
        [context saveGraphicsState];
		[transform concat];
		// drawGlyphsForGlyphRange: draws the glyph at its laid-out location in container coordinates.
        // Since we are using the transform to place the glyph, we subtract the laid-out location here.
        [layoutManager drawGlyphsForGlyphRange:NSMakeRange(glyphIndex, 1) 
                                       atPoint:NSMakePoint(-layoutLocation.x, -layoutLocation.y)];
		[context restoreGraphicsState];
	} // for (glyphIndex...)
    */
}

@end
