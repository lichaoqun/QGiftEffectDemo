//
//  GLESUtils.m
//  OpenGL ES Learning
//
//  Created by 李超群 on 2019/1/24.
//  Copyright © 2019 李超群. All rights reserved.
//

#import "DYGLESUtils.h"

@implementation DYGLESUtils

+(GLuint)loadShader:(GLenum)type withFilepath:(NSString *)shaderFilepath{
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderFilepath encoding:NSUTF8StringEncoding error:nil];
    return [self loadShader:type withString:shaderString];
}

+(GLuint)loadShader:(GLenum)type withString:(NSString *)shaderString{
    GLuint shader = glCreateShader(type);
    const char *shaderStringUTF8 = [shaderString UTF8String];
    glShaderSource(shader, 1, &shaderStringUTF8, NULL);
    glCompileShader(shader);
    return shader;
}

@end
