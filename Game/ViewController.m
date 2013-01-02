//
//  ViewController.m
//  Game
//
//  Created by P. Mark Anderson on 1/1/13.
//  Copyright (c) 2013 Bordertown Labs. All rights reserved.
//

#import "ViewController.h"
#import "GameKitTurnBasedMatchHelper.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)findMatch
{
    [[GameKitTurnBasedMatchHelper sharedInstance] findMatchWithMinPlayers:2
                                                               maxPlayers:2
                                                      showExistingMatches:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self findMatch];
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
        int playerNum = [match.participants
                         indexOfObject:match.currentParticipant] + 1;
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
    // Tell user: Player 1's Turn (that's you)
    
}

-(void)takeTurn:(GKTurnBasedMatch *)match
{
    NSLog(@"Taking turn for existing game...");

    int playerNum = [match.participants
                     indexOfObject:match.currentParticipant] + 1;
    
    NSString *statusString = [NSString stringWithFormat:
                              @"Player %d's Turn (that's you)", playerNum];
    
    NSLog(@"takeTurn: %@", statusString);
    
    if ([match.matchData bytes])
    {
//        NSString *storySoFar = [NSString stringWithUTF8String:
//                                [match.matchData bytes]];
    }
    
    [self checkForEnding:match.matchData];
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
    GKTurnBasedMatch *currentMatch = [[GameKitTurnBasedMatchHelper sharedInstance] currentMatch];

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

@end
