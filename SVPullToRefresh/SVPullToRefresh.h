//
// SVPullToRefresh.h
//
// Created by Sam Vermette on 23.04.12.
// Copyright (c) 2012 samvermette.com. All rights reserved.
//
// https://github.com/samvermette/SVPullToRefresh
//

#import <UIKit/UIKit.h>

@interface SVPullToRefresh : UIView
{
    BOOL loading;
}

@property (nonatomic, strong) UIColor *arrowColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, readwrite) UIActivityIndicatorViewStyle activityIndicatorViewStyle;
@property (nonatomic, strong) NSDate *lastUpdatedDate;

- (void)stopAnimating;

@end


// extends UIScrollView

@interface UIScrollView (SVPullToRefresh)

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler showAtInitialLoading:(BOOL)showAtInitialLoading;

@property (nonatomic, strong) SVPullToRefresh *pullToRefreshView;

@end