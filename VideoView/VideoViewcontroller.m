//
//  VideoViewcontroller.m
//  rmz
//
//  Created by bejoy on 14-5-29.
//  Copyright (c) 2014年 zeng hui. All rights reserved.
//

#import "VideoViewcontroller.h"
#import "ZHCameraVideoHelper.h"


@interface VideoViewcontroller ()
@property(retain,nonatomic) ZHCameraVideoHelper *cameraHelper;

@end

@implementation VideoViewcontroller

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

    _cameraHelper = [[ZHCameraVideoHelper alloc]init];
    
    // 开始实时取景
    [_cameraHelper startRunning];
    [_cameraHelper embedPreviewInView:self.liveImageView];
    
    [_cameraHelper changePreviewOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    
    
}


- (void)viewWillDisappear:(BOOL)animated
{
    
    [super viewWillDisappear:YES];
    
    
    [_cameraHelper stopRunning];
    [_cameraHelper removeAVObserver];
    
    

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [_cameraHelper changePreviewOrientation:(UIInterfaceOrientation)toInterfaceOrientation];
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)test:(id)sender {
    NSLog(@"test");
}

- (IBAction)startRecord:(id)sender {
    
    [_cameraHelper toggleMovieRecording:nil];
  
}
- (IBAction)stopRecord:(id)sender {

    [_cameraHelper toggleMovieRecording:nil];
}
@end
