//
//  MoviesViewController.m
//  Rotten Tomatoes
//
//  Created by Ken Szubzda on 2/4/15.
//  Copyright (c) 2015 Ken Szubzda. All rights reserved.
//

#import "MoviesViewController.h"
#import "MovieCell.h"
#import "UIImageView+AFNetworking.h"
#import "MovieDetailViewController.h"
#import "SVProgressHUD.h"
#import "MovieCollectionCell.h"

@interface MoviesViewController () <UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property UIRefreshControl *refreshControl;
@property NSArray *movies;
@property UILabel *networkErrorLabel;
@property UISegmentedControl *gridListControl;
@end

@implementation MoviesViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // table view setup
    self.tableView.hidden = YES;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerNib:[UINib nibWithNibName:@"MovieCell" bundle:nil] forCellReuseIdentifier:@"MovieCell"];
    
    // collection view setup
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerNib:[UINib nibWithNibName:@"MovieCollectionCell" bundle:nil] forCellWithReuseIdentifier:@"MovieCollectionCell"];
    
    // display loading HUD
    [SVProgressHUD show];
    // get data
    [self onRefresh];

    self.title = @"Box Office Movies";
    
    // add refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(onRefresh) forControlEvents:UIControlEventValueChanged];
    [self.collectionView insertSubview:self.refreshControl atIndex:0];
    
    // set grid list segmented control
    NSArray *iconArray = [NSArray arrayWithObjects:[UIImage imageNamed:@"grid"], [UIImage imageNamed:@"list"], nil];
    self.gridListControl = [[UISegmentedControl alloc] initWithItems:iconArray];
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.gridListControl];
    self.navigationItem.rightBarButtonItem = barButtonItem;
    [self.gridListControl addTarget:self action:@selector(segmentedControlValueDidChange:) forControlEvents:UIControlEventValueChanged];
    self.gridListControl.selectedSegmentIndex = 0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Segmented control methods
- (void)segmentedControlValueDidChange:(UISegmentedControl *)segment {
    switch (segment.selectedSegmentIndex) {
        case 0: {
            self.tableView.hidden = YES;
            self.collectionView.hidden = NO;
            [self.collectionView insertSubview:self.refreshControl atIndex:0];
            break;
        }
        case 1: {
            self.tableView.hidden = NO;
            self.collectionView.hidden = YES;
            [self.tableView insertSubview:self.refreshControl atIndex:0];
            break;
        }
    }
}

#pragma mark - Collection view methods
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.movies.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MovieCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MovieCollectionCell" forIndexPath:indexPath];
    NSDictionary *movie = self.movies[indexPath.row];

    cell.titleLabel.text = movie[@"title"];
    
    NSString *rating = [movie valueForKeyPath:@"ratings.critics_score"];
    cell.criticScore.text = [NSString stringWithFormat:@"%@%%", rating];
    if ([rating intValue] >= 60) {
        cell.freshRottenView.image = [UIImage imageNamed:@"fresh"];
    } else {
        cell.freshRottenView.image = [UIImage imageNamed:@"rotten"];
    }
    
    cell.posterView.image = nil;
    NSString *url = [movie valueForKeyPath:@"posters.thumbnail"];
    url = [url stringByReplacingOccurrencesOfString:@"tmb" withString:@"ori"];
    [cell.posterView setImageWithURL:[NSURL URLWithString:url]];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    MovieDetailViewController *vc = [[MovieDetailViewController alloc] init];
    vc.movie = self.movies[indexPath.row];
    
    [self.navigationController pushViewController:vc animated:YES];
}
#pragma mark - Table methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.movies.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MovieCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MovieCell" forIndexPath:indexPath];
    NSDictionary *movie = self.movies[indexPath.row];
    
    cell.titleLabel.text = movie[@"title"];
    cell.synopsisLabel.text = movie[@"synopsis"];
    
    NSString *url = [movie valueForKeyPath:@"posters.thumbnail"];
    cell.posterView.image = nil;
    [cell.posterView setImageWithURL:[NSURL URLWithString:url]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MovieDetailViewController *vc = [[MovieDetailViewController alloc] init];
    vc.movie = self.movies[indexPath.row];
    
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Network methods
- (void)showNetworkError {
    CGRect viewRect = CGRectMake(0, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height, self.tableView.frame.size.width, 40);
    UILabel *errorLabel = [[UILabel alloc] initWithFrame:viewRect];
    errorLabel.text = @"Network Error";
    errorLabel.textAlignment = NSTextAlignmentCenter;
    errorLabel.backgroundColor = [UIColor yellowColor];
    self.networkErrorLabel = errorLabel;
    [self.view.superview addSubview:self.networkErrorLabel];
}

- (void)hideNetworkError {
    [self.networkErrorLabel setHidden:YES];
}

- (void)onRefresh {
    NSURL *url = [NSURL URLWithString:@"http://api.rottentomatoes.com/api/public/v1.0/lists/movies/box_office.json?apikey=7gc6v2tkga4wsbsq5qfk7kyd&limit=20"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (data == nil) {
            // show network error
            [self showNetworkError];
        } else {
            [self hideNetworkError];
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            // TODO remove me
            NSLog(@"response: %@", responseDictionary);
            self.movies = responseDictionary[@"movies"];
            [self.tableView reloadData];
            [self.collectionView reloadData];
        }
        [self.refreshControl endRefreshing];
        [SVProgressHUD dismiss];
    }];
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
