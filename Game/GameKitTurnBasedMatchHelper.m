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
    [self dismissModalViewController];
    NSLog(@"did find match, %@", match);
    
    self.currentMatch = match;
    
    GKTurnBasedParticipant *firstParticipant = [match.participants objectAtIndex:0];
    
    if (firstParticipant.lastTurnDate == NULL)
    {
        // It's a new game!
        [self.tbDelegate enterNewGame:match];
    }
    else
    {
        if ([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID])
        {
            // It's your turn!
            [self.tbDelegate takeTurn:match];
        }
        else
        {
            // It's not your turn, just display the game state.
            [self.tbDelegate layoutMatch:match];
        }
    }
}

-(void)turnBasedMatchmakerViewControllerWasCancelled:(GKTurnBasedMatchmakerViewController *)viewController
{
    [self dismissModalViewController];
    NSLog(@"has cancelled");
}

-(void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController
                        didFailWithError:(NSError *)error
{
    [self dismissModalViewController];
    NSLog(@"Error finding match: %@", error.localizedDescription);
}

-(void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController
                      playerQuitForMatch:(GKTurnBasedMatch *)match
{
    NSUInteger currentIndex = [match.participants indexOfObject:match.currentParticipant];
    GKTurnBasedParticipant *part;
    
    NSMutableArray *nextParticipants = [NSMutableArray array];
    
    for (int i = 0; i < [match.participants count]; i++)
    {        
        part = [match.participants objectAtIndex:(currentIndex + 1 + i) % match.participants.count];
        
        if (part.matchOutcome != GKTurnBasedMatchOutcomeQuit)
        {
            [nextParticipants addObject:part];
        }
    }

    NSLog(@"playerquitforMatch, %@, %@", match, match.currentParticipant);
    
    [match participantQuitInTurnWithOutcome:GKTurnBasedMatchOutcomeQuit
                           nextParticipants:nextParticipants
                                turnTimeout:INT_MAX
                                  matchData:match.matchData
                          completionHandler:nil];
}


#pragma mark GKTurnBasedEventHandlerDelegate

-(void)handleInviteFromGameCenter:(NSArray *)playersToInvite
{
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
    NSLog(@"Turn has happened");
    
    if ([match.matchID isEqualToString:self.currentMatch.matchID])
    {
        if ([match.currentParticipant.playerID
             isEqualToString:[GKLocalPlayer localPlayer].playerID])
        {
            // it's the current match and it's our turn now
            self.currentMatch = match;
            [self.tbDelegate takeTurn:match];
        }
        else
        {
            // it's the current match, but it's someone else's turn
            self.currentMatch = match;
            [self.tbDelegate layoutMatch:match];
        }
    }
    else
    {
        if ([match.currentParticipant.playerID
             isEqualToString:[GKLocalPlayer localPlayer].playerID])
        {
            // it's not the current match and it's our turn now
            [self.tbDelegate sendNotice:@"It's your turn for another match"
                        forMatch:match];
        }
        else
        {
            // it's the not current match, and it's someone else's
            // turn
        }
    }
}

-(void)handleMatchEnded:(GKTurnBasedMatch *)match
{
    NSLog(@"Game has ended");
    
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
        self.matches = matches;
        
        if (self.tbDelegate)
        {
            [self.tbDelegate didFetchMatches:matches];
        }
    }];
}

@end
