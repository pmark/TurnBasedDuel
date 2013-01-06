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
    NSLog(@"playerQuitForMatch, %@, %@", match.matchID, [APP_DELEGATE.playerCache playerWithID:match.currentParticipant.playerID].alias);
    

    NSUInteger currentIndex = [match.participants indexOfObject:match.currentParticipant];
    GKTurnBasedParticipant *part;
    
    NSMutableArray *nextParticipants = [NSMutableArray array];
    NSInteger matchSize = [match.participants count];
    
    for (int i = 0; i < matchSize; i++)
    {        
        part = [match.participants objectAtIndex:(currentIndex + 1 + i) % match.participants.count];
        
        if (part.matchOutcome != GKTurnBasedMatchOutcomeQuit)
        {
            [nextParticipants addObject:part];
        }
    }

    if ([nextParticipants count] < 2)
    {
        // Last person standing.
        
        [match endMatchInTurnWithMatchData:match.matchData
                         completionHandler:^(NSError *error) {
                             if (error)
                             {
                                 NSLog(@"[GKTBMH] endMatchInTurnWithMatchData error: %@", error.localizedDescription);
                             }
                             else
                             {
                                 NSLog(@"[GKTBMH] endMatchInTurnWithMatchData completed.");
                             }
                         }];
    }
    else
    {
        [match participantQuitInTurnWithOutcome:GKTurnBasedMatchOutcomeQuit
                               nextParticipants:nextParticipants
                                    turnTimeout:INT_MAX
                                      matchData:match.matchData
                              completionHandler:^(NSError *error) {
                                  if (error)
                                  {
                                      NSLog(@"[GKTBMH] participantQuitInTurnWithOutcome error: %@", error.localizedDescription);
                                  }
                                  else
                                  {
                                      NSLog(@"[GKTBMH] participantQuitInTurnWithOutcome completed.");
                                  }
                              }];
    }

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
    
    NSString *localPlayerID = [GKLocalPlayer localPlayer].playerID;
    BOOL myTurn = ([match.currentParticipant.playerID isEqualToString:localPlayerID]);


    // This happens after the other player quits too.
    
    BOOL gameOver = YES;
    GKTurnBasedParticipant *myParticipant = nil;
    
    for (GKTurnBasedParticipant *participant in match.participants)
    {
        NSLog(@"[GKTBMH] handleTurnEventForMatch %@ status: %i", [APP_DELEGATE.playerCache playerWithID:participant.playerID].alias, participant.matchOutcome);

        if ([participant.playerID isEqualToString:localPlayerID])
        {
            myParticipant = participant;
            
            
        }
        else if (participant.matchOutcome == GKTurnBasedMatchOutcomeNone)
        {
            gameOver = NO;
            break;
        }
    }
    
    if (gameOver)
    {
        // I win.
        myParticipant.matchOutcome = GKTurnBasedMatchOutcomeWon;
        
        if (myTurn)
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

            if (myTurn)
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

- (void)loadMatches
{
    [GKTurnBasedMatch loadMatchesWithCompletionHandler:^(NSArray *matches, NSError *error) {

        self.matches = [NSMutableDictionary dictionaryWithCapacity:[matches count]];

        for (GKTurnBasedMatch *oneMatch in matches)
        {
            [self.matches setValue:oneMatch forKey:oneMatch.matchID];
        }
        
        if (self.tbDelegate)
        {
            [self.tbDelegate didFetchMatches:matches];
        }
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

@end
