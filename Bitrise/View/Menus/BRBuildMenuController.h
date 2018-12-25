//
//  BRBuildMenuController.h
//  Bitrise
//
//  Created by Deszip on 25/12/2018.
//  Copyright © 2018 Bitrise. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface BRBuildMenuController : NSObject

- (void)bind:(NSMenu *)menu toOutline:(NSOutlineView *)outline;

@end

NS_ASSUME_NONNULL_END
