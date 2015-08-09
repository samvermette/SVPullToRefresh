//
//  SVDemoPullToRefresh.m
//  SVPullToRefreshDemo
//
//  Created by Marian Paul on 23/04/2014.
//  Copyright (c) 2014 Home. All rights reserved.
//

#import "SVDemoPullToRefresh.h"

const static CGFloat kDeltaScaleForPullToRefresh = 0.2f;

@implementation SVDemoPullToRefresh
{
    UIView *_circleView;
    UIActivityIndicatorView *_activity;
    BOOL _triggered;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _circleView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 20.0f, 20.0f)];
        
        UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect:_circleView.bounds];
        CAShapeLayer *plane = [CAShapeLayer layer];
        plane.fillColor = [UIColor redColor].CGColor;
        plane.path = ovalPath.CGPath;
        plane.frame = _circleView.bounds;
        plane.anchorPoint = CGPointMake(0.5, 0.5);
        plane.anchorPointZ = 0.5;
        
        [_circleView.layer addSublayer:plane];
        
        [self addSubview:_circleView];
        
        _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [_activity setHidesWhenStopped:YES];
        [self addSubview:_activity];
    }
    return self;
}

- (void)handleNewState:(SVPullToRefreshState)state
{
    switch (state) {
        case SVPullToRefreshStateStopped:
            [_activity stopAnimating];
            _circleView.hidden = NO;
            break;
        case SVPullToRefreshStateTriggered:
            
            break;
        case SVPullToRefreshStateLoading:
        {
            if (!_triggered) {
                _triggered = YES;
                CGFloat duration = 0.6f;
                
                [UIView animateWithDuration:duration
                                 animations:^{
                                     _circleView.center = CGPointMake(CGRectGetWidth(self.frame)/2.0f, CGRectGetHeight(self.frame) / 2.0f);
                                     _circleView.transform = CGAffineTransformIdentity;
                                 }
                                 completion:^(BOOL finished) {
                                     if (finished && self.state == SVPullToRefreshStateLoading)
                                     {
                                         [_activity setCenter:_circleView.center];
                                         [_activity startAnimating];
                                         _circleView.hidden = YES;
                                     }
                                 }];
            }
            
        }
            break;
        case SVPullToRefreshStateAll:
            
            break;
        default:
            break;
    }
}

- (void) updateForPercentage:(CGFloat)percentage
{
    percentage = MAX(0.0f, percentage);
    
    if (percentage == 0.0f) _triggered = NO;
    
    if (_triggered) return;
    
    CGFloat deltaScale = percentage * kDeltaScaleForPullToRefresh + 1.0f;
    
    [_circleView setTransform:CGAffineTransformMakeScale(deltaScale, deltaScale)];
    _circleView.center = CGPointMake(CGRectGetWidth(self.frame)/2.0f, CGRectGetHeight(self.frame) * (1.0f - percentage*0.3f) - 13.0f);
    _activity.center = _circleView.center;
}

@end
