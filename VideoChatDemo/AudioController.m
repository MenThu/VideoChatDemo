//
//  AudioController.m
//  VideoChatDemo
//
//  Created by menthu on 2022/8/23.
//  Copyright © 2022 menthu. All rights reserved.
//

#import "AudioController.h"
#import "AudioManager.h"

@interface AudioController ()

@end

@implementation AudioController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSLog(@"%s", __FUNCTION__);
}

- (IBAction)onStartClick:(UIButton *)sender {
    NSLog(@"%s", __FUNCTION__);
    
    [AudioManager.shareInstance startRecordWithSampleRate:44100 channels:1 sampleBits:16];
}


- (IBAction)onStopClick:(UIButton *)sender {
    NSLog(@"%s", __FUNCTION__);
    
    [AudioManager.shareInstance stopRecord];
}



@end
