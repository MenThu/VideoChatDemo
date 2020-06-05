//
//  MTGLTool.m
//  VideoChatDemo
//
//  Created by menthu on 2020/6/2.
//  Copyright © 2020 menthu. All rights reserved.
//

#import "MTGLTool.h"

static const void *_interQueueKey = &_interQueueKey;
static dispatch_queue_t QAVVideoChatModuleSerialQueue(){
    static dispatch_queue_t _qav_service_serial_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _qav_service_serial_queue = dispatch_queue_create("com.tencent.qavvideochatmodule.serial.queue", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_qav_service_serial_queue, &_interQueueKey, (void *)_interQueueKey, NULL);
    });
    return _qav_service_serial_queue;
}

void executeTaskInQueue(BOOL isSync, dispatch_block_t _Nonnull task){
    if (task == nil) {
        return;
    }
    if (dispatch_get_specific(&_interQueueKey) == NULL) {
        if (isSync) {
            dispatch_sync(QAVVideoChatModuleSerialQueue(), task);
        } else {
            dispatch_async(QAVVideoChatModuleSerialQueue(), task);
        }
    } else {
        if (isSync) {
            task();
        } else {
            dispatch_async(QAVVideoChatModuleSerialQueue(), task);
        }
    }
}

@implementation MTGLTool



@end
