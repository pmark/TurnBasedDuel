//
//  GameKitTurnBasedMatchHelper.h
//  game
//
//  Created by P. Mark Anderson on 1/1/13.
//
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "GameKitHelper.h"

#define NOTIF_TURN_EVENT @"NOTIF_TURN_EVENT"
#define NOTIF_NEW_GAME @"NOTIF_NEW_GAME"

@protocol GameKitTurnBasedMatchHelperDelegate
- (void)enterNewGame:(GKTurnBasedMatch *)match;
- (void)layoutMatch:(GKTurnBasedMatch *)match;
- (void)takeTurn:(GKTurnBasedMatch *)match;
- (void)receiveEndGame:(GKTurnBasedMatch *)match;
- (void)sendNotice:(NSString *)notice
          forMatch:(GKTurnBasedMatch *)match;
- (void)didFetchMatches:(NSArray*)matches;
@end


@interface GameKitTurnBasedMatchHelper : GameKitHelper <GKTurnBasedMatchmakerViewControllerDelegate, GKTurnBasedEventHandlerDelegate,GKFriendRequestComposeViewControllerDelegate>
{
}

@property (strong) GKTurnBasedMatch *currentMatch;
@property (strong) NSMutableDictionary *matches;
@property (nonatomic, assign) id <GameKitTurnBasedMatchHelperDelegate> tbDelegate;

+ (GameKitTurnBasedMatchHelper *)sharedInstance;
+ (NSString*)matchStatusDisplayName:(GKTurnBasedMatchStatus)status;
- (void)findMatchWithMinPlayers:(int)minPlayers
                     maxPlayers:(int)maxPlayers
            showExistingMatches:(BOOL)showExistingMatches;
- (void)cachePlayerData;

@end
