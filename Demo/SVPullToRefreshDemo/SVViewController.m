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
@synthesize tableView = tableView;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // setup the pull-to-refresh view
    [self.tableView addPullToRefreshWithActionHandler:^{
        NSLog(@"refresh dataSource");
        if (tableView.pullToRefreshView.state == SVPullToRefreshStateLoading)
            NSLog(@"Pull to refresh is loading");
        [tableView.pullToRefreshView performSelector:@selector(stopAnimating) withObject:nil afterDelay:2];
    }];
    
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        NSLog(@"load more data");
    }];
    
    if (tableView.pullToRefreshView.state == SVPullToRefreshStateHidden)
        NSLog(@"Pull to refresh is hidden");

    // trigger the refresh manually at the end of viewDidLoad
    [tableView.pullToRefreshView triggerRefresh];
    
    // you can also display the "last updated" date
    // tableView.pullToRefreshView.lastUpdatedDate = [NSDate date];
    
    // you can configure how that date is displayed
    // NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    // dateFormatter.dateStyle = NSDateFormatterLongStyle;
    // dateFormatter.timeStyle = NSDateFormatterNoStyle;
    // tableView.pullToRefreshView.dateFormatter = dateFormatter;
    
    // you can temporarily toggle the pull to refresh view
    // tableView.showsPullToRefresh = NO;
    
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 10;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [NSString stringWithFormat:@"Section %d", section];
}

@end
