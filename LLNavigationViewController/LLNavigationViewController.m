//
//  ViewController.m
//  LLNavigationViewController
//
//  Created by Nick Luo on 11/04/2014.
//  Copyright (c) 2014 Nick Luo. All rights reserved.
//

#import "LLNavigationViewController.h"
#import "TestViewController.h"

#define TRANSITION_TIME 0.4f

@interface LLNavigationViewController () <UINavigationBarDelegate>

@property (strong, nonatomic, readwrite) UIViewController *currentContentViewController;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (nonatomic) BOOL transitionInProgress;

@end

@implementation LLNavigationViewController

@synthesize currentContentViewController = _currentContentViewController, containerView = _containerView, transitionInProgress = _transitionInProgress;


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationBar.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self pushViewController:viewController animated:animated completion:nil];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)())completion
{
    [self addChildViewController:viewController];
    
    _transitionInProgress = YES;
    // the off-screen rect where we transition from
    CGRect offScreen = self.containerView.bounds;
    
    offScreen.origin.x += offScreen.size.width;
    viewController.view.frame = offScreen;
    
    
    // Disable the current view controller interaction to prevent user click multiple times of the cell and consequently trigger the push view controler multiple times
    self.currentContentViewController.view.userInteractionEnabled = NO;
    // transition to the new view controller
    
    [self.navigationBar pushNavigationItem:viewController.navigationItem animated:YES];
    
    [self
     transitionFromViewController:self.currentContentViewController
     toViewController:viewController
     duration:TRANSITION_TIME
     options:UIViewAnimationOptionCurveEaseOut
     animations:^{
         
         viewController.view.frame = self.containerView.bounds;
     }
     completion:^(BOOL finished) {
         
         // enable the interaction again
         self.currentContentViewController.view.userInteractionEnabled = YES;
         
         self.currentContentViewController = viewController;
         //[self configureBackButton];
         [viewController didMoveToParentViewController:self];
         
         _transitionInProgress = NO;
        
     }
     ];
}
- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    return [self popViewControllerAnimated:animated withCompletion:nil];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated withCompletion:(void(^)())completion
{
    if (self.childViewControllers.count == 1) {
        return nil;
    }
    
    _transitionInProgress = YES;
    
    UIViewController *currentViewController = self.currentContentViewController;
    UIViewController *toViewController = [self.childViewControllers objectAtIndex:(self.childViewControllers.count-2)];
    
    [self.view bringSubviewToFront:currentViewController.view];
    
    CGRect currentViewControllerSlideBackFrame = CGRectOffset(currentViewController.view.frame, CGRectGetWidth(self.view.frame), 0);
    CGRect toViewControllerInitialFrame = CGRectOffset(currentViewController.view.frame, -CGRectGetWidth(self.view.frame), 0);
    
    [toViewController willMoveToParentViewController:self];
    
    toViewController.view.frame = toViewControllerInitialFrame;
    
    [self.containerView insertSubview:toViewController.view belowSubview:currentViewController.view];
    
    NSTimeInterval animTime = animated ? TRANSITION_TIME : 0;
    
    [UIView animateWithDuration:animTime animations:^(void){
        currentViewController.view.frame = currentViewControllerSlideBackFrame;
        toViewController.view.frame = self.containerView.bounds;
        
        
    } completion:^(BOOL finished) {
        
        [currentViewController removeFromParentViewController];
        [currentViewController.view removeFromSuperview];
        self.currentContentViewController = toViewController;

        [toViewController didMoveToParentViewController:self];
        if (completion) completion();

        _transitionInProgress = NO;
        
    }];
    
    return toViewController;
}

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    NSMutableArray *popViewControllers = [NSMutableArray array];
    
    if ([self.childViewControllers indexOfObject:viewController]!=NSNotFound) {
        UIViewController *tmp = [self popViewControllerAnimated:animated];
        [popViewControllers addObject:tmp];
        while(![tmp isEqual:viewController]) {
            tmp = [self popViewControllerAnimated:animated];
            [popViewControllers addObject:tmp];
        }
    }
    return popViewControllers;
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated
{
    
    // if only 1 controller left we return nil
    if ([self.childViewControllers count] == 1) {
        return nil;
    }
    
    _transitionInProgress = YES;
    // Create the view controllers that will be returned in this method
    NSArray *viewControllers = [[NSMutableArray alloc] init];
    viewControllers = [self.childViewControllers objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, self.childViewControllers.count-1)]];
    
    
    UIViewController *rootViewController = [self.childViewControllers objectAtIndex:0];
    UIViewController *currentViewController = [self.childViewControllers lastObject];
    
    
    rootViewController.view.frame = CGRectMake(self.view.bounds.size.width,0,self.view.bounds.size.width,self.view.bounds.size.height);
    
    [currentViewController willMoveToParentViewController:nil];
    
    NSTimeInterval duration = animated ? TRANSITION_TIME : 0.f;
    
    [self popToRootNavigationItem];
    
    [self transitionFromViewController:currentViewController
                      toViewController:rootViewController
                              duration:duration
                               options:0
                            animations:^{
                                rootViewController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
                            }
                            completion:^(BOOL finished) {
                                [currentViewController removeFromParentViewController];
                                [currentViewController.view removeFromSuperview];
                                
                                while (self.childViewControllers.count > 1) {
                                    UIViewController *tmp = [self.childViewControllers lastObject];
                                    [tmp willMoveToParentViewController:nil];
                                    [tmp removeFromParentViewController];
                                }
                                
                                NSLog(@"the child VCs are %@",self.childViewControllers);
                               
                                self.currentContentViewController = rootViewController;
                                
                                [rootViewController didMoveToParentViewController:self];
                                _transitionInProgress = NO;
                            }];
    
    
    return viewControllers;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self setRootViewController:segue.destinationViewController];
}

- (void)setRootViewController: (UIViewController *)rootViewController
{
    [self addChildViewController:rootViewController];
    [rootViewController didMoveToParentViewController:self];
    self.currentContentViewController = rootViewController;
    
    self.navigationItem.title = rootViewController.title;
}


- (void)popToRootNavigationItem
{
    NSArray *navigationItems = self.navigationBar.items;
    
    if (navigationItems.count == 1) {
        return;
    }
    
    if (navigationItems.count == 2) {
        [self.navigationBar popNavigationItemAnimated:YES];
    } else {
        [self.navigationBar popNavigationItemAnimated:NO];
    }

    [self popToRootNavigationItem];
}

#pragma mark UINavigationBar Delegate

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPushItem:(UINavigationItem *)item
{
    return YES;
}
- (void)navigationBar:(UINavigationBar *)navigationBar didPushItem:(UINavigationItem *)item
{
    
}
- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
    if (!_transitionInProgress) {
        [self popViewControllerAnimated:YES];
    }
    
    return YES;
}
- (void)navigationBar:(UINavigationBar *)navigationBar didPopItem:(UINavigationItem *)item
{
    
}

@end