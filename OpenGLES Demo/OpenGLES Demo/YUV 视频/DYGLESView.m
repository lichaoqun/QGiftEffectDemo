//
//  GLESView6.m
//  OpenGL ES Learning
//
//  Created by 李超群 on 2019/2/12.
//  Copyright © 2019 李超群. All rights reserved.
//

#import "DYGLESView.h"
#import "DYGLESUtils.h"

typedef struct {
    GLuint uniform_Y;
    GLuint uniform_UV;
}ShaderF;

typedef struct {
    GLuint attribute_position;
    GLuint attribute_texcoord;
}ShaderV;

@interface DYGLESView (){
    EAGLContext *_context;
    CVOpenGLESTextureRef _lumaTexture;
    CVOpenGLESTextureRef _chromaTexture;

    CVOpenGLESTextureCacheRef _videoTextureCache;
    
    GLuint _VAO;
    ShaderF _shaderF;
    ShaderV _shaderV;
    
}

@property GLuint program;

@end

@implementation DYGLESView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupGL];
    }
    return self;
}

# pragma mark - OpenGL setup
+ (Class)layerClass{
    return [CAEAGLLayer class];
}

- (void)setupGL{
    
    [self setupLayer];
    [self setupContext];
    [self setupBuffers];
    [self setupShader];
    [self setupRender];
}

-(void)setupLayer{
    self.contentScaleFactor = [[UIScreen mainScreen] scale];
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = @{ kEAGLDrawablePropertyRetainedBacking : @(NO),
                                      kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8};
}

-(void)setupContext{
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:_context];
}

- (void)setupBuffers{
    CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_videoTextureCache);
    
    GLuint colorRenderBufferID;
    glGenRenderbuffers(1, &colorRenderBufferID);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBufferID);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    
    GLuint frameBufferID;
    glGenFramebuffers(1, &frameBufferID);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBufferID);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, frameBufferID);
}

-(void)setupShaderData{
    glEnableVertexAttribArray(_shaderV.attribute_position);
    glEnableVertexAttribArray(_shaderV.attribute_texcoord);

    glUniform1i(_shaderF.uniform_Y, 0);
    glUniform1i(_shaderF.uniform_UV, 1);
}

- (void)setupShader{
    NSString * vertextShaderPath = [[NSBundle mainBundle] pathForResource:@"VertextShader6" ofType:@"glsl"];
    NSString * fragmentShaderPath = [[NSBundle mainBundle] pathForResource:@"FragmentShader6" ofType:@"glsl"];
    GLuint vertextShader = [DYGLESUtils loadShader:GL_VERTEX_SHADER withFilepath:vertextShaderPath];
    GLuint framegmentShader = [DYGLESUtils loadShader:GL_FRAGMENT_SHADER withFilepath:fragmentShaderPath];
    self.program = glCreateProgram();
    glAttachShader(self.program, vertextShader);
    glAttachShader(self.program, framegmentShader);
    glLinkProgram(self.program);
    glUseProgram(self.program);
    
    _shaderV.attribute_position = glGetAttribLocation(self.program, "position");
    _shaderV.attribute_texcoord = glGetAttribLocation(self.program, "texCoord");
    _shaderF.uniform_Y = glGetUniformLocation(self.program, "SamplerY");
    _shaderF.uniform_UV = glGetUniformLocation(self.program, "SamplerUV");
    
    glDetachShader(self.program, vertextShader);
    glDeleteShader(vertextShader);
    glDetachShader(self.program, framegmentShader);
    glDeleteShader(framegmentShader);
}

#pragma mark - OpenGLES drawing
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self setupShaderData];
    [self cleanUpTextures];
    CVReturn err;
    if (pixelBuffer != NULL) {
        int frameWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
        int frameHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
        
        glActiveTexture(GL_TEXTURE0);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           _videoTextureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_LUMINANCE,
                                                           frameWidth,
                                                           frameHeight,
                                                           GL_LUMINANCE,
                                                           GL_UNSIGNED_BYTE,
                                                           0,
                                                           &_lumaTexture);
        if (err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture), CVOpenGLESTextureGetName(_lumaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        // UV-plane.
        glActiveTexture(GL_TEXTURE1);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           _videoTextureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_LUMINANCE_ALPHA,
                                                           frameWidth / 2,
                                                           frameHeight / 2,
                                                           GL_LUMINANCE_ALPHA,
                                                           GL_UNSIGNED_BYTE,
                                                           1,
                                                           &_chromaTexture);
        if (err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(_chromaTexture), CVOpenGLESTextureGetName(_chromaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glViewport(0, 0, self.frame.size.width * [UIScreen mainScreen].scale, self.frame.size.width * [UIScreen mainScreen].scale);
        glBindVertexArray(_VAO);
        
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
        [_context presentRenderbuffer:GL_RENDERBUFFER];
    }
}

-(void)setupRender{
    glClearColor(0.0, 0.0, 0.0, 0.0f);

    //前三个是顶点坐标， 后面两个是纹理坐标
    GLfloat attrArr[] =
    {
        -1.0f,  1.0f,   -1.0f,      1.0f, 0.0f,
        1.0f,   1.0f,   -1.0f,      0.0f, 0.0f,
        1.0f,   -1.0f,  -1.0f,      0.0f, 1.0f,
        -1.0f,  -1.0f,  -1.0f,      1.0f, 1.0f
    };
    
    GLuint eles[] = {
        0, 1, 2,
        2, 3, 0
    };
    
    glGenVertexArrays(1, &_VAO);
    glBindVertexArray(_VAO);
    
    GLuint VBO;
    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    GLuint EVO;
    glGenBuffers(1, &EVO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EVO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(eles), eles, GL_STATIC_DRAW);
    
    glVertexAttribPointer(_shaderV.attribute_position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    glVertexAttribPointer(_shaderV.attribute_texcoord, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
    
}

- (void)cleanUpTextures
{
    if (_lumaTexture) {
        CFRelease(_lumaTexture);
        _lumaTexture = NULL;
    }
    
    if (_chromaTexture) {
        CFRelease(_chromaTexture);
        _chromaTexture = NULL;
    }
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

- (void)dealloc{
    [self cleanUpTextures];
    
    if(_videoTextureCache) {
        CFRelease(_videoTextureCache);
    }
}

/** 可以透过事件 */
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if ([super hitTest:point withEvent:event] == self) return nil;
    return [super hitTest:point withEvent:event];
}

@end
