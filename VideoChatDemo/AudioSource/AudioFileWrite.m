//
//  AudioFileWrite.m
//  VideoChatDemo
//
//  Created by menthu on 2022/8/26.
//  Copyright © 2022 menthu. All rights reserved.
//

#import "AudioFileWrite.h"

@interface AudioFileWrite ()

@property (nonatomic, assign) AudioFileID fileID;

@end

@implementation AudioFileWrite

+ (BOOL)write2FilePath:(NSString *)filePath
       withAudioFormat:(const AudioStreamBasicDescription *)format
             audioData:(NSData *)pcmAudioData
          audioPackets:(UInt32)audioPackets{
    NSString *cachesDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *avlogPath = [NSString stringWithFormat:@"%@/%@", cachesDir, filePath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:avlogPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:avlogPath error:nil];
    }
    
    NSLog(@"[%s] write file data to [%@] audioPackets=[%u]", __FUNCTION__, avlogPath, audioPackets);
    const char *path = avlogPath.UTF8String;
    const CFURLRef outputFileURL = CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault,
                                                                           (UInt8*)path,
                                                                           strlen(path),
                                                                           false);
    AudioFileID fileID;
    OSStatus err = AudioFileCreateWithURL(outputFileURL,
                                          kAudioFileWAVEType,
                                          format,
                                          kAudioFileFlags_EraseFile,
                                          &fileID);
    CFRelease(outputFileURL);
    if (err != noErr) {
        NSLog(@"[%s] create audio file failed=[%d]",__FUNCTION__, err);
        return NO;
    }
    
    UInt32 inNumPackets = audioPackets;
    err = AudioFileWritePackets(fileID,
                                false,
                                (UInt32)pcmAudioData.length,
                                NULL,
                                0,
                                &inNumPackets,
                                pcmAudioData.bytes);
    if (err != noErr || inNumPackets < audioPackets) {
        NSLog(@"write audio data error, err=[%d] audioPackets=[%u] inNumPackets=[%u] ",
              err, audioPackets, inNumPackets);
        return NO;
    }
    err = AudioFileClose(fileID);
    if (err != noErr) {
        NSLog(@"AudioFileClose Failed err=[%d]", err);
        return NO;
    }
    NSLog(@"[%s] save pcm 2 wave file succ", __FUNCTION__);
    return YES;
}

@end
