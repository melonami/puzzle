//
//  ViewController.m
//  slider
//
//  Created by sj on 2017/7/26.
//  Copyright © 2017年 sj. All rights reserved.
//

#import "ViewController.h"
#import "TTGPuzzleVerifyView.h"

@interface ViewController ()<TTGPuzzleVerifyViewDelegate>
@property (strong, nonatomic) TTGPuzzleVerifyView *puzzleVerifyView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setFrame:[[UIScreen mainScreen] bounds]];
    _puzzleVerifyView = [[TTGPuzzleVerifyView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width-50, 300)];
    _puzzleVerifyView.image = [UIImage imageNamed:@"pintu"];
//    _puzzleVerifyView.puzzleBlankPosition = CGPointMake(arc4random()%100*2, 40);
//    _puzzleVerifyView.puzzlePosition = CGPointMake(0, 40);
//    _puzzleVerifyView.puzzleXPercentage = 0.1;
    _puzzleVerifyView.delegate = self;
    
    [self.view addSubview:_puzzleVerifyView];
    // Do any additional setup after loading the view, typically from a nib.
    
}
- (void)puzzleVerifyView:(TTGPuzzleVerifyView *)puzzleVerifyView didChangedVerification:(BOOL)isVerified {
    if ([_puzzleVerifyView isVerified]) {
        [_puzzleVerifyView completeVerificationWithAnimation:YES];
        _puzzleVerifyView.enable = NO;
        NSLog(@"Verify done !");
//        _puzzleVerifyView.enable = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
