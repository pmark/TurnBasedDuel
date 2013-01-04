//
//  MatchCell.m
//  Game
//
//  Created by P. Mark Anderson on 1/3/13.
//  Copyright (c) 2013 Bordertown Labs. All rights reserved.
//

#import "MatchCell.h"
#import "PlayerCache.h"
#import "AppDelegate.h"
#import "GameKitTurnBasedMatchHelper.h"

@implementation MatchCell

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerWasFetched:)
                                                     name:NOTIF_PLAYER_CACHE_DID_FETCH_PLAYERS
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoWasFetched:)
                                                     name:NOTIF_PLAYER_CACHE_DID_FETCH_PLAYER_PHOTO
                                                   object:nil];
    }
    
    return self;
}

- (void)setPlayer1PhotoImage:(UIImage*)image
{
    NSLog(@"cell player1 image fetched");
    self.player1Photo.image = image;
}

- (void)setPlayer2PhotoImage:(UIImage*)image
{
    NSLog(@"cell player2 image fetched");
    self.player2Photo.image = image;
}

- (void)photoWasFetched:(NSNotification*)notif
{
    GKPlayer *player = (GKPlayer*)[notif.userInfo objectForKey:@"player"];
    UIImage *photo = (UIImage*)[notif.userInfo objectForKey:@"photo"];
    
    
    // Set proper player's photo.
    
    if ([player.playerID isEqualToString:self.player1ID])
    {
        [self performSelectorOnMainThread:@selector(setPlayer1PhotoImage:) withObject:photo waitUntilDone:NO];
    }
    else if ([player.playerID isEqualToString:self.player2ID])
    {
        [self performSelectorOnMainThread:@selector(setPlayer2PhotoImage:) withObject:photo waitUntilDone:NO];
    }
}

- (NSString*)opponentPlayerID
{
    if ([[GKLocalPlayer localPlayer].playerID isEqualToString:self.player1ID])
    {
        return self.player2ID;
    }
    else
    {
        return self.player1ID;
    }
}

- (void)setOpponentName:(NSString*)name
{
    self.opponent.text = name;
}

- (void)playerWasFetched:(NSNotification*)notif
{
    if ([self.opponent.text length] > 0)
        return;
    
    // Set opponent name.
    
    NSString *oid = [self opponentPlayerID];
    
    NSArray *players = (NSArray*)[notif.userInfo objectForKey:@"players"];
    
    for (GKPlayer *onePlayer in players)
    {
        if ([onePlayer.playerID isEqualToString:oid])
        {
            // This is the opponent.
            
            [self performSelectorOnMainThread:@selector(setOpponentName:)
                                   withObject:onePlayer.alias
                                waitUntilDone:YES];
            break;
        }
    }

}

@end
