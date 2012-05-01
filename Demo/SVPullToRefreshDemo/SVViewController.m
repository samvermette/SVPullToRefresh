//
//  SVViewController.m
//  SVPullToRefreshDemo
//
//  Created by Sam Vermette on 23.04.12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "SVViewController.h"
#import "SVPullToRefresh.h"

@interface SVViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation SVViewController

@synthesize tableView = _tableView;
@synthesize sectionDisplayLimit = _sectionDisplayLimit;
@synthesize rowDisplayLimit = _rowDisplayLimit;
@synthesize sectionLimitsLoaded = _sectionLimitsLoaded;
@synthesize rowLimitsLoaded = _rowLimitsLoaded;
@synthesize spinner = _spinner;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView addPullToRefreshWithActionHandler:^{
        NSLog(@"refresh dataSource");
        [_tableView.pullToRefreshView performSelector:@selector(stopAnimating) withObject:nil afterDelay:2];
    }];
    
    self.sectionDisplayLimit = 6;
    self.sectionLimitsLoaded = 1;
}

- (void)loadNextPortion {
    if (self.sectionDisplayLimit > 1) {
        self.sectionLimitsLoaded++;
    }
    else {
        self.rowLimitsLoaded++;
    }
    [_tableView reloadData];
    
    [self.spinner stopAnimating];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _sectionDisplayLimit * _sectionLimitsLoaded;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    
    if (indexPath.section == (_sectionDisplayLimit * _sectionLimitsLoaded) - 1 && indexPath.row == 3 && [[tableView indexPathsForVisibleRows] containsObject:indexPath]) {
        if (!self.spinner) {
            self.spinner = [[UIActivityIndicatorView alloc] 
                            initWithFrame:CGRectMake((cell.contentView.frame.size.width / 2) - 10, 
                                                     cell.contentView.frame.size.height - 10, 
                                                     20, 
                                                     20)];
            self.spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
            self.spinner.hidesWhenStopped = YES;
        }
        [cell.contentView addSubview:self.spinner];
        [self.spinner startAnimating];
        [self performSelector:@selector(loadNextPortion) withObject:nil afterDelay:2.0];
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	return [NSString stringWithFormat:@"Section %i", section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == (_sectionDisplayLimit * _sectionLimitsLoaded) - 1) {
        if (indexPath.row == 3) {
            return 45;
        }
    }
    return 25;
}

@end
