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

@synthesize tableView;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView addPullToRefreshWithTarget:self action:@selector(loadData)];    
    // that's it!
}

- (void)loadData {
    [self performSelector:@selector(doneLoading) withObject:nil afterDelay:5];
}

- (void)doneLoading {
    [tableView.pullToRefreshView stopAnimating];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 10;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	return [NSString stringWithFormat:@"Section %i", section];
}

@end
