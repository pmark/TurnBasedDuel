//
//  GameKitHelper.m
//  MonkeyJump
//
//  Created by Fahim Farook on 18/8/12.
//
//

#import "GameKitHelper.h"
#import "GameConstants.h"
#import "AppDelegate.h"

@interface GameKitHelper ()
{
}

@end

@implementation GameKitHelper

- (BOOL)isGameCenterAvailable
{
    // check for presence of GKLocalPlayer API
    Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
    
    // check if the device is running iOS 4.1 or later
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer
                                           options:NSNumericSearch] != NSOrderedAscending);
    
    return (gcClass && osVersionSupported);
}

#pragma mark Singleton stuff

+ (id)sharedInstance
{
    static GameKitHelper *sharedGameKitHelper;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedGameKitHelper = [[GameKitHelper alloc] init];
    });
    
    return sharedGameKitHelper;
}

#pragma mark Player Authentication

- (void)authenticateLocalPlayer
{
	GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
	
    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error)
    {
        [self setLastError:error];
        
        if (localPlayer.authenticated)
        {
            self.gameCenterFeaturesEnabled = YES;
            [self localPlayerWasAuthenticated];
        }
        else if (viewController)
        {
            [self presentViewController:viewController];
        }
        else
        {
            self.gameCenterFeaturesEnabled = NO;
        }
    };
}

- (void)localPlayerWasAuthenticated
{
    // Implemented by subclasses.
}

#pragma mark -

// The user has cancelled matchmaking
- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController
{
    
}

// Matchmaking has failed with an error
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error
{
    
}

// A peer-to-peer match has been found, the game should start
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)match
{
    
}

// Players have been found for a server-hosted game, the game should start
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindPlayers:(NSArray *)playerIDs
{
    
}

// An invited player has accepted a hosted invite.  Apps should connect through the hosting server and then update the player's connected state (using setConnected:forHostedPlayer:)
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didReceiveAcceptFromHostedPlayer:(NSString *)playerID
{
    
}


#pragma mark -

- (void)loadPlayerPhoto:(GKPlayer*)player
{

    [player loadPhotoForSize:GKPhotoSizeSmall withCompletionHandler:^(UIImage *photo, NSError *error) {
        if (photo != nil)
        {
            NSLog(@"Loaded photo for %@", player.alias);
            [APP_DELEGATE.playerCache cachePhoto:photo forPlayer:player];
        }
        if (error != nil)
        {
            // Handle the error if necessary.
            NSLog(@"Error fetching player photo: %@", [error localizedDescription]);
        }
    }];
}

- (void)retrieveFriends
{
    GKLocalPlayer *lp = [GKLocalPlayer localPlayer];
    if (lp.authenticated)
    {
        [lp loadFriendsWithCompletionHandler:^(NSArray *friends, NSError *error) {
            if (friends != nil)
            {
                //[self loadPlayerData: friends];
            }
        }];
    }
}

- (void)getPlayerInfo:(NSArray*)playerList delegate:(NSObject<GameKitHelperProtocol>*)delegate
{
    if (!self.gameCenterFeaturesEnabled)
        return;
    
    if ([playerList count] > 0)
    {
        [GKPlayer loadPlayersForIdentifiers:playerList
                      withCompletionHandler:^(NSArray* players, NSError* error) {
                          
                          [self setLastError:error];
                          
                          if ([delegate respondsToSelector:@selector(onPlayerInfoReceived:)])
                          {
                              [delegate onPlayerInfoReceived:players];
                          }
                      }];
	}
}

- (void)getPlayerInfo:(NSArray*)playerList
{
    [self getPlayerInfo:playerList delegate:self.delegate];
}

- (void)inviteFriends:(NSArray*)identifiers
{
    GKFriendRequestComposeViewController *friendRequestViewController = [[GKFriendRequestComposeViewController alloc] init];
    
    friendRequestViewController.composeViewDelegate = self;
    
    if (identifiers)
    {
        [friendRequestViewController addRecipientsWithPlayerIDs: identifiers];
    }
    
    [self presentViewController:friendRequestViewController];
}

- (void)friendRequestComposeViewControllerDidFinish:(GKFriendRequestComposeViewController *)viewController
{
    [self dismissModalViewController];
}

#pragma mark Property setters
-(void)setLastError:(NSError*)error
{
    _lastError = [error copy];
    
	if (_lastError)
    {
		NSLog(@"GameKitHelper ERROR: %@", [[_lastError userInfo] description]);
        
        if ([[error domain] isEqualToString:GKErrorDomain])
        {
            if ([error code] == GKErrorNotSupported)
            {
                // Not supported
            }
            else
            {
                if ([error code] == GKErrorCancelled)
                {
                    // Login cancelled
                }
            }
        }
	}
}

#pragma mark UIViewController stuff

- (UIViewController*)getRootViewController
{
	return [UIApplication sharedApplication].keyWindow.rootViewController;
}

- (void)presentViewController:(UIViewController*)vc
{
	UIViewController *rootVC = [self getRootViewController];
	[rootVC presentViewController:vc animated:YES completion:nil];
}

- (void)dismissModalViewController
{
    UIViewController *rootVC = [self getRootViewController];
    [rootVC dismissViewControllerAnimated:YES completion:nil];
}

@end
