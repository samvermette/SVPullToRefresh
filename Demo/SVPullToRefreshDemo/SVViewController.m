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
    
    // setup the pull-to-refresh view
    [self.tableView addPullToRefreshWithActionHandler:^{
        NSLog(@"refresh dataSource");
		tableView.pullToRefreshView.lastUpdatedDate = [NSDate date];
        [tableView.pullToRefreshView performSelector:@selector(stopAnimating) withObject:nil afterDelay:2];
    }];
	
	// configure a custom date formatter
	NSDateFormatter *outaTime = [[NSDateFormatter alloc] init];
	outaTime.dateStyle = NSDateFormatterLongStyle;
	outaTime.timeStyle = NSDateFormatterNoStyle;
	tableView.pullToRefreshView.lastUpdatedDateFormatter = outaTime;
    
    // trigger the refresh manually at the end of viewDidLoad
    [tableView.pullToRefreshView triggerRefresh];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];

    return cell;
}

@end
