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
#import <Cocoa/Cocoa.h>

/**
* This widget show two cog wheels, which can be animated (= rotate in opposite directions).
*/
@interface MI_AnalysisButton : NSView
{
    IBOutlet NSObject* target;
    SEL action; // called if the animation is not running
    BOOL userStartsClick; // set to true on mouseDown and checked on mouseUp
    unsigned animationCounter;
    float rotation;
    BOOL animationStopped;
    BOOL enabled;
}
- (void) setAction:(SEL)newAction;
- (void) setTarget:(NSObject*)newTarget;
- (NSObject*) target;
- (BOOL) isEnabled;
- (void) setEnabled:(BOOL)state;

// Called by the object which controls the circuit analysis
// Starts the animation
- (void) startAnimation;

// Stops the animation
- (void) stopAnimation;

- (BOOL) isAnimating;

@end
