//
//  BRGetBuildsCommand.m
//  Bitrise
//
//  Created by Deszip on 07/07/2018.
//  Copyright © 2018 Bitrise. All rights reserved.
//

#import "BRSyncCommand.h"

@interface BRSyncCommand ()

@property (strong, nonatomic, readonly) BRSyncEngine *syncEngine;

@end

@implementation BRSyncCommand

- (instancetype)initSyncEngine:(BRSyncEngine *)engine {
    if (self = [super init]) {
        _syncEngine = engine;
    }
    
    return self;
}

- (void)execute:(BRCommandResult)callback {
    [self.syncEngine sync];
    
//    [self.storage getAccounts:^(NSArray<BRAccountInfo *> *accounts, NSError *error) {
//        [accounts enumerateObjectsUsingBlock:^(BRAccountInfo *nextAccount, NSUInteger idx, BOOL *stop) {
//            [self.api getApps:nextAccount completion:^(NSArray<BRAppInfo *> *apps, NSError *error) {
//                [self.storage saveApps:apps forAccount:nextAccount];
//                [apps enumerateObjectsUsingBlock:^(BRAppInfo *nextApp, NSUInteger idx, BOOL *stop) {
//                    [self.api getBuilds:nextApp account:nextAccount completion:^(NSArray<BRBuildInfo *> *builds, NSError *error) {
//                        [self.storage saveBuilds:builds forApp:nextApp completion:nil];
//                    }];
//                }];
//            }];
//        }];
//
//        if (callback) callback(YES, nil);
//    }];
}

@end