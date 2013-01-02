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

@protocol GameKitTurnBasedMatchHelperDelegate
- (void)enterNewGame:(GKTurnBasedMatch *)match;
- (void)layoutMatch:(GKTurnBasedMatch *)match;
- (void)takeTurn:(GKTurnBasedMatch *)match;
- (void)receiveEndGame:(GKTurnBasedMatch *)match;
- (void)sendNotice:(NSString *)notice
          forMatch:(GKTurnBasedMatch *)match;
@end


@interface GameKitTurnBasedMatchHelper : GameKitHelper <GKTurnBasedMatchmakerViewControllerDelegate, GKTurnBasedEventHandlerDelegate,GKFriendRequestComposeViewControllerDelegate>
{
}

@property (strong) GKTurnBasedMatch *currentMatch;
@property (nonatomic, assign) id <GameKitTurnBasedMatchHelperDelegate> tbDelegate;

+ (GameKitTurnBasedMatchHelper *)sharedInstance;
- (void)findMatchWithMinPlayers:(int)minPlayers
                     maxPlayers:(int)maxPlayers
            showExistingMatches:(BOOL)showExistingMatches;

@end
