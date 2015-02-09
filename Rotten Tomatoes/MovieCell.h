//
//  MovieCell.h
//  Rotten Tomatoes
//
//  Created by Ken Szubzda on 2/7/15.
//  Copyright (c) 2015 Ken Szubzda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MovieCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *synopsisLabel;
@property (weak, nonatomic) IBOutlet UIImageView *posterView;
@property (weak, nonatomic) IBOutlet UIImageView *rottonFreshView;
@property (weak, nonatomic) IBOutlet UILabel *criticsRating;

@end
