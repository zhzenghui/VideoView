//
//  ZHCameraVideoHelper.m
//  rmz
//
//  Created by bejoy on 14-5-29.
//  Copyright (c) 2014年 zeng hui. All rights reserved.
//

#import "ZHCameraVideoHelper.h"
#import <CoreMedia/CoreMedia.h>
#import <ImageIO/ImageIO.h>


@implementation ZHCameraVideoHelper

//static CameraImageHelper *sharedInstance = nil;

- (void) initialize
{
    //1.创建会话层
    self.session = [[AVCaptureSession alloc] init];
    if ([_session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        _session.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    else {
        // Handle the failure.
    }
    
    //2.创建、配置输入设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    
    NSArray *devices = [AVCaptureDevice devices];
    
    for (AVCaptureDevice *device in devices) {
        
        NSLog(@"Device name: %@", [device localizedName]);
        
        if ([device hasMediaType:AVMediaTypeVideo]) {
            
            if ([device position] == AVCaptureDevicePositionBack) {
                NSLog(@"Device position : back");
            }
            else {
                NSLog(@"Device position : front");
            }
        }
    }
    
    
#if 1
    int flags = NSKeyValueObservingOptionNew; //监听自动对焦
    [device addObserver:self forKeyPath:@"adjustingFocus" options:flags context:nil];
#endif
    
	NSError *error;
	AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
	if (!captureInput)
	{
		NSLog(@"Error: %@", error);
		return;
	}
    [self.session addInput:captureInput];
    
    
    
    
    dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
	[self setSessionQueue:sessionQueue];

    
    AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    if ([_session canAddOutput:movieFileOutput])
    {
        [_session addOutput:movieFileOutput];
        AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([connection isVideoStabilizationSupported])
            [connection setEnablesVideoStabilizationWhenAvailable:YES];
        [self setMovieFileOutput:movieFileOutput];
    }
    
    
    //3.创建、配置输出
    _captureOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
    [_captureOutput setOutputSettings:outputSettings];
    
	[self.session addOutput:_captureOutput];
    
    
    
}

- (void)setClipSquare
{
    NSDictionary *videoCleanApertureSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSNumber numberWithInt:320], AVVideoCleanApertureWidthKey,
                                                [NSNumber numberWithInt:480], AVVideoCleanApertureHeightKey,
                                                [NSNumber numberWithInt:10], AVVideoCleanApertureHorizontalOffsetKey,
                                                [NSNumber numberWithInt:10], AVVideoCleanApertureVerticalOffsetKey,
                                                nil];
    
    
    NSDictionary *videoAspectRatioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithInt:3], AVVideoPixelAspectRatioHorizontalSpacingKey,
                                              [NSNumber numberWithInt:3],AVVideoPixelAspectRatioVerticalSpacingKey,
                                              nil];
    
    
    
    NSDictionary *codecSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt:960000], AVVideoAverageBitRateKey,
                                   [NSNumber numberWithInt:1],AVVideoMaxKeyFrameIntervalKey,
                                   videoCleanApertureSettings, AVVideoCleanApertureKey,
                                   //videoAspectRatioSettings, AVVideoPixelAspectRatioKey,
                                   //AVVideoProfileLevelH264Main30, AVVideoProfileLevelKey,
                                   nil];
    
    
    
    
    
    NSString *targetDevice = [[UIDevice currentDevice] model];
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   codecSettings,AVVideoCompressionPropertiesKey,
                                   [NSNumber numberWithInt:320], AVVideoWidthKey,
                                   [NSNumber numberWithInt:480], AVVideoHeightKey,
                                   nil];
}

- (id) init
{
	if (self = [super init])
        [self initialize];
	return self;
}


//对焦回调
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if( [keyPath isEqualToString:@"adjustingFocus"] ){
        BOOL adjustingFocus = [ [change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1] ];
        NSLog(@"Is adjusting focus? %@", adjustingFocus ? @"YES" : @"NO" );
        NSLog(@"Change dictionary: %@", change);
        if (_delegate) {
            
            if ( _delegate  ) {
                
            }
            [_delegate foucusStatus:adjustingFocus];
        }
    }
}





-(void) embedPreviewInView: (UIView *) aView {
    if (!_session) return;
    //设置取景
    _preview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    _preview.frame = aView.bounds;
    _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [aView.layer addSublayer: _preview];
}


- (void)changePreviewOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (!_preview) {
        return;
    }
    [CATransaction begin];
    if (interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        g_orientation = UIImageOrientationUp;
        _preview.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        
    }else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft){
        g_orientation = UIImageOrientationDown;
        _preview.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
        
    }else if (interfaceOrientation == UIDeviceOrientationPortrait){
        g_orientation = UIImageOrientationRight;
        _preview.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        
    }else if (interfaceOrientation == UIDeviceOrientationPortraitUpsideDown){
        g_orientation = UIImageOrientationLeft;
        _preview.connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
    }
    [CATransaction commit];
}


-(void)giveImg2Delegate
{
    [_delegate didFinishedCapture:_image];
}


-(void)Captureimage
{
    //get connection
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in _captureOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) { break; }
    }
    
    
    
    //get UIImage
    [_captureOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:
     ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
         CFDictionaryRef exifAttachments =
         CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
         if (exifAttachments) {
             // Do something with the attachments.
         }
         
         // Continue as appropriate.
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         UIImage *t_image = [UIImage imageWithData:imageData];
         _image = [[UIImage alloc]initWithCGImage:t_image.CGImage scale:1.0 orientation:g_orientation];
         
         [self giveImg2Delegate];
     }];
}


- (void)removeAVObserver
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device removeObserver:self forKeyPath:@"adjustingFocus"];
	self.session = nil;
	self.image = nil;
    


}

- (void)toggleMovieRecording:(id)sender
{
    
	dispatch_async([self sessionQueue], ^{
		if (![[self movieFileOutput] isRecording])
		{
			
			if ([[UIDevice currentDevice] isMultitaskingSupported])
			{
				// Setup background task. This is needed because the captureOutput:didFinishRecordingToOutputFileAtURL: callback is not received until AVCam returns to the foreground unless you request background execution time. This also ensures that there will be time to write the file to the assets library when AVCam is backgrounded. To conclude this background execution, -endBackgroundTask is called in -recorder:recordingDidFinishToOutputFileURL:error: after the recorded file has been saved.
//				[self setBackgroundRecordingID:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil]];
			}
			
			// Update the orientation on the movie file output video connection before starting recording.
//			[[[self movieFileOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[[ preview layer] connection] videoOrientation]];

			[self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
			// Turning OFF flash for video recording
//			[AVCamViewController setFlashMode:AVCaptureFlashModeOff forDevice:[[self videoDeviceInput] device]];
			

            
			// Start recording to a temporary file.
            NSString *shu = [NSString stringWithFormat:@"%d", arc4random()];
            NSString *name = [NSString stringWithFormat:@"movie_%@", shu ];
			NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"mov"]];
			[[self movieFileOutput] startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
		}
		else
		{
			[[self movieFileOutput] stopRecording];
		}
	});
    
}


- (void) startRunning
{
	[[self session] startRunning];
}

- (void) stopRunning
{
	[[self session] stopRunning];
}

-(void)CaptureStillImage
{
    [self  Captureimage];
}




@end
