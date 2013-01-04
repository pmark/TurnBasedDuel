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

@interface GameViewController ()

@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    GKTurnBasedParticipant *participant1 = (GKTurnBasedParticipant *)[self.match.participants objectAtIndex:0];
    GKTurnBasedParticipant *participant2 = (GKTurnBasedParticipant *)[self.match.participants objectAtIndex:1];
    NSArray *playerIDs = [NSArray arrayWithObjects:participant1.playerID, participant2.playerID, nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playersWereFetched:)
                                                 name:NOTIF_PLAYER_CACHE_DID_FETCH_PLAYERS
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoWasFetched:)
                                                 name:NOTIF_PLAYER_CACHE_DID_FETCH_PLAYER_PHOTO
                                               object:nil];
    
    [[GameKitTurnBasedMatchHelper sharedInstance] getPlayerInfo:playerIDs delegate:APP_DELEGATE.playerCache];
 
    NSLog(@"photos: %@ and %@", self.player1Photo, self.player2Photo);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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

-(void)playersWereFetched:(NSNotification*)notif
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

@end
