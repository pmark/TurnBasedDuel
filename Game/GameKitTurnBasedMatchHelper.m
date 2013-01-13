//
//  GameKitTurnBasedMatchHelper.m
//  game
//
//  Created by P. Mark Anderson on 1/1/13.
//
//

#import "GameKitTurnBasedMatchHelper.h"
#import "AppDelegate.h"

@interface GameKitTurnBasedMatchHelper ()
{
    BOOL isInvited;
}

@property (nonatomic, assign) BOOL userAuthenticated;
@end


@implementation GameKitTurnBasedMatchHelper

static GameKitTurnBasedMatchHelper *sharedHelper = nil;

+ (GameKitTurnBasedMatchHelper *) sharedInstance
{
    if (!sharedHelper)
    {
        sharedHelper = [[GameKitTurnBasedMatchHelper alloc] init];
    }
    
    return sharedHelper;
}

- (void)authenticationChanged
{
    if ([GKLocalPlayer localPlayer].isAuthenticated && !self.userAuthenticated)
    {
        NSLog(@"Authentication changed: player authenticated.");
        self.userAuthenticated = TRUE;
    }
    else if (![GKLocalPlayer localPlayer].isAuthenticated && self.userAuthenticated)
    {
        NSLog(@"Authentication changed: player not authenticated");
        self.userAuthenticated = FALSE;
    }
}

- (void)localPlayerWasAuthenticated
{
    [super localPlayerWasAuthenticated];
    [GKTurnBasedEventHandler sharedTurnBasedEventHandler].delegate = self;
    [self loadMatches];
}

- (void)findMatchWithMinPlayers:(int)minPlayers
                     maxPlayers:(int)maxPlayers
            showExistingMatches:(BOOL)showExistingMatches
{

    if (!self.gameCenterFeaturesEnabled)
        return;
    
//    self.presentingViewController = viewController;
    
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = minPlayers;
    request.maxPlayers = maxPlayers;
    
    GKTurnBasedMatchmakerViewController *mmvc = [[GKTurnBasedMatchmakerViewController alloc] initWithMatchRequest:request];

    mmvc.turnBasedMatchmakerDelegate = self;
    mmvc.showExistingMatches = showExistingMatches;
    
    [self presentViewController:mmvc];
}

#pragma mark GKTurnBasedMatchmakerViewControllerDelegate

-(void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController
                            didFindMatch:(GKTurnBasedMatch *)match
{
    NSLog(@"[GKTBMH] didFindMatch, %@", match);

    // Update the match list.
    
    [self.matches setValue:match forKey:match.matchID];
    
    [self dismissModalViewController];
    
    GKTurnBasedParticipant *firstParticipant = [match.participants objectAtIndex:0];
    
    if (firstParticipant.lastTurnDate == NULL)
    {
        // It's a new game!

        NSLog(@"didFindMatch: New game");
        [self.tbDelegate enterNewGame:match];
    }
    else
    {
        if ([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID])
        {
            // It's your turn!

            NSLog(@"didFindMatch: It's your turn.");
            [self.tbDelegate takeTurn:match];
        }
        else
        {
            // It's not your turn, just display the game state.
            
            NSLog(@"didFindMatch: Not your turn.");
            [self.tbDelegate layoutMatch:match];
        }
    }
}

-(void)turnBasedMatchmakerViewControllerWasCancelled:(GKTurnBasedMatchmakerViewController *)viewController
{
    [self dismissModalViewController];
    NSLog(@"[GKTBMH] matchmaker cancelled");
}

-(void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController
                        didFailWithError:(NSError *)error
{
    NSLog(@"[GKTBMH] matchmaker failed: %@", error.localizedDescription);
}


// Called when a users chooses to quit a match and that player has the current turn.  The developer should call
//  playerQuitInTurnWithOutcome:nextPlayer:matchData:completionHandler: on the match passing in appropriate values.
//  They can also update matchOutcome for other players as appropriate.
//
-(void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController
                      playerQuitForMatch:(GKTurnBasedMatch *)match
{
    NSLog(@"playerQuitForMatch, %@, %@",
          match.matchID,
          [APP_DELEGATE.playerCache playerWithID:match.currentParticipant.playerID].alias);
    
    // TODO: Move the guts of the quit code somewhere else.

    [self quitMatch:match forParticipant:[GameKitTurnBasedMatchHelper participantForLocalPlayerInMatch:match]];

    [self.matches setValue:match forKey:match.matchID];
}


#pragma mark GKTurnBasedEventHandlerDelegate

-(void)handleInviteFromGameCenter:(NSArray *)playersToInvite
{
    NSLog(@"[GKTBMH] handleInviteFromGameCenter: %@", playersToInvite);
    [self dismissModalViewController];

    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.playersToInvite = playersToInvite;
    request.maxPlayers = 12;
    request.minPlayers = 2;

    GKTurnBasedMatchmakerViewController *viewController = [[GKTurnBasedMatchmakerViewController alloc]initWithMatchRequest:request];
    viewController.showExistingMatches = NO;
    viewController.turnBasedMatchmakerDelegate = self;

    [self presentViewController:viewController];
}

-(void)handleTurnEventForMatch:(GKTurnBasedMatch *)match
{
    NSLog(@"[GKTBMH] handleTurnEventForMatch (%@) %@",
          [GameKitTurnBasedMatchHelper matchStatusDisplayName:match.status],
          match.matchID);
    
    
    // TODO: End game if all other competitors' status != None.
    
    GKTurnBasedParticipant *localParticipant = [GameKitTurnBasedMatchHelper participantForLocalPlayerInMatch:match];
    NSString *localPlayerID = [GKLocalPlayer localPlayer].playerID;
    BOOL isMyTurn = ([match.currentParticipant.playerID isEqualToString:localPlayerID]);
    BOOL gameOver = YES;

    // This happens after the other player quits too.
    
    for (GKTurnBasedParticipant *participant in match.participants)
    {
        NSLog(@"[GKTBMH] handleTurnEventForMatch %@ status: %i",
              [APP_DELEGATE.playerCache playerWithID:participant.playerID].alias,
              participant.matchOutcome);

        if (![participant.playerID isEqualToString:localPlayerID] &&
            participant.matchOutcome == GKTurnBasedMatchOutcomeNone)
        {
            gameOver = NO;
            break;
        }
    }
    
    if (gameOver)
    {
        // I win.
        localParticipant.matchOutcome = GKTurnBasedMatchOutcomeWon;
        
        if (isMyTurn)
        {
            // End as victor.
            
            [match endMatchInTurnWithMatchData:match.matchData
                             completionHandler:^(NSError *error) {
                                 
                                 if (error)
                                 {
                                     NSLog(@"[GKTBMH] handleTurnEventForMatch won during my turn error: %@", error.localizedDescription);
                                 }
                                 else
                                 {
                                     NSLog(@"[GKTBMH] handleTurnEventForMatch won during my turn completed.");
                                     
                                     // Send notification.
                                     
                                     NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                               match, @"match",
                                                               nil];
                                     
                                     [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_MATCH_WON_BY_LOCAL_PLAYER
                                                                                         object:nil
                                                                                       userInfo:userInfo];
                                     
                                 }
                             }];

        }
        else
        {
            [match participantQuitOutOfTurnWithOutcome:GKTurnBasedMatchOutcomeWon
                                 withCompletionHandler:^(NSError *error) {
                                     if (error)
                                     {
                                         NSLog(@"[GKTBMH] handleTurnEventForMatch won out of turn error: %@", error.localizedDescription);
                                     }
                                     else
                                     {
                                         NSLog(@"[GKTBMH] handleTurnEventForMatch won out of turn completed.");
                                     }
                                 }];            
        }

    }

    
    // Update old match in match list.
    
    [self.matches setValue:match forKey:match.matchID];
        
    
    
    if (self.currentMatch)
    {
        if ([match.matchID isEqualToString:self.currentMatch.matchID])
        {
            // Point at this match.
            self.currentMatch = match;
            
            // You're looking at the match that just received a turn.

            if (isMyTurn)
            {
                // It's your turn.
                
                [self.tbDelegate takeTurn:match];
            }
            else
            {
                // Not your turn.
                
                [self.tbDelegate layoutMatch:match];
            }
        }
    }

    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              match, @"match",
                              nil];
    

    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_TURN_EVENT
                                                        object:nil
                                                      userInfo:userInfo];
}

-(void)handleMatchEnded:(GKTurnBasedMatch *)match
{
    NSLog(@"[GKTBMH] handleMatchEnded %@", match.matchID);
    
    if ([match.matchID isEqualToString:self.currentMatch.matchID])
    {
        [self.tbDelegate receiveEndGame:match];
    }
    else
    {
        [self.tbDelegate sendNotice:@"Another Game Ended!" forMatch:match];
    }
}

BOOL _loadingMatches;
- (void)loadMatches
{
    if (_loadingMatches)
        return;
    
    _loadingMatches = YES;
    
    [GKTurnBasedMatch loadMatchesWithCompletionHandler:^(NSArray *matches, NSError *error) {
        
        if (error)
        {
            NSLog(@"Error fetching matches: %@", error.localizedDescription);
        }

        self.matches = [NSMutableDictionary dictionaryWithCapacity:[matches count]];

        for (GKTurnBasedMatch *oneMatch in matches)
        {
            [self.matches setValue:oneMatch forKey:oneMatch.matchID];
        }
        
        if (self.tbDelegate)
        {
            [self.tbDelegate didFetchMatches:matches];
        }
        
        _loadingMatches = NO;
    }];
}

- (void)cachePlayerData
{
    NSMutableArray *ids = [NSMutableArray array];
    
    for (GKTurnBasedMatch *match in [self.matches allValues])
    {
        NSLog(@"Caching players in match: %@", match.matchID);
        
        for (GKTurnBasedParticipant *participant in match.participants)
        {
            if (!participant.playerID)
            {
                continue;
            }
            
            BOOL cached = ([APP_DELEGATE.playerCache.players objectForKey:participant.playerID] != nil);
            BOOL alreadyAdded = [ids containsObject:participant.playerID];
            
            if (!cached && !alreadyAdded)
            {
                NSLog(@"About to fetch player %@", participant.playerID);
                [ids addObject:participant.playerID];
            }
        }
    }
    
    [[GameKitTurnBasedMatchHelper sharedInstance] getPlayerInfo:ids delegate:APP_DELEGATE.playerCache];
}

+ (NSString*)matchStatusDisplayName:(GKTurnBasedMatchStatus)status
{
    NSString *name = @"";
    
    switch (status)
    {
        case GKTurnBasedMatchStatusOpen:
            name = @"Open";
            break;
            
        case GKTurnBasedMatchStatusEnded:
            name = @"Game Over";
            break;
            
        case GKTurnBasedMatchStatusMatching:
            name = @"Waiting";
            break;
            
        default:
            name = @"???";
            break;
    }
    
    return name;
}

- (void)quitMatch:(GKTurnBasedMatch*)match forParticipant:(GKTurnBasedParticipant*)participant
{
    NSString *localPlayerID = [GKLocalPlayer localPlayer].playerID;
    BOOL isLocalPlayer = [localPlayerID isEqualToString:participant.playerID];
    BOOL isCurrentParticipant = [match.currentParticipant.playerID isEqualToString:participant.playerID];
    NSArray *activeParticipants = [GameKitTurnBasedMatchHelper activeParticipantsInMatch:match];
    NSInteger activeParticipantCount = [activeParticipants count];

    if (isLocalPlayer)
    {
        if (isCurrentParticipant)
        {
            if (activeParticipantCount < 3)
            {
                // Set both players' match outcomes.
                // TODO: Determine if current player must quit first instead of ending immediately.
                // TODO: Determine what callback happens for the opponent.
                
                for (GKTurnBasedParticipant *p in activeParticipants)
                {
                    if (p.matchOutcome != GKTurnBasedMatchOutcomeQuit)
                    {
                        if ([p.playerID isEqualToString:localPlayerID])
                        {
                            // It's me.
                            p.matchOutcome = GKTurnBasedMatchOutcomeQuit;
                        }
                        else
                        {
                            // Opponent wins.
                            p.matchOutcome = GKTurnBasedMatchOutcomeWon;
                        }
                    }
                    
                    NSLog(@"[GVC] endGame participant %@ matchOutcome: %i",
                          [APP_DELEGATE.playerCache playerWithID:p.playerID].alias,
                          p.matchOutcome);
                }
                
                [match endMatchInTurnWithMatchData:match.matchData
                                 completionHandler:^(NSError *error) {
                                     if (error)
                                     {
                                         NSLog(@"[GKTBMH] quitMatch:forParticipant: endMatch error: %@", error.localizedDescription);
                                     }
                                     else
                                     {
                                         NSLog(@"[GKTBMH] quitMatch:forParticipant: endMatch completed.");
                                     }
                                 }];
            }
            else
            {
                NSArray *nextParticipants = [GameKitTurnBasedMatchHelper otherParticipantsInMatch:match];

                [match participantQuitInTurnWithOutcome:GKTurnBasedMatchOutcomeQuit
                                       nextParticipants:nextParticipants
                                            turnTimeout:INT_MAX
                                              matchData:match.matchData
                                      completionHandler:^(NSError *error) {
                                          if (error)
                                          {
                                              NSLog(@"[GKTBMH] quitMatch:forParticipant: error: %@", error.localizedDescription);
                                          }
                                          else
                                          {
                                              NSLog(@"[GKTBMH] quitMatch:forParticipant: completed.");
                                          }
                                      }];
            }
        }
        else
        {
            [match participantQuitOutOfTurnWithOutcome:GKTurnBasedMatchOutcomeQuit
                                 withCompletionHandler:^(NSError *error) {
                                     if (error)
                                     {
                                         NSLog(@"[GKTBMH] quitMatch:forParticipant: quit out of turn error: %@", error.localizedDescription);
                                     }
                                     else
                                     {
                                         NSLog(@"[GKTBMH] quitMatch:forParticipant: quit out of turn completed.");
                                     }
                                 }];
        }
    }
    else
    {
        // TODO: Figure out if this ever happens.
        NSAssert(NO, @"[GKTBMH] I wasn't sure that quitMatch:forParticipant: would be called for other players.");
    }
    
}

+ (GKTurnBasedParticipant*)participantForLocalPlayerInMatch:(GKTurnBasedMatch*)match
{
    NSString *localPlayerID = [GKLocalPlayer localPlayer].playerID;
    GKTurnBasedParticipant *localPlayerParticipant = nil;
    
    for (GKTurnBasedParticipant *p in match.participants)
    {
        if ([p.playerID isEqualToString:localPlayerID])
        {
            localPlayerParticipant = p;
            break;
        }
    }
    
    return localPlayerParticipant;
}

// Returns an array of participants after match's current participant.
+ (NSArray*)otherParticipantsInMatch:(GKTurnBasedMatch*)match
{
    NSUInteger currentIndex = [match.participants indexOfObject:match.currentParticipant];
    NSMutableArray *nextParticipants = [NSMutableArray array];
    NSInteger matchSize = [match.participants count];
    
    if (matchSize > 0)
    {
        for (int i = 0; i < matchSize; i++)
        {
            GKTurnBasedParticipant *p = [match.participants
                                         objectAtIndex:(currentIndex + 1 + i) %
                                         matchSize];
            
            if (![p.playerID isEqualToString:match.currentParticipant.playerID] &&
                p.status == GKTurnBasedParticipantStatusActive &&
                p.matchOutcome == GKTurnBasedMatchOutcomeNone)
            {
                [nextParticipants addObject:p];
            }
        }
    }
    
    return nextParticipants;
}

+ (NSArray*)activeParticipantsInMatch:(GKTurnBasedMatch*)match
{
    NSMutableArray *a = [NSMutableArray array];
    
    for (GKTurnBasedParticipant *p in match.participants)
    {
        if (p.status == GKTurnBasedParticipantStatusActive &&
            p.matchOutcome == GKTurnBasedMatchOutcomeNone)
        {
            [a addObject:p];
        }
    }
    
    return a;
}

@end
