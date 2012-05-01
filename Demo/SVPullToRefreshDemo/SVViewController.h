//
//  SVViewController.h
//  SVPullToRefreshDemo
//
//  Created by Sam Vermette on 23.04.12.
//  Copyright (c) 2012 samvermette.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SVViewController : UIViewController

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic) NSInteger sectionDisplayLimit;
@property (nonatomic) NSInteger sectionLimitsLoaded;
@property (nonatomic) NSInteger rowDisplayLimit;
@property (nonatomic) NSInteger rowLimitsLoaded;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end
