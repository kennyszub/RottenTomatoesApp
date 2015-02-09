//
//  MovieDetailViewController.m
//  Rotten Tomatoes
//
//  Created by Ken Szubzda on 2/7/15.
//  Copyright (c) 2015 Ken Szubzda. All rights reserved.
//

#import "MovieDetailViewController.h"
#import "UIImageView+AFNetworking.h"


@interface MovieDetailViewController ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *synopsisLabel;
@property (weak, nonatomic) IBOutlet UIImageView *posterView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property BOOL scrollViewIsUp;
@property CGRect originalScrollViewFrame;
@end

@implementation MovieDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // set title and synoposis
    self.titleLabel.text = self.movie[@"title"];
    self.synopsisLabel.text = self.movie[@"synopsis"];
    self.title = self.movie[@"title"];
    
    self.scrollViewIsUp = NO;
    
    // set poster
    NSString *url = [self.movie valueForKeyPath:@"posters.original"];
    [self.posterView setImageWithURL:[NSURL URLWithString:url]];
    url = [url stringByReplacingOccurrencesOfString:@"tmb" withString:@"ori"];
    [self.posterView setImageWithURL:[NSURL URLWithString:url]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.synopsisLabel sizeToFit];

    // determine scrollview content size
    CGRect contentRect = CGRectZero;
    for (UIView *view in self.scrollView.subviews) {
        contentRect = CGRectUnion(contentRect, view.frame);
    }
    self.scrollView.contentSize = contentRect.size;
    
    self.originalScrollViewFrame = self.scrollView.frame;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)scrollViewTapped:(id)sender {
    NSLog(@"scrollview tapped");
    CGRect viewRect;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    if (self.scrollViewIsUp) {
        self.scrollViewIsUp = NO;
        viewRect = self.originalScrollViewFrame;
    } else {
        self.scrollViewIsUp = YES;
        viewRect = CGRectMake(0, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height, self.scrollView.frame.size.width, screenRect.size.height);
    }

    [UIView animateWithDuration:.75 animations:^{
        self.scrollView.frame = viewRect;
    }];
    
    // determine scrollview content size
    CGRect contentRect = CGRectZero;
    for (UIView *view in self.scrollView.subviews) {
        contentRect = CGRectUnion(contentRect, view.frame);
    }
    contentRect.size.height += 50;
    self.scrollView.contentSize = contentRect.size;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
