//
//  RKSwipeBetweenViewControllers.m
//  RKSwipeBetweenViewControllers
//
//  Created by Richard Kim on 7/24/14.
//  Copyright (c) 2014 Richard Kim. All rights reserved.
//
//  @cwRichardKim for regular updates

#import "RKSwipeBetweenViewControllers.h"

//%%% customizeable button attributes
CGFloat X_BUFFER = 0.0; //%%% the number of pixels on either side of the segment
CGFloat Y_BUFFER = 10.0; //%%% number of pixels on top of the segment
CGFloat HEIGHT = 30.0; //%%% height of the segment

//%%% customizeable selector bar attributes (the black bar under the buttons)
CGFloat BOUNCE_BUFFER = 10.0; //%%% adds bounce to the selection bar when you scroll
CGFloat ANIMATION_SPEED = 0.2; //%%% the number of seconds it takes to complete the animation
CGFloat SELECTOR_Y_BUFFER = 42.0; //%%% the y-value of the bar that shows what page you are on (0 is the top)
CGFloat SELECTOR_HEIGHT = 2.0; //%%% thickness of the selector bar

CGFloat X_OFFSET = 0.0; //%%% for some reason there's a little bit of a glitchy offset.  I'm going to look for a better workaround in the future

#define RK_COLOR_MAIN [UIColor colorWithRed:0.42 green:0.47 blue:0.79 alpha:1]
#define FONT_SIZE_16 16

//单行文本size
#define MB_TEXTSIZE(text, font) [text length] > 0 ? [text \
sizeWithAttributes:@{NSFontAttributeName:font}] : CGSizeZero;
//多行文本size
#define MULTILINE_TEXTSIZE(text, font, maxSize, mode) [text length] > 0 ? [text \
boundingRectWithSize:maxSize options:(NSStringDrawingUsesLineFragmentOrigin) \
attributes:@{NSFontAttributeName:font} context:nil].size : CGSizeZero;
@interface RKSwipeBetweenViewControllers ()

@property (nonatomic) UIScrollView *pageScrollView;
@property (nonatomic) NSInteger currentPageIndex;
@property (nonatomic) BOOL isPageScrollingFlag; //%%% prevents scrolling / segment tap crash
@property (nonatomic) BOOL hasAppearedFlag; //%%% prevents reloading (maintains state)

@property(nonatomic,assign)CGFloat titleContainerWidth;
@property(nonatomic,assign)CGFloat titleWidth;
@end

@implementation RKSwipeBetweenViewControllers
@synthesize viewControllerArray;
@synthesize selectionBar;
@synthesize pageController;
@synthesize navigationView;

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

    //self.navigationBar.barTintColor = [UIColor colorWithRed:0.01 green:0.05 blue:0.06 alpha:1]; //%%% bartint
    //self.navigationBar.translucent = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    viewControllerArray = [[NSMutableArray alloc]init];
    self.currentPageIndex = 0;
    self.isPageScrollingFlag = NO;
    self.hasAppearedFlag = NO;
    
    /**
     *  titleview的宽度 和 每个标题的宽
     */
    self.titleContainerWidth = 200;
}

#pragma mark Customizables

//%%% color of the status bar
-(UIStatusBarStyle)preferredStatusBarStyle {
   // return UIStatusBarStyleLightContent;
    return UIStatusBarStyleDefault;
}

//%%% sets up the tabs using a loop.  You can take apart the loop to customize individual buttons, but remember to tag the buttons.  (button.tag=0 and the second button.tag=1, etc)
-(void)setupSegmentButtons {
    
    navigationView = [[UIView alloc]initWithFrame:CGRectMake(0,0,_titleContainerWidth,self.navigationBar.frame.size.height)];
    
    NSInteger numControllers = [viewControllerArray count];
    
    if (!_buttonText) {
         _buttonText = [[NSArray alloc]initWithObjects: @"first",@"second",@"third",@"fourth",@"etc",@"etc",@"etc",@"etc",nil]; //%%%buttontitle
    }
    
    for (int i = 0; i<numControllers; i++) {
        UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(X_BUFFER+i*(_titleContainerWidth-2*X_BUFFER)/numControllers-X_OFFSET, Y_BUFFER, (_titleContainerWidth-2*X_BUFFER)/numControllers, HEIGHT)];
        [navigationView addSubview:button];
        
        button.tag = i; //%%% IMPORTANT: if you make your own custom buttons, you have to tag them appropriately
        //button.backgroundColor = [UIColor colorWithRed:0.03 green:0.07 blue:0.08 alpha:1];//%%% buttoncolors
        
        [button addTarget:self action:@selector(tapSegmentButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        [button setTitle:[_buttonText objectAtIndex:i] forState:UIControlStateNormal]; //%%%buttontitle
        [button setTitleColor:RK_COLOR_MAIN forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont systemFontOfSize:FONT_SIZE_16]];
    }
    
    pageController.navigationController.navigationBar.topItem.titleView = navigationView;
    
    //%%% example custom buttons example:
    /*
    NSInteger width = (self.view.frame.size.width-(2*X_BUFFER))/3;
    UIButton *leftButton = [[UIButton alloc]initWithFrame:CGRectMake(X_BUFFER, Y_BUFFER, width, HEIGHT)];
    UIButton *middleButton = [[UIButton alloc]initWithFrame:CGRectMake(X_BUFFER+width, Y_BUFFER, width, HEIGHT)];
    UIButton *rightButton = [[UIButton alloc]initWithFrame:CGRectMake(X_BUFFER+2*width, Y_BUFFER, width, HEIGHT)];
    
    [self.navigationBar addSubview:leftButton];
    [self.navigationBar addSubview:middleButton];
    [self.navigationBar addSubview:rightButton];
    
    leftButton.tag = 0;
    middleButton.tag = 1;
    rightButton.tag = 2;
    
    leftButton.backgroundColor = [UIColor colorWithRed:0.03 green:0.07 blue:0.08 alpha:1];
    middleButton.backgroundColor = [UIColor colorWithRed:0.03 green:0.07 blue:0.08 alpha:1];
    rightButton.backgroundColor = [UIColor colorWithRed:0.03 green:0.07 blue:0.08 alpha:1];
    
    [leftButton addTarget:self action:@selector(tapSegmentButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [middleButton addTarget:self action:@selector(tapSegmentButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [rightButton addTarget:self action:@selector(tapSegmentButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [leftButton setTitle:@"left" forState:UIControlStateNormal];
    [middleButton setTitle:@"middle" forState:UIControlStateNormal];
    [rightButton setTitle:@"right" forState:UIControlStateNormal];
     */
    
    [self setupSelector];
}


//%%% sets up the selection bar under the buttons on the navigation bar
-(void)setupSelector {
    UIButton *curBtn = [[navigationView subviews] objectAtIndex:self.currentPageIndex];
    CGSize sizeOrigin = MB_TEXTSIZE(curBtn.currentTitle, [UIFont systemFontOfSize:FONT_SIZE_16]);
    CGFloat selectionBarWidth = sizeOrigin.width;//(_titleContainerWidth-2*X_BUFFER)/[viewControllerArray count](等宽)
    
    selectionBar = [[UIView alloc]initWithFrame:CGRectMake(X_BUFFER-X_OFFSET, SELECTOR_Y_BUFFER,selectionBarWidth, SELECTOR_HEIGHT)];
    selectionBar.backgroundColor = RK_COLOR_MAIN; //%%% sbcolor
    selectionBar.alpha = 0.8; //%%% sbalpha
    [navigationView addSubview:selectionBar];
}


//generally, this shouldn't be changed unless you know what you're changing
#pragma mark Setup

-(void)viewWillAppear:(BOOL)animated {
    if (!self.hasAppearedFlag) {
        [self setupPageViewController];
        [self setupSegmentButtons];
        self.hasAppearedFlag = YES;
    }
}

//%%% generic setup stuff for a pageview controller.  Sets up the scrolling style and delegate for the controller
-(void)setupPageViewController {
    pageController = (UIPageViewController*)self.topViewController;
    pageController.delegate = self;
    pageController.dataSource = self;
    [pageController setViewControllers:@[[viewControllerArray objectAtIndex:0]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    [self syncScrollView];
}

//%%% this allows us to get information back from the scrollview, namely the coordinate information that we can link to the selection bar.
-(void)syncScrollView {
    for (UIView* view in pageController.view.subviews){
        if([view isKindOfClass:[UIScrollView class]]) {
            self.pageScrollView = (UIScrollView *)view;
            self.pageScrollView.delegate = self;
        }
    }
}

//%%% methods called when you tap a button or scroll through the pages
// generally shouldn't touch this unless you know what you're doing or
// have a particular performance thing in mind

#pragma mark Movement

//%%% when you tap one of the buttons, it shows that page,
//but it also has to animate the other pages to make it feel like you're crossing a 2d expansion,
//so there's a loop that shows every view controller in the array up to the one you selected
//eg: if you're on page 1 and you click tab 3, then it shows you page 2 and then page 3
-(void)tapSegmentButtonAction:(UIButton *)button {
    
    if (!self.isPageScrollingFlag) {
        
        NSInteger tempIndex = self.currentPageIndex;
        
        __weak typeof(self) weakSelf = self;
        
        //%%% check to see if you're going left -> right or right -> left
        if (button.tag > tempIndex) {
            
            //%%% scroll through all the objects between the two points
            for (int i = (int)tempIndex+1; i<=button.tag; i++) {
                [pageController setViewControllers:@[[viewControllerArray objectAtIndex:i]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL complete){
                    
                    //%%% if the action finishes scrolling (i.e. the user doesn't stop it in the middle),
                    //then it updates the page that it's currently on
                    if (complete) {
                        [weakSelf updateCurrentPageIndex:i];
                    }
                }];
            }
        }
        
        //%%% this is the same thing but for going right -> left
        else if (button.tag < tempIndex) {
            for (int i = (int)tempIndex-1; i >= button.tag; i--) {
                [pageController setViewControllers:@[[viewControllerArray objectAtIndex:i]] direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:^(BOOL complete){
                    if (complete) {
                        [weakSelf updateCurrentPageIndex:i];
                    }
                }];
            }
        }
    }
}

//%%% makes sure the nav bar is always aware of what page you're on
//in reference to the array of view controllers you gave
-(void)updateCurrentPageIndex:(int)newIndex {
    self.currentPageIndex = newIndex;
}

//%%% method is called when any of the pages moves.
//It extracts the xcoordinate from the center point and instructs the selection bar to move accordingly
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    NSLog(@"Offset.x:%f",scrollView.contentOffset.x);
    NSLog(@"PAGE:%ld",(long)self.currentPageIndex);

    CGFloat percentX = (scrollView.contentOffset.x - CGRectGetWidth(scrollView.frame)) / CGRectGetWidth(scrollView.frame);//往左滑动大于0，往右小于0(由于默认偏移320)
    NSLog(@"percentX:%f",percentX);
    
    NSInteger currentPageIndex = self.currentPageIndex;

    UIButton *curBtn = [[navigationView subviews] objectAtIndex:currentPageIndex];

    NSInteger targetPage = percentX > 0 ? currentPageIndex+1:currentPageIndex-1;
    if (targetPage >= 0 && targetPage < _buttonText.count)
    {
        UIButton *targetBtn = [[navigationView subviews] objectAtIndex:targetPage];
        
        CGSize sizeOrigin = MB_TEXTSIZE(curBtn.currentTitle, [UIFont systemFontOfSize:FONT_SIZE_16]);
        CGFloat lengthOrigin = sizeOrigin.width;
        
        CGSize sizeTarget = MB_TEXTSIZE(targetBtn.currentTitle, [UIFont systemFontOfSize:FONT_SIZE_16]);
        CGFloat lengthTarget = sizeTarget.width;
        
        CGFloat selctionBarLength = lengthTarget + (lengthOrigin - lengthTarget)*(1-ABS(percentX));
        selectionBar.frame = CGRectMake(selectionBar.frame.origin.x, selectionBar.frame.origin.y, selctionBarLength, selectionBar.frame.size.height);
    }

    
    
    CGFloat centerxOfSelectionBar = curBtn.center.x + percentX*_titleWidth;
    selectionBar.center = CGPointMake(centerxOfSelectionBar, selectionBar.center.y);
}



//%%% the delegate functions for UIPageViewController.
//Pretty standard, but generally, don't touch this.
#pragma mark UIPageViewController Delegate Functions

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSInteger index = [viewControllerArray indexOfObject:viewController];

    if ((index == NSNotFound) || (index == 0)) {
        return nil;
    }
    
    index--;
    return [viewControllerArray objectAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSInteger index = [viewControllerArray indexOfObject:viewController];

    if (index == NSNotFound) {
        return nil;
    }
    index++;
    
    if (index == [viewControllerArray count]) {
        return nil;
    }
    return [viewControllerArray objectAtIndex:index];
}

-(void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (completed) {
        self.currentPageIndex = [viewControllerArray indexOfObject:[pageViewController.viewControllers lastObject]];
    }
}

#pragma mark - Scroll View Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.isPageScrollingFlag = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.isPageScrollingFlag = NO;
}


- (void)setButtonText:(NSArray *)buttonText
{
    _buttonText = buttonText;
    self.titleWidth = self.titleContainerWidth/_buttonText.count;
}
@end
