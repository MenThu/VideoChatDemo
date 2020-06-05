//
//  MTGLHead.h
//  VideoChatDemo
//
//  Created by menthu on 2020/5/8.
//  Copyright © 2020 menthu. All rights reserved.
//

#ifndef MTGLHead_h
#define MTGLHead_h

#define MTGetGLError() \
{ \
GLenum glErrorNo = glGetError(); \
if (glErrorNo != GL_NO_ERROR) { \
NSLog(@"[%@:%d] glerror %d", [[NSString stringWithFormat:@"%s", __FILE__] componentsSeparatedByString:@"/"].lastObject, \
__LINE__, glErrorNo); \
} \
}

#ifdef DEBUG
#define MTLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __func__, __LINE__, ##__VA_ARGS__)
#else
#define MTLog(...)
#endif

#endif /* MTGLHead_h */
