//
//  PlayerCache.h
//  Game
//
//  Created by P. Mark Anderson on 1/3/13.
//  Copyright (c) 2013 Bordertown Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameKitHelper.h"

#define NOTIF_PLAYER_CACHE_DID_FETCH_PLAYERS @"NOTIF_PLAYER_CACHE_DID_FETCH_PLAYERS"
#define NOTIF_PLAYER_CACHE_DID_FETCH_PLAYER_PHOTO @"NOTIF_PLAYER_CACHE_DID_FETCH_PLAYER_PHOTO"

//@protocol PlayerCacheDelegate <NSObject>
//
//- (void)playerInfoWasFetched:(NSArray*)players;
//
//@end

@interface PlayerCache : NSObject <GameKitHelperProtocol>

@property (nonatomic, strong) NSMutableDictionary *players;
@property (nonatomic, strong) NSMutableDictionary *playerPhotos;

- (GKPlayer*)playerWithID:(NSString*)playerID;
- (void)cachePhoto:(UIImage*)photo forPlayer:(GKPlayer*)player;
- (UIImage*)photoForPlayer:(GKPlayer*)player;
- (GKPlayer*)player:(NSInteger)playerIndex amongParticipants:(NSArray*)participants;

@end
