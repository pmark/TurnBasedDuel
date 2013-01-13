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
#define NOTIF_MATCH_QUIT_BY_LOCAL_PLAYER @"NOTIF_MATCH_QUIT_BY_LOCAL_PLAYER"
#define NOTIF_MATCH_WON_BY_LOCAL_PLAYER @"NOTIF_MATCH_WON_BY_LOCAL_PLAYER"
#define NOTIF_MATCH_REMOVED @"NOTIF_MATCH_REMOVED"

@protocol GameKitTurnBasedMatchHelperDelegate
- (void)enterNewGame:(GKTurnBasedMatch *)match;
- (void)layoutMatch:(GKTurnBasedMatch *)match;
- (void)takeTurn:(GKTurnBasedMatch *)match;
- (void)receiveEndGame:(GKTurnBasedMatch *)match;
- (void)sendNotice:(NSString *)notice
          forMatch:(GKTurnBasedMatch *)match;
- (void)didFetchMatches:(NSArray*)matches;
@end


@interface GameKitTurnBasedMatchHelper : GameKitHelper <GKTurnBasedMatchmakerViewControllerDelegate, GKTurnBasedEventHandlerDelegate,GKFriendRequestComposeViewControllerDelegate, GKTurnBasedEventHandlerDelegate>
{
}

@property (strong) GKTurnBasedMatch *currentMatch;
@property (strong) NSMutableDictionary *matches;
@property (nonatomic, assign) id <GameKitTurnBasedMatchHelperDelegate> tbDelegate;

+ (GameKitTurnBasedMatchHelper *)sharedInstance;
+ (NSString*)matchStatusDisplayName:(GKTurnBasedMatchStatus)status;
+ (GKTurnBasedParticipant*)participantForLocalPlayerInMatch:(GKTurnBasedMatch*)match;

- (void)findMatchWithMinPlayers:(int)minPlayers
                     maxPlayers:(int)maxPlayers
            showExistingMatches:(BOOL)showExistingMatches;
- (void)cachePlayerData;
- (void)loadMatches;
- (void)quitMatch:(GKTurnBasedMatch*)match forParticipant:(GKTurnBasedParticipant*)participant;

@end
