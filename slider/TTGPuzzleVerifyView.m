//
//  TTGPuzzleVerifyView.m
//  Pods
//
//  Created by tutuge on 2016/12/10.
//
//

#import "TTGPuzzleVerifyView.h"
#import "TTGPuzzleVerifyView+PatternPathProvider.h"

static CGSize kTTGPuzzleDefaultSize;
static CGFloat kTTGPuzzleAnimationDuration = 1;

@interface TTGPuzzleVerifyView ()
@property (nonatomic, strong) UIImageView *backImageView;
@property (nonatomic, strong) CAShapeLayer *backInnerShadowLayer;

@property (nonatomic, strong) UIImageView *frontImageView;

@property (nonatomic, strong) UIImageView *puzzleImageView;
@property (nonatomic, strong) UIView *puzzleImageContainerView;
@property (nonatomic, assign) CGPoint puzzleContainerPosition;
@property (nonatomic, assign) CGPoint puzzleContainerPositionSet;
@property (nonatomic, assign) CGRect initRect;

@property (nonatomic, assign) BOOL lastVerification;
@end

@implementation TTGPuzzleVerifyView

#pragma mark - Init
#define sliderheight 38
- (instancetype)initWithFrame:(CGRect)frame {
    _initRect =frame;
    self = [super initWithFrame:_initRect];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

//同步slider 和 拼图的位置
-(void)sliderValueChanged:(id)slider{
    
    self.puzzleXPercentage = ((UISlider *)slider).value/100;
}

//slider 失去焦点的时候，判断拼图位置
-(void)sliderLostFocus:(id)slider{
    
    if (_lastVerification != [self isVerified]) {
        _lastVerification = [self isVerified];
        
        // Delegate
        if ([_delegate respondsToSelector:@selector(puzzleVerifyView:didChangedVerification:)]) {
            [_delegate puzzleVerifyView:self didChangedVerification:[self isVerified]];
            [self.slider setValue:0];
            self.puzzleXPercentage = 0;
        }
        
        // Block
        if (_verificationChangeBlock) {
            _verificationChangeBlock(self, [self isVerified]);
        }
        
        return;
    }
    [self updateBlackPuzzlePosition];
    [self.slider setValue:0];
    self.puzzleBlankAlpha = 0.5;
    self.puzzleShadowOpacity = 0.5;
    self.puzzlePosition = CGPointMake([self findThePuzzleFrame].origin.x,self.puzzlePosition.y);
//    self.puzzleXPercentage = 0+[self findThePuzzleFrame].origin.x;
}

-(UIImage *)OriginImage:(UIImage *)image scaleToSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0,0, size.width, size.height)];
    UIImage *scaleImage=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaleImage;
}

//frame.x为宽，frame.y为高
-(CGRect)findThePuzzleFrame{
    CGPoint frame = CGPointMake(self.frame.size.width, self.frame.size.height-sliderheight);
    if(frame.x*5/8.0<frame.y){
        return CGRectMake((self.frame.size.width-frame.x)/2.0, (self.frame.size.height-sliderheight-frame.x*5/8.0)/2.0, frame.x, frame.x*5/8.0);
    }
    return CGRectMake((self.frame.size.width-frame.y*8.0/5.0)/2.0, (self.frame.size.height-sliderheight-frame.y)/2.0, frame.y*8.0/5.0, frame.y);
}


- (void)commonInit {
    if (_backImageView) {
        return;
    }

    
    self.userInteractionEnabled = YES;
    self.clipsToBounds = YES;

    // Init value
    kTTGPuzzleDefaultSize = CGSizeMake(100, 100);
    self.enable = YES;
    self.puzzlePattern = TTGPuzzleVerifyClassicPattern;
    self.customPuzzlePatternPath = [self getNewScaledPuzzledPath];
    self.puzzleSize = kTTGPuzzleDefaultSize;
    self.puzzlePosition = CGPointMake([self findThePuzzleFrame].origin.x,[self findThePuzzleFrame].origin.y+40);
    
    self.puzzleBlankPosition = CGPointZero;
    self.verificationTolerance = 8;
    
    self.puzzleBlankAlpha = 0.5;
    self.puzzleBlankInnerShadowColor = [UIColor blackColor];
    self.puzzleBlankInnerShadowRadius = 4;
    self.puzzleBlankInnerShadowOpacity = 0.5;
    self.puzzleBlankInnerShadowOffset = CGSizeZero;

    self.puzzleShadowColor = [UIColor blackColor];
    self.puzzleShadowRadius = 4;
    self.puzzleShadowOpacity = 0.5;
    self.puzzleShadowOffset = CGSizeZero;

    // Back puzzle blank image view
    CGRect rect = [self findThePuzzleFrame];
    
    _slider = [[UISlider alloc] initWithFrame:CGRectMake(rect.origin.x,self.bounds.size.height-sliderheight, rect.size.width, sliderheight)];
    _slider.minimumValue = 0;
    _slider.maximumValue = 100;
    [_slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [_slider addTarget:self action:@selector(sliderLostFocus:) forControlEvents:UIControlEventTouchUpInside];
    UIImage *imagea=[self OriginImage:[UIImage imageNamed:@"littlecircle"] scaleToSize:CGSizeMake(30, 30)];
    [_slider setThumbImage:imagea forState:UIControlStateNormal];
    UIImage *imagea2=[self OriginImage:[UIImage imageNamed:@"littlecircle2"] scaleToSize:CGSizeMake(30, 30)];
    [_slider setThumbImage:imagea2 forState:UIControlStateHighlighted];

    [self addSubview:_slider];
    [_slider setValue:0];
    
    
    _backImageView = [[UIImageView alloc] initWithFrame:rect];
    _backImageView.userInteractionEnabled = NO;
    _backImageView.contentMode = UIViewContentModeScaleToFill;
    _backImageView.backgroundColor = [UIColor clearColor];
    _backImageView.alpha = _puzzleBlankAlpha;
    [self addSubview:_backImageView];
    //查看border
//    _backImageView.backgroundColor = [UIColor redColor];
//    [_backImageView.layer setBorderColor:[UIColor purpleColor].CGColor];
//    [_backImageView.layer setBorderWidth:3.0];
    
    // Front puzzle hole image view
    _frontImageView = [[UIImageView alloc] initWithFrame:rect];
    _frontImageView.userInteractionEnabled = NO;
    _frontImageView.contentMode = UIViewContentModeScaleToFill;
    _frontImageView.backgroundColor = [UIColor clearColor];
    [self addSubview:_frontImageView];
//    [_frontImageView.layer setBorderColor:[UIColor greenColor].CGColor];
//    [_frontImageView.layer setBorderWidth:3.0];
    
    _puzzleContainerPositionSet = _puzzleContainerPosition;
    // Puzzle piece container view 指的是拼图
    _puzzleImageContainerView = [[UIView alloc] initWithFrame:CGRectMake(
            _puzzleContainerPosition.x, _puzzleContainerPosition.y,
            CGRectGetWidth(rect), CGRectGetHeight(rect))];
//    [_puzzleImageContainerView.layer setBorderColor:[UIColor redColor].CGColor];
//    [_puzzleImageContainerView.layer setBorderWidth:2.0];
    
    NSLog(@"puzzle %f",_puzzleImageContainerView.frame.origin.x);
    
    _puzzleImageContainerView.backgroundColor = [UIColor clearColor];
    _puzzleImageContainerView.userInteractionEnabled = NO;
    _puzzleImageContainerView.layer.shadowColor = _puzzleShadowColor.CGColor;
    _puzzleImageContainerView.layer.shadowRadius = _puzzleShadowRadius;
    _puzzleImageContainerView.layer.shadowOpacity = _puzzleShadowOpacity;
    _puzzleImageContainerView.layer.shadowOffset = _puzzleShadowOffset;
    [self addSubview:_puzzleImageContainerView];

    // Puzzle piece imageView 拼图块
    _puzzleImageView = [[UIImageView alloc] initWithFrame:_puzzleImageContainerView.bounds];
    _puzzleImageView.userInteractionEnabled = NO;
    _puzzleImageView.contentMode = UIViewContentModeScaleToFill;
    _puzzleImageView.backgroundColor = [UIColor clearColor];
    //查看border
//    _puzzleImageView.backgroundColor = [UIColor whiteColor];
//    [_puzzleImageView.layer setBorderWidth:1.0];
//    [_puzzleImageView.layer setBorderColor:[UIColor grayColor].CGColor];
//    
    
    [_puzzleImageContainerView addSubview:_puzzleImageView];

    // Inner shadow layer 拼图块的阴影，目的：将拼图和背景区分开
    _backInnerShadowLayer = [CAShapeLayer layer];
    _backInnerShadowLayer.frame = rect;
    _backInnerShadowLayer.fillRule = kCAFillRuleEvenOdd;
    _backInnerShadowLayer.shadowColor = _puzzleBlankInnerShadowColor.CGColor;
    _backInnerShadowLayer.shadowRadius = _puzzleBlankInnerShadowRadius;
    _backInnerShadowLayer.shadowOpacity = _puzzleBlankInnerShadowOpacity;
    _backInnerShadowLayer.shadowOffset = _puzzleBlankInnerShadowOffset;


    // Pan gesture 为自身添加动作捕捉，更新拼图缺口的位置
    UITapGestureRecognizer *panGestureRecognizer = [UITapGestureRecognizer new];
    [panGestureRecognizer addTarget:self action:@selector(onPanGesture:)];
    [self addGestureRecognizer:panGestureRecognizer];
    
    [self updateBlackPuzzlePosition];
}

#pragma mark - Public methods
//puzzle blank position 指的是拼图缺口的位置,应该在_puzzlesize.width 到 背景width-_puzzlesize.width之间
-(void)updateBlackPuzzlePosition{
    
    /*我们要获取下图1到2的距离，3到4的距离=5到6的距离=拼图的大小，5到6为拼图初始x偏移也就是0
     *
     *      5---6
     *          3---4
     *          l---------------------------2
     *
     *      l    ___                         ___l
     *      l   l   l                       l   l
     *      l                                   l
     *
     */
    
    int wid = [self findThePuzzleFrame].size.width-_puzzleSize.width*2;
    float rand =arc4random()%wid;
    
    [self setPuzzleBlankPosition: CGPointMake(rand+_puzzleSize.width, 40)];
}

- (void)completeVerificationWithAnimation:(BOOL)withAnimation {
    if (withAnimation) {
        //设置 拼图到拼图缺口的位置
        [UIView animateWithDuration:kTTGPuzzleAnimationDuration animations:^{

            [self setPuzzlePosition:CGPointMake(_puzzleBlankPosition.x,_puzzleBlankPosition.y)];
            _puzzleImageContainerView.layer.shadowOpacity = 0;
        }];
        
    } else {
        [self setPuzzlePosition:CGPointMake(_puzzleBlankPosition.x,_puzzleBlankPosition.y)];
        _puzzleImageContainerView.layer.shadowOpacity = 0;
    }
}

#pragma mark - Pan gesture

- (void)onPanGesture:(UIPanGestureRecognizer *)panGestureRecognizer {
//    CGPoint panLocation = [panGestureRecognizer locationInView:self];
//
//    // New position
//    CGPoint position = CGPointZero;
//    position.x = panLocation.x - _puzzleSize.width / 2;
//    position.y = panLocation.y - _puzzleSize.height / 2;
//
//    // Update position
//    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
//        // Animate move
//        [UIView animateWithDuration:kTTGPuzzleAnimationDuration animations:^{
//            [self setPuzzlePosition:position];
//        }];
//    } else {
//        [self setPuzzlePosition:position];
//    }
//    
//    // Callback
//    [self performCallback];
    
    [self updateBlackPuzzlePosition];
    [self.slider setValue:0];
    self.puzzleBlankAlpha = 0.5;
    self.puzzleShadowOpacity = 0.5;
    self.puzzlePosition = CGPointMake([self findThePuzzleFrame].origin.x,self.puzzlePosition.y);

    
}


#pragma mark - Override

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect rect = [self findThePuzzleFrame];
    _backImageView.frame = rect;
    _frontImageView.frame = rect;
    _puzzleImageContainerView.frame = CGRectMake(
            _puzzleContainerPosition.x, _puzzleContainerPosition.y,
            CGRectGetWidth(rect), CGRectGetHeight(rect));
    _puzzleImageView.frame = _puzzleImageContainerView.bounds;
    self.puzzlePosition = CGPointMake([self findThePuzzleFrame].origin.x,[self findThePuzzleFrame].origin.y+40);
    
    
    [self updatePuzzleMask];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (newSuperview) {
        [self updatePuzzleMask];
    }
}

#pragma mark - Update Mask layer

- (void)updatePuzzleMask {
    if (!self.superview) {
        return;
    }
    //拼图整体的rect
    CGRect rect1 = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height-sliderheight);
    // Paths生成
    UIBezierPath *puzzlePath = [self getNewScaledPuzzledPath];
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRect:rect1];
    [maskPath appendPath:[UIBezierPath bezierPathWithCGPath:puzzlePath.CGPath]];
    maskPath.usesEvenOddFillRule = YES;

    // Layers
    CAShapeLayer *backMaskLayer = [CAShapeLayer new];
    backMaskLayer.frame = rect1;
    backMaskLayer.path = puzzlePath.CGPath;
    backMaskLayer.fillRule = kCAFillRuleEvenOdd;
    
    CAShapeLayer *frontMaskLayer = [CAShapeLayer new];
    frontMaskLayer.frame = rect1;
    frontMaskLayer.path = maskPath.CGPath;
    frontMaskLayer.fillRule = kCAFillRuleEvenOdd;

    CAShapeLayer *puzzleMaskLayer = [CAShapeLayer new];
    puzzleMaskLayer.frame =rect1;
    puzzleMaskLayer.path = puzzlePath.CGPath;

    _backImageView.layer.mask = backMaskLayer;
    _frontImageView.layer.mask = frontMaskLayer;
    _puzzleImageView.layer.mask = puzzleMaskLayer;

    // Puzzle blank inner shadow
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:CGRectInset(rect1, -20, -20)]; // Outer rect
    [shadowPath appendPath:puzzlePath]; // Inner shape

    _backInnerShadowLayer.frame = rect1;
    _backInnerShadowLayer.path = shadowPath.CGPath;
    
    [[_backImageView.layer sublayers] makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [_backImageView.layer addSublayer:_backInnerShadowLayer];
    
    
}

#pragma mark - Callback

- (void)performCallback {
    // Callback for position change
    if ([_delegate respondsToSelector:@selector(puzzleVerifyView:didChangedPuzzlePosition:xPercentage:yPercentage:)]) {
        [_delegate puzzleVerifyView:self didChangedPuzzlePosition:[self puzzlePosition]
                        xPercentage:[self puzzleXPercentage] yPercentage:[self puzzleYPercentage]];
    }
    
    
}

#pragma mark - Setter and getter

- (UIBezierPath *)getNewScaledPuzzledPath {
    UIBezierPath *path = nil;
    
    // Pattern path 缩放
    if (_puzzlePattern == TTGPuzzleVerifyCustomPattern) {
        path = [UIBezierPath bezierPathWithCGPath:_customPuzzlePatternPath.CGPath];
        _puzzleSize = path.bounds.size;
    } else {
        path = [UIBezierPath bezierPathWithCGPath:[TTGPuzzleVerifyView verifyPathForPattern:_puzzlePattern].CGPath];
        // Apply scale transform
        [path applyTransform:CGAffineTransformMakeScale(
                                                        _puzzleSize.width / path.bounds.size.width,
                                                        _puzzleSize.height / path.bounds.size.height)];
    }
    
    // Apply position transform 位置
    //http://www.jianshu.com/p/bb0b1e627baf
    [path applyTransform:CGAffineTransformMakeTranslation(
            _puzzleBlankPosition.x - path.bounds.origin.x,
            _puzzleBlankPosition.y - path.bounds.origin.y)];
    
    return path;
}

// Puzzle position 设置的就是puzzleContainerPosition 也就是puzzleImageContainerView的position

- (void)setPuzzlePosition:(CGPoint)puzzlePosition {
    //
    if (!_enable) {
        return;
    }
    
    // Limit range
    puzzlePosition.x = MAX([self puzzleMinX], puzzlePosition.x);
    puzzlePosition.x = MIN([self puzzleMaxX], puzzlePosition.x);
    
    puzzlePosition.y = MAX([self puzzleMinY], puzzlePosition.y);
    puzzlePosition.y = MIN([self puzzleMaxY], puzzlePosition.y);
    
    // Reset shadow
    _puzzleImageContainerView.layer.shadowOpacity = _puzzleShadowOpacity;
    
    // Set puzzle image container position 由于我们设置container是findThePuzzleFrame大小也就是图片比例适配之后的大小，所以y值是[self findThePuzzleFrame].origin.y，uzzlePosition.x是通过百分值算出来的位置，拼图相对于PuzzleContainer的位置 = 拼图缺口在拼图底片中的位置，这就是为什么x方向的位置是puzzlePosition.x - _puzzleBlankPosition.x，而 puzzlePosition.x指的就是你x方向滑动的距离
    
    [self setPuzzleContainerPosition:CGPointMake(
                                                 puzzlePosition.x - _puzzleBlankPosition.x,
                                                 [self findThePuzzleFrame].origin.y)];
}

- (CGPoint)puzzlePosition {
    return CGPointMake(_puzzleContainerPosition.x + _puzzleBlankPosition.x,
                       _puzzleContainerPosition.y + _puzzleBlankPosition.y);
}

// Puzzle blank position，设置拼图缺口的位置

- (void)setPuzzleBlankPosition:(CGPoint)puzzleBlankPosition {
    _puzzleBlankPosition = puzzleBlankPosition;
    [self updatePuzzleMask];
}

// Puzzle pattern

- (void)setPuzzlePattern:(TTGPuzzleVerifyPattern)puzzlePattern {
    _puzzlePattern = puzzlePattern;
    [self updatePuzzleMask];
}

// Image

- (void)setImage:(UIImage *)image {
    _image = image;
    _backImageView.image = _image;
    _frontImageView.image = _image;
    _puzzleImageView.image = _image;
    [self updatePuzzleMask];
}

// Puzzle size

- (void)setPuzzleSize:(CGSize)puzzleSize {
    _puzzleSize = puzzleSize;
    [self updatePuzzleMask];
}

// Puzzle custom pattern path

- (void)setCustomPuzzlePatternPath:(UIBezierPath *)customPuzzlePatternPath {
    _customPuzzlePatternPath = customPuzzlePatternPath;
    [self updatePuzzleMask];
}

// Puzzle container position

- (void)setPuzzleContainerPosition:(CGPoint)puzzleContainerPosition {
    _puzzleContainerPosition = puzzleContainerPosition;
    CGRect frame = _puzzleImageContainerView.frame;
    frame.origin = puzzleContainerPosition;
    _puzzleImageContainerView.frame = frame;
}

// Puzzle X position percentage

- (CGFloat)puzzleXPercentage {
    return ([self puzzlePosition].x - [self puzzleMinX]) / ([self puzzleMaxX] - [self puzzleMinX]);
}

- (void)setPuzzleXPercentage:(CGFloat)puzzleXPercentage {
    if (!_enable) {
        return;
    }
    
    // Limit range
    puzzleXPercentage = MAX(0, puzzleXPercentage);
    puzzleXPercentage = MIN(1, puzzleXPercentage);

    // Change position
    CGPoint position = [self puzzlePosition];
    //计算位置，为最小数值加上 偏移值
    position.x = puzzleXPercentage * ([self puzzleMaxX] - [self puzzleMinX]) + [self puzzleMinX]+[self findThePuzzleFrame].origin.x;
    
    [self setPuzzlePosition:position];
    
    // Callback
    [self performCallback];
}

// Puzzle Y position percentage

- (CGFloat)puzzleYPercentage {
    return ([self puzzlePosition].y - [self puzzleMinY]) / ([self puzzleMaxY] - [self puzzleMinY]);
}

- (void)setPuzzleYPercentage:(CGFloat)puzzleYPercentage {
    if (!_enable) {
        return;
    }
    
    // Limit range
    puzzleYPercentage = MAX(0, puzzleYPercentage);
    puzzleYPercentage = MIN(1, puzzleYPercentage);

    // Change position
    CGPoint position = [self puzzlePosition];
    position.y = puzzleYPercentage * ([self puzzleMaxY] - [self puzzleMinY]) + [self puzzleMinY];
    [self setPuzzlePosition:position];
    
    // Callback
    [self performCallback];
}

// isVerified

- (BOOL)isVerified {
    return fabs([self puzzlePosition].x-[self findThePuzzleFrame].origin.x - _puzzleBlankPosition.x) <= _verificationTolerance;
}

// Puzzle position range

- (CGFloat)puzzleMinX {
    return 0;
}

- (CGFloat)puzzleMaxX {
    CGRect rect = [self findThePuzzleFrame];
    return CGRectGetWidth(rect) - _puzzleSize.width;
}

- (CGFloat)puzzleMinY {
    return 0;
}

- (CGFloat)puzzleMaxY {
    CGRect rect = [self findThePuzzleFrame];
    return CGRectGetHeight(rect) - _puzzleSize.height;
}

// Puzzle shadow

- (void)setPuzzleShadowColor:(UIColor *)puzzleShadowColor {
    _puzzleShadowColor = puzzleShadowColor;
    _puzzleImageContainerView.layer.shadowColor = puzzleShadowColor.CGColor;
}

- (void)setPuzzleShadowRadius:(CGFloat)puzzleShadowRadius {
    _puzzleShadowRadius = puzzleShadowRadius;
    _puzzleImageContainerView.layer.shadowRadius = puzzleShadowRadius;
}

- (void)setPuzzleShadowOpacity:(CGFloat)puzzleShadowOpacity {
    _puzzleShadowOpacity = puzzleShadowOpacity;
    _puzzleImageContainerView.layer.shadowOpacity = puzzleShadowOpacity;
}

- (void)setPuzzleShadowOffset:(CGSize)puzzleShadowOffset {
    _puzzleShadowOffset = puzzleShadowOffset;
    _puzzleImageContainerView.layer.shadowOffset = puzzleShadowOffset;
}

// Puzzle blank alpha

- (void)setPuzzleBlankAlpha:(CGFloat)puzzleBlankAlpha {
    _puzzleBlankAlpha = puzzleBlankAlpha;
    _backImageView.alpha = puzzleBlankAlpha;
}

// Puzzle blank inner shadow

- (void)setPuzzleBlankInnerShadowColor:(UIColor *)puzzleBlankInnerShadowColor {
    _puzzleBlankInnerShadowColor = puzzleBlankInnerShadowColor;
    _backInnerShadowLayer.shadowColor = puzzleBlankInnerShadowColor.CGColor;
}

- (void)setPuzzleBlankInnerShadowRadius:(CGFloat)puzzleBlankInnerShadowRadius {
    _puzzleBlankInnerShadowRadius = puzzleBlankInnerShadowRadius;
    _backInnerShadowLayer.shadowRadius = puzzleBlankInnerShadowRadius;
}

- (void)setPuzzleBlankInnerShadowOpacity:(CGFloat)puzzleBlankInnerShadowOpacity {
    _puzzleBlankInnerShadowOpacity = puzzleBlankInnerShadowOpacity;
    _backInnerShadowLayer.shadowOpacity = puzzleBlankInnerShadowOpacity;
}

- (void)setPuzzleBlankInnerShadowOffset:(CGSize)puzzleBlankInnerShadowOffset {
    _puzzleBlankInnerShadowOffset = puzzleBlankInnerShadowOffset;
    _backInnerShadowLayer.shadowOffset = puzzleBlankInnerShadowOffset;
}

@end
