//
//  GLESUtils.h
//  OpenGL ES Learning
//
//  Created by 李超群 on 2019/1/24.
//  Copyright © 2019 李超群. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

@interface DYGLESUtils : NSObject

+(GLuint)loadShader:(GLenum)type withFilepath:(NSString *)shaderFilepath;

@end
