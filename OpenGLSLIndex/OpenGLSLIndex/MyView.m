//
//  MyView.m
//  OpenGLSLIndex
//
//  Created by MacW on 2020/8/2.
//  Copyright © 2020 MacW. All rights reserved.
//

#import "MyView.h"
#import <OpenGLES/ES2/gl.h>
#import "GLESMath.h"

@interface MyView ()
{
    float xDegree;
    float yDegree;
    float zDegree;
    BOOL bX;
    BOOL bY;
    BOOL bZ;
    NSTimer* myTimer;
    
    
}
@property (nonatomic ,strong)CAEAGLLayer *myLayer;
@property (nonatomic, strong) EAGLContext  *myContext;

@property (nonatomic, assign) GLuint myColorRenderBufferId;
@property (nonatomic, assign) GLuint myColorFrameBufferId;
@property (nonatomic, assign) GLuint myProgram;


@end

@implementation MyView

- (void)layoutSubviews {
    [self setUpLayer];
    [self setUpContext];
    [self deleteRenderAndFrameBuffer];
    [self setRenderBuffer];
    [self setUpFrameBuffer];
    [self render];
    
}

-(void)render {
    
    glClearColor(0.8, 0.2, 0.4, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    float scale = [UIScreen mainScreen].scale;
    glViewport(self.frame.origin.x*scale, self.frame.origin.y*scale, self.frame.size.width*scale, self.frame.size.height*scale);
    self.myProgram = [self loadVertexShaderAndFraneShader];
    glLinkProgram(self.myProgram);
    GLint linkSuccess;
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(self.myProgram, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"error%@", messageString);
        return;
    } else {
        NSLog(@"link success");
        glUseProgram(self.myProgram);
    }
    GLfloat attributeArr[] = {
        -0.5,-0.5,0.5,   1.0f, 0.0f, 1.0f,    0,0,
        0.5,-0.5,0.5,    1.0f, 0.0f, 1.0f,   0,1,
        0.5,-0.5,-0.5, 1.0f, 1.0f, 1.0f,    1.0,1.0,
        -0.5,-0.5,-0.5, 1.0f, 1.0f, 1.0f,   1,0,
        0.0,1.0,0.0,    0.0f, 1.0f, 0.0f,   0.5,0.5,
    };
    
    GLint indices[]= {
        0,2,1,
        0,3,2,
        0,1,4,
        1,2,4,
        2,3,4,
        3,0,4,
    };
    GLuint buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attributeArr), attributeArr, GL_STATIC_DRAW);
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    glEnableVertexAttribArray(position);
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(float)*8, NULL);

    GLuint positionColor = glGetAttribLocation(self.myProgram, "positionColor");
    glEnableVertexAttribArray(positionColor);
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(float)*8, (GLfloat *)NULL+3);
    
    [self setUpTexture];

    GLuint textCoordinate = glGetAttribLocation(self.myProgram, "textCoordinate");
    glEnableVertexAttribArray(textCoordinate);
    glVertexAttribPointer(textCoordinate, 2, GL_FLOAT, GL_FALSE, sizeof(float)*8, (GLfloat *)NULL+6);
    glUniform1i(glGetUniformLocation(self.myProgram, "colorMap"), 0);
    GLuint projectionMatrix,modelViewMatrix;
    projectionMatrix  = glGetUniformLocation(self.myProgram, "projectionMatrix");
    modelViewMatrix = glGetUniformLocation(self.myProgram, "modelViewMatrix");
    glEnable(GL_CULL_FACE);
//    glEnable(GL_DEPTH_TEST);
    KSMatrix4 projectMatrix4;
    ksMatrixLoadIdentity(&projectMatrix4);
    ksPerspective(&projectMatrix4, 30.0, self.frame.size.width/self.frame.size.height, 5.f, 500);
    glUniformMatrix4fv(projectionMatrix, 1, GL_FALSE, &projectMatrix4.m[0][0]);
     //13.创建一个4 * 4 矩阵，模型视图矩阵
     KSMatrix4 _modelViewMatrix;
     //(1)获取单元矩阵
     ksMatrixLoadIdentity(&_modelViewMatrix);
     //(2)平移，z轴平移-10
     ksTranslate(&_modelViewMatrix, 0.0, 0.0, -10.0);
     //(3)创建一个4 * 4 矩阵，旋转矩阵
     KSMatrix4 _rotationMatrix;
     //(4)初始化为单元矩阵
     ksMatrixLoadIdentity(&_rotationMatrix);
     //(5)旋转
     ksRotate(&_rotationMatrix, xDegree, 1.0, 0.0, 0.0); //绕X轴
     ksRotate(&_rotationMatrix, yDegree, 0.0, 1.0, 0.0); //绕Y轴
     ksRotate(&_rotationMatrix, zDegree, 0.0, 0.0, 1.0); //绕Z轴
     //(6)把变换矩阵相乘.将_modelViewMatrix矩阵与_rotationMatrix矩阵相乘，结合到模型视图
      ksMatrixMultiply(&_modelViewMatrix, &_rotationMatrix, &_modelViewMatrix);

    glUniformMatrix4fv(modelViewMatrix, 1, GL_FALSE, &_modelViewMatrix.m[0][0]);
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];


}

-(void)setUpTexture {
    
    CGImageRef image = [UIImage imageNamed:@"test.jpg"].CGImage;
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    GLubyte *spriteData = (GLubyte *)calloc(width*height*4, sizeof(GLubyte));
    CGContextRef context = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(image),kCGImageAlphaPremultipliedLast );
    CGRect rect = CGRectMake(0, 0, width, height);
    CGContextDrawImage(context, rect, image);
    CGContextRelease(context);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    float texWidth = width,texHeight = height;

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texWidth, texHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    free(spriteData);
    
    
}

-(GLuint)loadVertexShaderAndFraneShader {
    GLuint verShader,frameShader ;
    
    NSString *vshaderFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
    NSString *fshaderFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];
    [self loadShader:&verShader type:GL_VERTEX_SHADER fileString:vshaderFile];
    [self loadShader:&frameShader type:GL_FRAGMENT_SHADER   fileString:fshaderFile];

   GLuint program = glCreateProgram();
    glAttachShader(program, verShader);
    glAttachShader(program, frameShader);
    glDeleteShader(verShader);
    glDeleteShader(frameShader);
    
    return program;
}
-(void)loadShader:(GLuint *)shader type:(GLuint)type fileString:(NSString *)file {
    NSString *context = [[NSString alloc] initWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar *source = (GLchar *)[context UTF8String];
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    
}
-(void)setUpFrameBuffer {
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    glBindFramebuffer(GL_FRAMEBUFFER, buffer);
    self.myColorFrameBufferId = buffer;
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBufferId);
    
}
-(void)setRenderBuffer {
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    glBindRenderbuffer(GL_RENDERBUFFER, buffer);
    self.myColorRenderBufferId = buffer;
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myLayer];
}
-(void)deleteRenderAndFrameBuffer {
    glDeleteRenderbuffers(1, &_myColorRenderBufferId);
    self.myColorRenderBufferId = 0;
    glDeleteFramebuffers(1, &_myColorFrameBufferId);
    self.myColorFrameBufferId = 0;
}
-(void)setUpContext {
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!context) {
        NSLog(@"create context failed");
        return;
    }
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"set current context failed");
        return;
    }
    self.myContext = context;
    
}
-(void)setUpLayer {
    self.myLayer = (CAEAGLLayer *)self.layer;
    [self setContentScaleFactor:[UIScreen mainScreen].scale];
    self.myLayer.drawableProperties = @{
        kEAGLDrawablePropertyRetainedBacking:@false,
        kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8,
    };
    
}
- (IBAction)cButton:(id)sender {
    //开启定时器
     if (!myTimer) {
         myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
     }
     //更新的是X还是Y
     bZ = !bZ;
}
- (IBAction)bButton:(id)sender {
    //开启定时器
      if (!myTimer) {
          myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
      }
      //更新的是X还是Y
      bY = !bY;
}
- (IBAction)xButton:(id)sender {
    //开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    //更新的是X还是Y
    bX = !bX;
}
-(void)reDegree
{
    //如果停止X轴旋转，X = 0则度数就停留在暂停前的度数.
    //更新度数
    xDegree += bX * 5;
    yDegree += bY * 5;
    zDegree += bZ * 5;
    //重新渲染
    [self render];
    
}

+ (Class)layerClass {
    return  [CAEAGLLayer class];;
}

@end
