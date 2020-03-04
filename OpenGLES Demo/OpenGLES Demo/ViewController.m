//
//  ViewController.m
//  OpenGLES Demo
//
//  Created by 李超群 on 2020/3/4.
//  Copyright © 2020 李超群. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "DYGLESView.h"

@interface ViewController ()

@property (nonatomic,strong)AVPlayer *player;
@property (nonatomic,strong)AVPlayerItemVideoOutput *videoOutput;
@property (nonatomic, strong) CADisplayLink *displayLink;

// - 渲染视频的 view
@property (nonatomic, weak) DYGLESView *glView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIImageView *img = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"img_shareMusician_bg"]];
    img.frame = self.view.bounds;
    [self.view addSubview:img];
    NSURL *url = [[NSBundle mainBundle]URLForResource:@"rocket.mp4" withExtension:nil];
    self.videoOutput = [[AVPlayerItemVideoOutput alloc]init];
    AVPlayerItem *item = [[AVPlayerItem alloc]initWithURL:url];
    [item addOutput:self.videoOutput];
    _player = [[AVPlayer alloc]initWithPlayerItem:item];
    [self startDisplayLink];

}

#pragma mark -/** *** 懒加载 *** */
// - 渲染视频的 view
-(DYGLESView *)glView{
    if(!_glView){
        DYGLESView *glView = [[DYGLESView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:glView];
        glView.backgroundColor = [UIColor clearColor];
        _glView = glView;
    }
    return _glView;
}

/** 计时器 */
- (CADisplayLink *)displayLink{
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkDidrefresh:)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return _displayLink;
}

-(void)stopDisplayLink{
    [self.displayLink setPaused:YES];
}

-(void)startDisplayLink{
    [self.displayLink setPaused:NO];
    [self.player play];
}

#pragma mark -/** *** 计时器事件 *** */
-(void)displayLinkDidrefresh:(CADisplayLink*)link{
    CMTime itemTime = _player.currentItem.currentTime;
    CVPixelBufferRef pixelBuffer = [self.videoOutput copyPixelBufferForItemTime:itemTime itemTimeForDisplay:nil];
    [self.glView displayPixelBuffer:pixelBuffer];
    CVPixelBufferRelease(pixelBuffer);

    Float64 duration = -1;
    if (self.player.currentItem.status == AVPlayerStatusReadyToPlay) {
        duration = CMTimeGetSeconds(_player.currentItem.duration);
    }
    if (CMTimeGetSeconds(itemTime) == duration) {
        [self stopDisplayLink];
        self.glView.hidden = YES;
    }
}

@end
