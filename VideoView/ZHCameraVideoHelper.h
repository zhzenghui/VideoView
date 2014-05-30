//
//  ZHCameraVideoHelper.h
//  rmz
//
//  Created by bejoy on 14-5-29.
//  Copyright (c) 2014年 zeng hui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol AVVideoHelperDelegate;

@interface ZHCameraVideoHelper : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate,
AVCaptureFileOutputRecordingDelegate>
{
    UIImageOrientation g_orientation;
    
    
}
@property (nonatomic) dispatch_queue_t sessionQueue; // Communicate with the session and other session objects on this queue.

@property (retain) AVCaptureSession *session;
@property (retain) AVCaptureStillImageOutput *captureOutput;
@property (retain) UIImage *image;
@property (assign) UIImageOrientation g_orientation;
@property (strong) AVCaptureVideoPreviewLayer *preview;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (assign) id<AVVideoHelperDelegate>delegate;

- (void) startRunning;
- (void) stopRunning;

- (void)setDelegate:(id<AVVideoHelperDelegate>)_delegate;
- (void)CaptureStillImage;
- (void)embedPreviewInView: (UIView *) aView;
- (void)changePreviewOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)removeAVObserver;

- (void)toggleMovieRecording:(id)sender;

@end

@protocol AVVideoHelperDelegate <NSObject>

- (void)didFinishedCapture:(UIImage*)_img;
- (void)foucusStatus:(BOOL)isadjusting;
@end
