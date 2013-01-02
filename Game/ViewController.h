//
//  ViewController.h
//  Game
//
//  Created by P. Mark Anderson on 1/1/13.
//  Copyright (c) 2013 Bordertown Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameKitTurnBasedMatchHelper.h"

@interface ViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, GameKitTurnBasedMatchHelperDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *menuCollection;

@property (nonatomic, strong) NSMutableArray *matches;

- (IBAction)newGameButtonWasTapped:(id)sender;

@end
