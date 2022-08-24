//
//  AudioHelper.m
//  VideoChatDemo
//
//  Created by menthu on 2022/8/23.
//  Copyright © 2022 menthu. All rights reserved.
//

#import "AudioHelper.h"

@implementation AudioHelper

+ (void)savePCMData:(NSData *)pcmData
         sampleRate:(int)sampleRate
         channelNum:(int)channelNum
         toFilename:(NSString *)filename {
    NSString *cachesDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *avlogPath = [NSString stringWithFormat:@"%@/%@", cachesDir, filename];
    
    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString * path = [NSString stringWithFormat:@"%@/%@",documentsDirectory,fileName];
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    BOOL isDir;
//    if (![fileManager fileExistsAtPath:path isDirectory:&isDir]) {//先判断目录是否存在，不存在才创建
//        BOOL res=[fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
//    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:avlogPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:avlogPath error:nil];
    }
    
    NSMutableData *fileData = [[NSMutableData alloc] init];
    NSData *header = [self appendWavFileHeader:pcmData.length
                                  totalDataLen:pcmData.length + 36
                                    sampleRate:sampleRate
                                      channels:channelNum
                                      byteRate:sampleRate * channelNum * 2];
    [fileData appendData:header];
    [fileData appendData:pcmData];
    
    BOOL ret = [[NSFileManager defaultManager] createFileAtPath:avlogPath contents:fileData attributes:nil];
    if (!ret) {
        NSLog(@"[%s] save pcm data failed, filepath=[%@]", __FUNCTION__, avlogPath);
    }else{
        NSLog(@"[%s] did saved=[%@]", __FUNCTION__, avlogPath);
    }
}

+ (NSData *)appendWavFileHeader:(long)totalAudioLen
                   totalDataLen:(long)totalDataLen
                     sampleRate:(long)sampleRate
                       channels:(int)channels
                       byteRate:(long)byteRate {
    Byte header[44];
    header[0] = 'R'; // RIFF/WAVE header
    header[1] = 'I';
    header[2] = 'F';
    header[3] = 'F';
    header[4] = (Byte)(totalDataLen & 0xff); // file-size (equals file-size - 8)
    header[5] = (Byte)((totalDataLen >> 8) & 0xff);
    header[6] = (Byte)((totalDataLen >> 16) & 0xff);
    header[7] = (Byte)((totalDataLen >> 24) & 0xff);
    header[8] = 'W'; // Mark it as type "WAVE"
    header[9] = 'A';
    header[10] = 'V';
    header[11] = 'E';
    header[12] = 'f'; // Mark the format section 'fmt ' chunk
    header[13] = 'm';
    header[14] = 't';
    header[15] = ' ';
    header[16] = 16; // 4 bytes: size of 'fmt ' chunk, Length of format data.  Always 16
    header[17] = 0;
    header[18] = 0;
    header[19] = 0;
    header[20] = 1; // format = 1 ,Wave type PCM
    header[21] = 0;
    header[22] = (Byte)channels; // channels
    header[23] = 0;
    header[24] = (Byte)(sampleRate & 0xff);
    header[25] = (Byte)((sampleRate >> 8) & 0xff);
    header[26] = (Byte)((sampleRate >> 16) & 0xff);
    header[27] = (Byte)((sampleRate >> 24) & 0xff);
    header[28] = (Byte)(byteRate & 0xff);
    header[29] = (Byte)((byteRate >> 8) & 0xff);
    header[30] = (Byte)((byteRate >> 16) & 0xff);
    header[31] = (Byte)((byteRate >> 24) & 0xff);
    header[32] = (Byte)(2 * 16 / 8); // block align
    header[33] = 0;
    header[34] = 16; // bits per sample
    header[35] = 0;
    header[36] = 'd'; //"data" marker
    header[37] = 'a';
    header[38] = 't';
    header[39] = 'a';
    header[40] = (Byte)(totalAudioLen & 0xff); // data-size (equals file-size - 44).
    header[41] = (Byte)((totalAudioLen >> 8) & 0xff);
    header[42] = (Byte)((totalAudioLen >> 16) & 0xff);
    header[43] = (Byte)((totalAudioLen >> 24) & 0xff);
    return [[NSData alloc] initWithBytes:header length:44];
}

@end
