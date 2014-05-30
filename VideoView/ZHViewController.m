//
//  ZHViewController.m
//  VideoView
//
//  Created by bejoy on 14-5-30.
//  Copyright (c) 2014年 zeng hui. All rights reserved.
//

#import "ZHViewController.h"
#import "VideoViewcontroller.h"

@interface ZHViewController ()

@end

@implementation ZHViewController

- (void)viewDidLoad
{
    [super viewDidLoad];


    
    VideoViewcontroller *kvc = [[VideoViewcontroller alloc] initWithNibName:@"VideoViewcontroller" bundle:nil];

    [self.view addSubview:kvc.view];
    [self addChildViewController:kvc];
    
    

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
