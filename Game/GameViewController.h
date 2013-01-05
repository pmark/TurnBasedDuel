//
//  GameViewController.h
//  Game
//
//  Created by P. Mark Anderson on 1/2/13.
//  Copyright (c) 2013 Bordertown Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

@interface GameViewController : UIViewController

@property (nonatomic, strong) GKTurnBasedMatch *match;
@property (weak, nonatomic) IBOutlet UILabel *player1Label;
@property (weak, nonatomic) IBOutlet UILabel *player2Label;
@property (weak, nonatomic) IBOutlet UIImageView *player1Photo;
@property (weak, nonatomic) IBOutlet UIImageView *player2Photo;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

- (IBAction)backButtonWasTapped:(id)sender;
- (IBAction)playButtonWasTapped:(UIButton *)sender;

@end
