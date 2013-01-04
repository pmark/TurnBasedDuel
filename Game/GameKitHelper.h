//
//  GameKitHelper.h
//  MonkeyJump
//
//  Created by Fahim Farook on 18/8/12.
//
//

//   Include the GameKit framework
#import <GameKit/GameKit.h>

//   Protocol to notify external
//   objects when Game Center events occur or
//   when Game Center async tasks are completed
@protocol GameKitHelperProtocol<NSObject>
@optional
-(void) onScoresSubmitted:(bool)success;
-(void) onScoresOfFriendsToChallengeListReceived:(NSArray*)scores;
-(void) onPlayerInfoReceived:(NSArray*)players;
@end


@interface GameKitHelper : NSObject <GKFriendRequestComposeViewControllerDelegate, GKMatchmakerViewControllerDelegate>

@property (nonatomic, assign) id<GameKitHelperProtocol> delegate;
@property (nonatomic, assign) BOOL gameCenterFeaturesEnabled;
@property (nonatomic, strong) NSError *lastError;

+ (id)sharedInstance;
- (void)authenticateLocalPlayer;
- (void)getPlayerInfo:(NSArray*)playerList;
- (void)getPlayerInfo:(NSArray*)playerList delegate:(NSObject<GameKitHelperProtocol>*)delegate;
- (void)presentViewController:(UIViewController*)vc;
- (void)dismissModalViewController;
- (void)localPlayerWasAuthenticated;
- (void)loadPlayerPhoto:(GKPlayer*)player;

@end
