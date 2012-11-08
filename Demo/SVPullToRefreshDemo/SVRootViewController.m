//
//  SVRootViewController.m
//  SVPullToRefreshDemo
//
//  Created by fengjian on 12-10-31.
//  Copyright (c) 2012年 Home. All rights reserved.
//

#import "SVRootViewController.h"
#import "SVViewController.h"

@interface SVRootViewController ()

@end

@implementation SVRootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showTableView:(id)sender
{
    [self.navigationController pushViewController:[[SVViewController alloc] initWithNibName:@"SVViewController" bundle:nil] animated:YES];
}
@end
