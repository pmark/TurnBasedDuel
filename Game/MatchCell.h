//
//  MatchCell.h
//  Game
//
//  Created by P. Mark Anderson on 1/3/13.
//  Copyright (c) 2013 Bordertown Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

@interface MatchCell : UICollectionViewCell

@property (assign, nonatomic) GKTurnBasedMatch *match;
@property (strong, nonatomic) NSString *player1ID;
@property (strong, nonatomic) NSString *player2ID;
@property (weak, nonatomic) IBOutlet UILabel *status;
@property (weak, nonatomic) IBOutlet UILabel *opponent;
@property (weak, nonatomic) IBOutlet UILabel *matchName;
@property (weak, nonatomic) IBOutlet UIImageView *player1Photo;
@property (weak, nonatomic) IBOutlet UIImageView *player2Photo;
@property (weak, nonatomic) IBOutlet UILabel *matchStatus;

- (IBAction)removeButtonWasTapped:(UIButton *)sender;

@end
