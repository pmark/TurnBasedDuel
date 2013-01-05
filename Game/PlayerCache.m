//
//  PlayerCache.m
//  Game
//
//  Created by P. Mark Anderson on 1/3/13.
//  Copyright (c) 2013 Bordertown Labs. All rights reserved.
//

#import "PlayerCache.h"
#import "GameKitHelper.h"
#import "GameKitTurnBasedMatchHelper.h"

@implementation PlayerCache

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.players = [NSMutableDictionary dictionary];
        self.playerPhotos = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)onPlayerInfoReceived:(NSArray*)players
{
    // Update the cache.
    
    for (GKPlayer *onePlayer in players)
    {
        NSLog(@"Fetched player: %@", onePlayer.alias);
        
        [self.players setValue:onePlayer forKey:onePlayer.playerID];

        [[GameKitTurnBasedMatchHelper sharedInstance] loadPlayerPhoto:onePlayer];
    }
    
    // Send a notification.
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              players, @"players",
                              nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_PLAYER_CACHE_DID_FETCH_PLAYERS
                                                        object:nil
                                                      userInfo:userInfo];

}

- (GKPlayer*)playerWithID:(NSString*)playerID
{
    return (GKPlayer*)[self.players objectForKey:playerID];
}

- (void)cachePhoto:(UIImage*)photo forPlayer:(GKPlayer*)player
{
    [self.playerPhotos setValue:photo forKey:player.playerID];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              player, @"player",
                              photo, @"photo",
                              nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_PLAYER_CACHE_DID_FETCH_PLAYER_PHOTO
                                                        object:nil
                                                      userInfo:userInfo];
}

- (UIImage*)photoForPlayer:(GKPlayer*)player
{
    UIImage *img = [self.playerPhotos objectForKey:player.playerID];
    
    if (!img)
    {
        img = [UIImage imageNamed:@"anonymous-75.png"];
    }
    
    return img;
}

- (GKPlayer*)player:(NSInteger)playerIndex amongParticipants:(NSArray*)participants
{
    NSString *playerID = ((GKTurnBasedParticipant*)[participants objectAtIndex:playerIndex]).playerID;
    return [self playerWithID:playerID];
}

@end
