//
//  UIScrollView+SVPullToRefresh_CustomView.h
//  SVPullToRefreshDemo
//
//  Created by jack on 13-10-29.
//  Copyright (c) 2013年 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SVPullToRefreshView;

@interface UIScrollView (SVPullToRefresh_CustomView)
- (void)setPullToRefreshCustomViewWith:(SVPullToRefreshView*)pullToRefreshView;
@end
