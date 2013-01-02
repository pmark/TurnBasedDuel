//
//  GameConstants.h
//  MonkeyJump
//
//  Created by Kauserali on 27/07/12.
//
//

#ifndef MonkeyJump_GameConstants_h
#define MonkeyJump_GameConstants_h
typedef enum {
    kMonkey,
    kSnake,
    kCroc,
    kHedgeHog
} GameElementType;

typedef enum {
  kIdleState,
  kWalking,
  kJumping,
  kDead
} MonkeyState;

#define kSnakeEnemyType 0
#define kCrocEnemyType 1
#define kHedgeHogEnemyType 2
#define kHighScoreLeaderboardCategory @"HighScores"
#define kAchievementsFileName @"Achievements.plist"
#define kAchievementsResourceName @"Achievements"

#endif
