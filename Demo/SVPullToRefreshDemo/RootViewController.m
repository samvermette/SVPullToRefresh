//
//  RootViewController.m
//  SVPullToRefreshDemo
//
//  Created by Christopher Pickslay on 4/24/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "RootViewController.h"
#import "SVViewController.h"

@interface RootViewController ()

@end

@implementation RootViewController

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

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)didTapLaunch:(id)sender {
    SVViewController *viewController = [[SVViewController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
