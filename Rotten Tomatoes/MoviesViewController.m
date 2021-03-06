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

@interface MoviesViewController () <UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property UIRefreshControl *refreshControl;
@property NSArray *movies;
@property NSArray *filteredMovies;
@property UILabel *networkErrorLabel;
@property UISegmentedControl *gridListControl;
@property UISearchBar *searchBar;
@property BOOL searchBarActive;
@property UITapGestureRecognizer *screenTap;
@property (weak, nonatomic) IBOutlet UISearchBar *tableSearchBar;

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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.searchBar) {
        // add search bar to collection view
        self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height, [UIScreen mainScreen].bounds.size.width, 44)];
        [self.view addSubview:self.searchBar];
        self.searchBar.delegate = self;
    }
    
    self.tableSearchBar.delegate = self;
    
    // prepare collection view contentInset/ContentOffset so searchBar fit at the top
    self.collectionView.contentInset = UIEdgeInsetsMake(self.searchBar.frame.size.height, 0, 0, 0);
    self.collectionView.contentOffset = CGPointMake(0, - self.searchBar.frame.size.height);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark - Search methods
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length > 0) {
        NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(title contains[c] %@)", searchText];
        self.filteredMovies = [self.movies filteredArrayUsingPredicate:resultPredicate];
        self.searchBarActive = YES;
        [self.collectionView reloadData];
        [self.tableView reloadData];
    } else {
        self.filteredMovies = self.movies;
        [self.collectionView reloadData];
        [self.tableView reloadData];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    self.searchBarActive = YES;
    [self.view endEditing:YES];
}

- (void) searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [self.view removeGestureRecognizer:self.screenTap];
}

- (void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    // add tap recognizer
    self.screenTap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:self.screenTap];
}

- (void) dismissKeyboard {
    [self.view endEditing:YES];
}


#pragma mark - Segmented control methods
- (void)segmentedControlValueDidChange:(UISegmentedControl *)segment {
    switch (segment.selectedSegmentIndex) {
        case 0: {
            self.tableView.hidden = YES;
            self.collectionView.hidden = NO;
            self.searchBar.hidden = NO;
            [self.collectionView insertSubview:self.refreshControl atIndex:0];
            [self dismissKeyboard];
            break;
        }
        case 1: {
            self.tableView.hidden = NO;
            self.collectionView.hidden = YES;
            self.searchBar.hidden = YES;
            [self.tableView insertSubview:self.refreshControl atIndex:0];
            if (self.movies) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }
            [self dismissKeyboard];
            break;
        }
    }
}

#pragma mark - Collection view methods
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.searchBarActive) {
        return self.filteredMovies.count;
    } else {
        return self.movies.count;
    }
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MovieCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MovieCollectionCell" forIndexPath:indexPath];
    NSDictionary *movie;
    if (self.searchBarActive) {
        movie = self.filteredMovies[indexPath.row];
    } else {
        movie = self.movies[indexPath.row];
    }

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
    if (self.searchBarActive) {
        vc.movie = self.filteredMovies[indexPath.row];
    } else {
        vc.movie = self.movies[indexPath.row];
    }


    [self.view endEditing:YES];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Table methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchBarActive) {
        return self.filteredMovies.count;
    } else {
        return self.movies.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MovieCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MovieCell" forIndexPath:indexPath];
    NSDictionary *movie;
    if (self.searchBarActive) {
        movie = self.filteredMovies[indexPath.row];
    } else {
        movie = self.movies[indexPath.row];

    }
    
    cell.titleLabel.text = movie[@"title"];
    cell.synopsisLabel.text = movie[@"synopsis"];
    
    NSString *rating = [movie valueForKeyPath:@"ratings.critics_score"];
    cell.criticsRating.text = [NSString stringWithFormat:@"%@%%", rating];
    if ([rating intValue] >= 60) {
        cell.rottonFreshView.image = [UIImage imageNamed:@"fresh"];
    } else {
        cell.rottonFreshView.image = [UIImage imageNamed:@"rotten"];
    }
    
    NSString *url = [movie valueForKeyPath:@"posters.thumbnail"];
    url = [url stringByReplacingOccurrencesOfString:@"tmb" withString:@"ori"];
    cell.posterView.image = nil;
    [cell.posterView setImageWithURL:[NSURL URLWithString:url]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MovieDetailViewController *vc = [[MovieDetailViewController alloc] init];
    if (self.searchBarActive) {
        vc.movie = self.filteredMovies[indexPath.row];
    } else {
        vc.movie = self.movies[indexPath.row];
    }
    
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Network methods
- (void)showNetworkError {
    CGRect viewRect = CGRectMake(0, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height, [UIScreen mainScreen].bounds.size.width, 44);
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
    NSURL *url = [NSURL URLWithString:@"http://api.rottentomatoes.com/api/public/v1.0/lists/movies/box_office.json?apikey=7gc6v2tkga4wsbsq5qfk7kyd&limit=30"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (data == nil) {
            // show network error
            [self showNetworkError];
        } else {
            [self hideNetworkError];
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
           // NSLog(@"response: %@", responseDictionary);
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
