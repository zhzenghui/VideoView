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
#import <AssetsLibrary/AssetsLibrary.h>

static void * RecordingContext = &RecordingContext;

@implementation ZHCameraVideoHelper

//static CameraImageHelper *sharedInstance = nil;

- (void) initialize
{
    
    
    [self setBackgroundRecordingID:UIBackgroundTaskInvalid];

    
    //1.创建会话层
    self.session = [[AVCaptureSession alloc] init];
    if ([_session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        _session.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    else {
        // Handle the failure.
    }
    
    
    //2.创建、配置输入设备
    
//    麦克
    NSError *error;
    
    AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
	if (!audioDeviceInput)
	{
		NSLog(@"Error: %@", error);
		return;
	}
    [self.session addInput:audioDeviceInput];
    

    
    
    
//    摄像机
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
    
    
    dispatch_async([self sessionQueue], ^{

		[self addObserver:self forKeyPath:@"movieFileOutput.recording" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:RecordingContext];

		

		[[self session] startRunning];
	});

    
    
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
    else if (context == RecordingContext)
	{
		BOOL isRecording = [change[NSKeyValueChangeNewKey] boolValue];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (isRecording)
			{
                //				[[self cameraButton] setEnabled:NO];
                //				[[self recordButton] setTitle:NSLocalizedString(@"Stop", @"Recording button stop title") forState:UIControlStateNormal];
                //				[[self recordButton] setEnabled:YES];
                
                NSLog(@"stop");
			}
			else
			{
                //				[[self cameraButton] setEnabled:YES];
                //				[[self recordButton] setTitle:NSLocalizedString(@"Record", @"Recording button record title") forState:UIControlStateNormal];
                //				[[self recordButton] setEnabled:YES];
                
                
                NSLog(@"start");
            }
		});
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
				[self setBackgroundRecordingID:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil]];
			}
			
			// Update the orientation on the movie file output video connection before starting recording.
//			[[[self movieFileOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[[ preview layer] connection] videoOrientation]];

			[self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
			// Turning OFF flash for video recording
//			[AVCamViewController setFlashMode:AVCaptureFlashModeOff forDevice:[[self videoDeviceInput] device]];
			


            
			// Start recording to a temporary file.
            NSString *shu = [NSString stringWithFormat:@"%d", arc4random()];
            NSString *name = [NSString stringWithFormat:@"m_%@", shu ];
			NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"mov"]];
			[[self movieFileOutput] startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];

		}
		else
		{
			[[self movieFileOutput] stopRecording];
		}
	});
    
}

-(void)CropVideo:(NSURL*) filePath : (BOOL) forceToPortrait : (BOOL) deleteOriginalVideo{
    
    NSString* docFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];

    NSString *shu = [NSString stringWithFormat:@"%d", arc4random()];
    NSString *name = [NSString stringWithFormat:@"m_%@", shu ];
    NSString *outputPath = [docFolder stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"mov"]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath])
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
    
    
    
    AVAsset* originalAsset = [AVAsset assetWithURL:filePath];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    [composition  addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack *originalAssetTrack = [[originalAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = CGSizeMake(640, 640);
    videoComposition.frameDuration = CMTimeMake(1, 30);
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30) );
    
    if (forceToPortrait){
        AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:originalAssetTrack];
        CGAffineTransform t1 = CGAffineTransformMakeTranslation(originalAssetTrack.naturalSize.height, -(originalAssetTrack.naturalSize.width - originalAssetTrack.naturalSize.height) /2 );
        CGAffineTransform t2 = CGAffineTransformRotate(t1, M_PI_2);
        
        CGAffineTransform finalTransform = t2;
        [transformer setTransform:finalTransform atTime:kCMTimeZero];
        instruction.layerInstructions = [NSArray arrayWithObject:transformer];
        videoComposition.instructions = [NSArray arrayWithObject: instruction];
    }
    
    exporter = [[AVAssetExportSession alloc] initWithAsset:originalAsset presetName:AVAssetExportPresetHighestQuality] ;
    exporter.videoComposition = videoComposition;
    exporter.outputURL=[NSURL fileURLWithPath:outputPath];
    exporter.outputFileType=AVFileTypeQuickTimeMovie;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^(void){
        NSLog(@"FinishedExporting!");
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"%@", filePath.absoluteString);
            if (deleteOriginalVideo && [[NSFileManager defaultManager] fileExistsAtPath:filePath.absoluteString]){
                [[NSFileManager defaultManager] removeItemAtPath:filePath.absoluteString error:nil];
            }
            
        }
                       
                       );
    }];
}


- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
	if (error)
		NSLog(@"%@", error);
	
//	[self setLockInterfaceRotation:NO];
	
	// Note the backgroundRecordingID for use in the ALAssetsLibrary completion handler to end the background task associated with this recording. This allows a new recording to be started, associated with a new UIBackgroundTaskIdentifier, once the movie file output's -isRecording is back to NO — which happens sometime after this method returns.
	UIBackgroundTaskIdentifier backgroundRecordingID = [self backgroundRecordingID];
	[self setBackgroundRecordingID:UIBackgroundTaskInvalid];
	

    [self  CropVideo:outputFileURL :YES :YES ];
//	[[[ALAssetsLibrary alloc] init] writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
//		if (error)
//			NSLog(@"%@", error);
//		
//		[[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
//		
//		if (backgroundRecordingID != UIBackgroundTaskInvalid)
//			[[UIApplication sharedApplication] endBackgroundTask:backgroundRecordingID];
//	}];
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
