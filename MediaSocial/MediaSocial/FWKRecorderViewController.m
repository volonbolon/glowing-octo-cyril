//
//  FWKRecorderViewController.m
//  MediaSocial
//
//  Created by Ariel Rodriguez on 8/10/14.
//  Copyright (c) 2014 Ariel Rodriguez. All rights reserved.
//

#import "FWKRecorderViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AWSiOSSDKv2/S3.h>
#import "FWKAppDelegate.h"

@interface FWKRecorderViewController () <AVAudioRecorderDelegate>
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;

@property (strong) AVAudioRecorder *recorder;

- (IBAction)record:(id)sender;
- (IBAction)stopRecord:(id)sender;
- (IBAction)submit:(id)sender;
@end

@implementation FWKRecorderViewController

- (void)viewDidLoad
{

    [super viewDidLoad];
    
    [[self stopButton] setEnabled:NO];
    [[self submitButton] setEnabled:NO];
    [[self recordButton] setEnabled:YES];
    
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"tmp_audio_file.m4a",
                               nil];
    
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
    BOOL success = [session setCategory:AVAudioSessionCategoryRecord error:&error];
    
    if ( success ) {
        
        // Define the recorder setting
        NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
        
        [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
        [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
        [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
        
        // Initiate and prepare the recorder
        
        AVAudioRecorder *recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting
                                                                   error:NULL];
        [recorder setDelegate:self];
        [recorder setMeteringEnabled:YES];
        
        [self setRecorder:recorder];
        
        [recorder prepareToRecord];
        
    } else {
        
        NSLog(@"%@", error);
        
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)record:(id)sender
{

    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
    BOOL success = [session setActive:YES
                                error:&error];
    if ( success ) {
        
        [[self recorder] record];
        [[self recordButton] setEnabled:NO];
        [[self stopButton] setEnabled:YES];
        
    } else {
        
        NSLog(@"%@", error);
        
    }

}

- (IBAction)stopRecord:(id)sender
{

    [[self recorder] stop];
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
    BOOL success = [session setActive:NO error:&error];
    
    if ( success ) {
    
        [[self submitButton] setEnabled:YES];
        
    } else {
        
        NSLog(@"%@", error);
        
    }
    
    [[self stopButton] setEnabled:NO];
    [[self recordButton] setEnabled:YES];
    
}

- (IBAction)submit:(id)sender
{
    
    NSURL *url = [[self recorder] url];
    
    NSError *error = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[url path] error:&error];
    
    if ( nil != attributes ) {
        
        AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
        [uploadRequest setBucket:@"fwkhackaton"];
        [uploadRequest setKey:@"ss"];
        [uploadRequest setBody:url];
        [uploadRequest setContentLength:[attributes objectForKey:NSFileSize]];
        
        [[[AWSS3TransferManager defaultS3TransferManager] upload:uploadRequest] continueWithBlock:^id(BFTask *task) {
            
                return nil;
            
        }];
    
    } else {
        
        NSLog(@"%@", error);
    
    }
    
}
@end
