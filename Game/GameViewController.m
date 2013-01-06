//
//  GameViewController.m
//  Game
//
//  Created by P. Mark Anderson on 1/2/13.
//  Copyright (c) 2013 Bordertown Labs. All rights reserved.
//

#import "GameViewController.h"
#import "PlayerCache.h"
#import "AppDelegate.h"
#import "GameKitTurnBasedMatchHelper.h"

#define READY_STATUS @"It is your turn."
#define WAITING_STATUS @"Waiting for opponent to play."
#define SENDING_STATUS @"..."
#define ERROR_STATUS @"Sorry, please try again."

@interface GameViewController ()

@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePlayerInfo)
                                                 name:NOTIF_PLAYER_CACHE_DID_FETCH_PLAYERS
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoWasFetched:)
                                                 name:NOTIF_PLAYER_CACHE_DID_FETCH_PLAYER_PHOTO
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(:)
                                                 name:NOTIF_MATCH_TURN_CHANGED_TO_LOCAL_PLAYER
                                               object:self.match];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleTurn:)
                                                 name:NOTIF_TURN_EVENT
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(localPlayerWon:)
                                                 name:NOTIF_MATCH_WON_BY_LOCAL_PLAYER
                                               object:nil];
    
    //    GKTurnBasedParticipant *participant1 = (GKTurnBasedParticipant *)[self.match.participants objectAtIndex:0];
    //    GKTurnBasedParticipant *participant2 = (GKTurnBasedParticipant *)[self.match.participants objectAtIndex:1];
    //    NSArray *playerIDs = [NSArray arrayWithObjects:participant1.playerID, participant2.playerID, nil];
    
    //    [[GameKitTurnBasedMatchHelper sharedInstance] getPlayerInfo:playerIDs delegate:APP_DELEGATE.playerCache];
    
    [self updatePlayerInfo];
 
    [self updateTurn];
}

- (void)updateTurn
{
    if ([[GKLocalPlayer localPlayer].playerID isEqualToString:self.match.currentParticipant.playerID])
    {
        self.statusLabel.text = READY_STATUS;
        self.playButton.enabled = YES;
    }
    else
    {
        self.statusLabel.text = WAITING_STATUS;
        self.playButton.enabled = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [GameKitTurnBasedMatchHelper sharedInstance].currentMatch = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonWasTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

- (IBAction)playButtonWasTapped:(UIButton *)sender
{
    sender.enabled = NO;
    self.statusLabel.text = SENDING_STATUS;
    
    
    GKTurnBasedMatch *currentMatch = self.match;
    
    NSData *data = [@"Play" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSUInteger currentIndex = [currentMatch.participants indexOfObject:currentMatch.currentParticipant];
    GKTurnBasedParticipant *nextParticipant;
    
    NSMutableArray *nextParticipants = [NSMutableArray array];
    
    for (int i = 0; i < [currentMatch.participants count]; i++)
    {
        nextParticipant = [currentMatch.participants
                           objectAtIndex:((currentIndex + 1 + i) %
                                          [currentMatch.participants count ])];
        
        if (nextParticipant.matchOutcome != GKTurnBasedMatchOutcomeQuit)
        {
            [nextParticipants addObject:nextParticipant];
        }
    }

    if (NO)
    {
        // Tie
        
        for (GKTurnBasedParticipant *part in currentMatch.participants)
        {
            part.matchOutcome = GKTurnBasedMatchOutcomeTied;
        }
        
        [currentMatch endMatchInTurnWithMatchData:data
                                completionHandler:^(NSError *error) {
                                    if (error)
                                    {
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
                                        self.statusLabel.text = ERROR_STATUS;
                                        self.playButton.enabled = YES;
                                    }
                                    else
                                    {
                                        self.statusLabel.text = WAITING_STATUS;
                                    }
                                }];
    }

    NSLog(@"Send turn, %@, %@", data, nextParticipant);

}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:^{
        // ???
    }];
}

- (IBAction)resignButtonWasTapped:(id)sender
{
    // TODO: Be busy.

    [self bowOut];
}

- (void)endGame
{
    NSString *localPlayerID = [GKLocalPlayer localPlayer].playerID;
    
    if ([self.match.currentParticipant.playerID isEqualToString:localPlayerID])
    {
        // I quit on my turn.
        
        for (GKTurnBasedParticipant *participant in self.match.participants)
        {
            if (participant.matchOutcome != GKTurnBasedMatchOutcomeQuit)
            {
                if ([participant.playerID isEqualToString:localPlayerID])
                {
                    // It's me.
                    participant.matchOutcome = GKTurnBasedMatchOutcomeQuit;
                }
                else
                {
                    // Opponent wins.
                    participant.matchOutcome = GKTurnBasedMatchOutcomeWon;
                }
            }
            
            NSLog(@"[GVC] endGame participant %@ matchOutcome: %i", [APP_DELEGATE.playerCache playerWithID:participant.playerID].alias, participant.matchOutcome);
        }
        
        [self.match endMatchInTurnWithMatchData:self.match.matchData
                              completionHandler:^(NSError *error) {
                                  
                                  if (error)
                                  {
                                      NSLog(@"[GVC] endGame endMatchInTurnWithMatchData error: %@", error.localizedDescription);
                                  }
                                  else
                                  {
                                      NSLog(@"[GVC] endGame endMatchInTurnWithMatchData completed.");
                                  }
                                  
                                  // Send notification.
                                  
                                  NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                            self.match, @"match",
                                                            nil];
                                  
                                  [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_MATCH_QUIT_BY_LOCAL_PLAYER
                                                                                      object:nil
                                                                                    userInfo:userInfo];
                                  
                                  [self performSelectorOnMainThread:@selector(dismiss) withObject:nil waitUntilDone:NO];

                              }];
    }
    else
    {
        // It's not my turn.
        
        [self.match participantQuitOutOfTurnWithOutcome:GKTurnBasedMatchOutcomeQuit
                                  withCompletionHandler:^(NSError *error) {
                                      if (error)
                                      {
                                          NSLog(@"[GVC] endGame out of turn error: %@", error.localizedDescription);
                                      }
                                      else
                                      {
                                          NSLog(@"[GVC] endGame out of turn completed.");
                                      }
                                      
                                      [self performSelectorOnMainThread:@selector(dismiss) withObject:nil waitUntilDone:NO];
                                  }];
    }

}

//
// Use this for matches that involve more than 2 players.
//
- (void)bowOut
{
    NSString *localPlayerID = [GKLocalPlayer localPlayer].playerID;
    NSMutableArray *nextParticipants = [NSMutableArray array];
    
    if ([self.match.currentParticipant.playerID isEqualToString:localPlayerID])
    {
        // I quit.
        
        NSUInteger currentIndex = [self.match.participants indexOfObject:self.match.currentParticipant];
        GKTurnBasedParticipant *participant;
        
        for (int i = 0; i < [self.match.participants count]; i++)
        {
            participant = [self.match.participants objectAtIndex:(currentIndex + 1 + i) %
                           self.match.participants.count];
            
            if (participant.matchOutcome != GKTurnBasedMatchOutcomeQuit &&
                ![participant.playerID isEqualToString:localPlayerID])
            {
                [nextParticipants addObject:participant];
            }
        }
        
        [self.match participantQuitInTurnWithOutcome:GKTurnBasedMatchOutcomeQuit
                                    nextParticipants:nextParticipants
                                         turnTimeout:INT_MAX
                                           matchData:self.match.matchData
                                   completionHandler:^(NSError *error) {
                                       if (error)
                                       {
                                           NSLog(@"[GVC] bowOut during my turn error: %@", error.localizedDescription);
                                       }
                                       else
                                       {
                                           NSLog(@"[GVC] bowOut during my turn completed.");
                                       }

                                       [self performSelectorOnMainThread:@selector(dismiss) withObject:nil waitUntilDone:NO];
                                   }];
    }
    
    if ([nextParticipants count] == 0)
    {
        [self.match participantQuitOutOfTurnWithOutcome:GKTurnBasedMatchOutcomeQuit
                                  withCompletionHandler:^(NSError *error) {
                                      if (error)
                                      {
                                          NSLog(@"[GVC] bowOut out of turn error: %@", error.localizedDescription);
                                      }
                                      else
                                      {
                                          NSLog(@"[GVC] bowOut out of turn completed.");
                                      }
                                      
                                      [self performSelectorOnMainThread:@selector(dismiss) withObject:nil waitUntilDone:NO];
                                  }];
    }
}

-(void)localPlayerWon:(NSNotification*)notif
{
    NSLog(@"localPlayerWon");
    
}

-(void)updatePlayerInfo
{
    GKTurnBasedParticipant *participant1 = (GKTurnBasedParticipant *)[self.match.participants objectAtIndex:0];
    GKPlayer *player1 = [APP_DELEGATE.playerCache playerWithID:participant1.playerID];
    self.player1Label.text = player1.alias;
    
    UIImage *image = [APP_DELEGATE.playerCache photoForPlayer:player1];
    
    if (image)
    {
        [self performSelectorOnMainThread:@selector(setPlayer1PhotoImage:) withObject:image waitUntilDone:YES];
    }
    else
    {
        [[GameKitTurnBasedMatchHelper sharedInstance] loadPlayerPhoto:player1];
    }

    
    GKTurnBasedParticipant *participant2 = (GKTurnBasedParticipant *)[self.match.participants objectAtIndex:1];
    GKPlayer *player2 = [APP_DELEGATE.playerCache playerWithID:participant2.playerID];
    self.player2Label.text = player2.alias;

    image = [APP_DELEGATE.playerCache photoForPlayer:player2];
    
    if (image)
    {
        [self performSelectorOnMainThread:@selector(setPlayer2PhotoImage:) withObject:image waitUntilDone:YES];
    }
    else
    {
        [[GameKitTurnBasedMatchHelper sharedInstance] loadPlayerPhoto:player2];
    }
}

- (void)setPlayer1PhotoImage:(UIImage*)image
{
    self.player1Photo.image = image;
    NSLog(@"Set image 1 with width %f %@", image.size.width, self.player1Photo);
}

- (void)setPlayer2PhotoImage:(UIImage*)image
{
    self.player2Photo.image = image;
    NSLog(@"Set image 2 with width %f %@", image.size.width, self.player2Photo);
}

-(void)photoWasFetched:(NSNotification*)notif
{
    GKPlayer *player = (GKPlayer*)[notif.userInfo objectForKey:@"player"];
    UIImage *photo = (UIImage*)[notif.userInfo objectForKey:@"photo"];
    
    // Set proper player's photo.
    
    NSInteger i = 0;
    
    for (GKTurnBasedParticipant *participant in self.match.participants)
    {
        if ([participant.playerID isEqualToString:player.playerID])
        {
            NSLog(@"Fetched photo for player %@", participant.playerID);
            
            if (i == 0)
            {
                [self performSelectorOnMainThread:@selector(setPlayer1PhotoImage:) withObject:photo waitUntilDone:NO];
            }
            else
            {
                [self performSelectorOnMainThread:@selector(setPlayer2PhotoImage:) withObject:photo waitUntilDone:NO];
            }
            
            break;
        }

        i++;
    }
}

-(void)handleTurn:(NSNotification*)notif
{
    GKTurnBasedMatch *match = (GKTurnBasedMatch*)[notif.userInfo objectForKey:@"match"];
    
    NSLog(@"[GVC] handleTurn: Notified match is %@ and the current game's match is %@", match.matchID, self.match.matchID);
    
    if ([match.matchID isEqualToString:self.match.matchID])
    {
        self.match = match;
        GKPlayer *playerWithTurn = [APP_DELEGATE.playerCache playerWithID:match.currentParticipant.playerID];
        
        NSLog(@"[GVC] Received turn event. It is %@'s turn now.", playerWithTurn.alias);

        
        [self updatePlayerInfo];

        [self updateTurn];
    }
    else
    {
        NSLog(@"[GVC] Received turn event for a different match.");
    }
    
}

@end
