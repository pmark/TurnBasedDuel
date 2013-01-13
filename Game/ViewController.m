//
//  ViewController.m
//  Game
//
//  Created by P. Mark Anderson on 1/1/13.
//  Copyright (c) 2013 Bordertown Labs. All rights reserved.
//

#import "ViewController.h"
#import "GameViewController.h"
#import "MatchCell.h"
#import "AppDelegate.h"

@interface ViewController ()

@property (nonatomic, strong) GKTurnBasedMatch *currentMatch;
@property (nonatomic, strong) NSMutableArray *sortedMatches;

// Navigate to new game after view appears
//@property (nonatomic, strong)

@end

@implementation ViewController

- (IBAction)moreButtonWasTapped:(UIButton *)sender
{
    NSLog(@"More button");
}

- (IBAction)newGameButtonWasTapped:(UIButton *)sender
{
    [self findMatch];
}

- (void)findMatch
{
    [[GameKitTurnBasedMatchHelper sharedInstance] findMatchWithMinPlayers:2
                                                               maxPlayers:2
                                                      showExistingMatches:YES];
}

#pragma mark -


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [GameKitTurnBasedMatchHelper sharedInstance].tbDelegate = self;
    
    [self loadMatches];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadMatches) name:NOTIF_TURN_EVENT object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadMatches) name:NOTIF_MATCH_QUIT_BY_LOCAL_PLAYER object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchMatches) name:UIApplicationDidBecomeActiveNotification object:nil];
    
}

- (void)loadMatches
{
    // TODO: Sort by last move time.
    self.sortedMatches = [NSMutableArray arrayWithArray:[[GameKitTurnBasedMatchHelper sharedInstance].matches allValues]];
    [self.menuCollection reloadData];
    
}

- (void)fetchMatches
{
    [[GameKitTurnBasedMatchHelper sharedInstance] loadMatches];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"\n\nviewWillAppear\n\n");
    
    [self loadMatches];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    GKTurnBasedMatch *matchToLoad = [GameKitTurnBasedMatchHelper sharedInstance].currentMatch;

    if (matchToLoad)
    {
        [self performSegueWithIdentifier:@"GameSegue" sender:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -



#pragma mark - GCTurnBasedMatchHelperDelegate

-(void)layoutMatch:(GKTurnBasedMatch *)match
{
    NSLog(@"Viewing match where it's not our turn...");
    NSString *statusString;
    
    if (match.status == GKTurnBasedMatchStatusEnded)
    {
        statusString = @"Match Ended";
    }
    else
    {
        int playerNum = [match.participants indexOfObject:match.currentParticipant] + 1;

        statusString = [NSString stringWithFormat:
                        @"Player %d's Turn", playerNum];
    }
    
//    NSString *storySoFar = [NSString stringWithUTF8String:
//                            [match.matchData bytes]];
    
    [self checkForEnding:match.matchData];
}

-(void)enterNewGame:(GKTurnBasedMatch *)match
{
    NSLog(@"Entering new game...");
    
    [[GameKitTurnBasedMatchHelper sharedInstance] cachePlayerData];
    [GameKitTurnBasedMatchHelper sharedInstance].currentMatch = match;

    //    [self loadMatches];

}

-(void)takeTurn:(GKTurnBasedMatch *)match
{
    NSLog(@"Taking turn for existing game...");

//    int playerNum = [match.participants indexOfObject:match.currentParticipant] + 1;    
//    NSString *statusString = [NSString stringWithFormat:@"Player %d's Turn (that's you)", playerNum];
//    NSLog(@"takeTurn: %@", statusString);
//    [self checkForEnding:match.matchData];
    
    [[GameKitTurnBasedMatchHelper sharedInstance] cachePlayerData];
    [GameKitTurnBasedMatchHelper sharedInstance].currentMatch = match;
    
}

-(void)sendNotice:(NSString *)notice forMatch:(GKTurnBasedMatch *)match
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:
                       @"Another game needs your attention!"
                                                 message:notice
                                                delegate:self
                                       cancelButtonTitle:@"Sweet!"
                                       otherButtonTitles:nil];
    [av show];
}

-(void)checkForEnding:(NSData *)matchData
{
    if ([matchData length] > 3000)
    {
    }
}

-(void)receiveEndGame:(GKTurnBasedMatch *)match
{
    [self layoutMatch:match];
}

#pragma mark -

- (IBAction)sendTurn:(id)sender
{
    GKTurnBasedMatch *currentMatch = [GameKitTurnBasedMatchHelper sharedInstance].currentMatch;

    NSString *newStoryString = @"Story";
    
    NSString *sendString = [NSString stringWithFormat:@"%@ %@",
                            @"old text", newStoryString];
    
    NSData *data = [sendString dataUsingEncoding:NSUTF8StringEncoding ];
//    mainTextController.text = sendString;
    
    NSUInteger currentIndex = [currentMatch.participants
                               indexOfObject:currentMatch.currentParticipant];
    
    NSUInteger nextIndex = (currentIndex + 1) % [currentMatch.participants count];
    GKTurnBasedParticipant *nextParticipant = [currentMatch.participants objectAtIndex:nextIndex];
    NSMutableArray *nextParticipants = [NSMutableArray array];
    
    for (int i = 0; i < [currentMatch.participants count]; i++)
    {
        nextParticipant = [currentMatch.participants
                           objectAtIndex:((currentIndex + 1 + i) %
                                          [currentMatch.participants count ])];
        
        if (nextParticipant.matchOutcome != GKTurnBasedMatchOutcomeQuit)
        {
            NSLog(@"isnt' quit %@", nextParticipant);
            [nextParticipants addObject:nextParticipant];
        }
        else
        {
            NSLog(@"next part %@", nextParticipant);
        }
    }
    
    if ([data length] > 3800)
    {
        // Data length reached the limit.
    
        for (GKTurnBasedParticipant *part in currentMatch.participants)
        {
            part.matchOutcome = GKTurnBasedMatchOutcomeTied;
        }
        
        [currentMatch endMatchInTurnWithMatchData:data
                                completionHandler:^(NSError *error) {
                                    if (error) {
                                        NSLog(@"%@", error);
                                    }
                                }];
    }
    else
    {
        [currentMatch endTurnWithNextParticipants:nextParticipants
                                      turnTimeout:INT_MAX
                                        matchData:data
                                completionHandler:^(NSError *error) {
                                    if (error)
                                    {
                                        NSLog(@"%@", error);
                                    }
                                    else
                                    {
                                    }
                                }];
    }

    NSLog(@"Send Turn, %@, %@", data, nextParticipant);
    
}

#pragma mark -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return [self.sortedMatches count];
    }
    else
    {
        return 2;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = nil;

    
    if (indexPath.section == 0)
    {
        // Match cell
        
        MatchCell *matchCell = (MatchCell*)[collectionView dequeueReusableCellWithReuseIdentifier:@"OneMatchCell"
                                                                                     forIndexPath:indexPath];

        GKTurnBasedMatch *match = [self.sortedMatches objectAtIndex:indexPath.row];
        GKPlayer *player1 = [APP_DELEGATE.playerCache player:0 amongParticipants:match.participants];
        GKPlayer *player2 = [APP_DELEGATE.playerCache player:1 amongParticipants:match.participants];
        
        NSString *player1ID = ((GKTurnBasedParticipant*)[match.participants objectAtIndex:0]).playerID;
        NSString *player2ID = ((GKTurnBasedParticipant*)[match.participants objectAtIndex:1]).playerID;
        
        matchCell.match = match;
        matchCell.player1ID = player1ID;
        matchCell.player2ID = player2ID;
        matchCell.matchName.text = match.matchID;

        GKPlayer *opponentPlayer = nil;
        if ([[GKLocalPlayer localPlayer].playerID isEqualToString:player1ID])
        {
            opponentPlayer = [APP_DELEGATE.playerCache playerWithID:player2ID];
        }
        else
        {
            opponentPlayer = [APP_DELEGATE.playerCache playerWithID:player1ID];
        }
        
        if (opponentPlayer)
        {
            NSString *msg = nil;
            for (GKTurnBasedParticipant *participant in match.participants)
            {
                NSLog(@"[VC] participant %@ matchOutcome: %i", [APP_DELEGATE.playerCache playerWithID:participant.playerID].alias, participant.matchOutcome);

                if (participant.matchOutcome != GKTurnBasedMatchOutcomeNone)
                {
                    if ([participant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID])
                    {
                        switch (participant.matchOutcome)
                        {
                            case GKTurnBasedMatchOutcomeWon:
                                msg = [NSString stringWithFormat:@"You beat %@", opponentPlayer.alias];
                                break;
                                
                            case GKTurnBasedMatchOutcomeLost:
                                msg = [NSString stringWithFormat:@"You lost to %@", opponentPlayer.alias];
                                break;
                                
                            case GKTurnBasedMatchOutcomeQuit:
                                msg = [NSString stringWithFormat:@"You forfeited to %@", opponentPlayer.alias];
                                break;
                                
                            default:
                                break;
                        }
                    }
                }
            }
            
            if (msg)
            {
                matchCell.opponent.text = msg;
            }
            else
            {
                matchCell.opponent.text = opponentPlayer.alias;
            }

        }
        else
        {
            matchCell.opponent.text = @"";
        }
        
        // If local player is the currentParticipant then it's my turn.
        
        if (match.status == GKTurnBasedMatchStatusOpen)
        {
            if ([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID])
            {
                matchCell.status.text = @"Your Turn";
                matchCell.status.textColor = [UIColor darkGrayColor];
            }
            else
            {
                matchCell.status.text = @"Waiting For Turn";
                matchCell.status.textColor = [UIColor lightGrayColor];
            }
        }
        else if (match.status == GKTurnBasedMatchStatusEnded)
        {
            matchCell.status.text = @"Game Over";
            matchCell.status.textColor = [UIColor darkGrayColor];
        }
        else if (match.status == GKTurnBasedMatchStatusMatching)
        {
            matchCell.status.text = @"Finding Opponent";
            matchCell.status.textColor = [UIColor lightGrayColor];
        }
        
        matchCell.player1Photo.image = [APP_DELEGATE.playerCache photoForPlayer:player1];
        matchCell.player2Photo.image = [APP_DELEGATE.playerCache photoForPlayer:player2];
        
//        matchCell.matchStatus.text = [GameKitTurnBasedMatchHelper matchStatusDisplayName:match.status];
        matchCell.matchStatus.text = @"";
        
        cell = matchCell;
        
//        NSLog(@"--------------------photo %@", matchCell.player1Photo.image);
    }
    else
    {
        // Buttons
        
        if (indexPath.row == 0)
        {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"NewMatchCell"
                                                             forIndexPath:indexPath];
        }
        else
        {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MoreCell"
                                                             forIndexPath:indexPath];
        }

    }

    return cell;    
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 2;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        // A match
        
        NSLog(@"Load match");
        
        [GameKitTurnBasedMatchHelper sharedInstance].currentMatch = (GKTurnBasedMatch *)[self.sortedMatches objectAtIndex:indexPath.row];
        
        [self performSegueWithIdentifier:@"GameSegue" sender:nil];

    }
    else
    {
    }

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"GameSegue"])
    {
        GameViewController *c = (GameViewController*)segue.destinationViewController;
        c.match = [GameKitTurnBasedMatchHelper sharedInstance].currentMatch;
    }
}

- (void)didFetchMatches:(NSArray*)matches
{
    [self loadMatches];
    [self.menuCollection reloadData];
    [[GameKitTurnBasedMatchHelper sharedInstance] cachePlayerData];
}

@end
