//
//  ViewController.m
//  FirstOpenGLESDemo
//
//  Created by MacW on 2020/7/25.
//  Copyright © 2020 MacW. All rights reserved.
//

#import "ViewController.h"
#import <OpenGLES/ES3/glext.h>
#import <OpenGLES/ES3/gl.h>

@interface ViewController ()<GLKViewControllerDelegate>
{
    GLuint bufferID;
}
@property (strong ,nonatomic) GLKBaseEffect *baseEffect;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.delegate = self;
    [self setUpConfig];
    [self setUpVertexData];
    [self setUpTexture];
    
}

-(void)setUpConfig{
    EAGLContext *context = [[EAGLContext alloc]initWithAPI: kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:context];
    GLKView *view = (GLKView *)self.view;
    view.context = context;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
     view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    glClearColor(0.5, 0.3, 0.3, 1);
    
}

-(void)setUpVertexData {
    GLfloat vertextData[] = {
        //正前方
        -0.5,  -0.5,  0.5,    0,     0,
        0.5,   -0.5,  0.5,   1.0,    0,
        0.5,    0.5,  0.5,   1.0,   1.,
        
        0.5,     0.5, 0.5,   1.,    1.,
        -0.5,    0.5, 0.5,   0,     1.f,
        -0.5,-0.5,0.5,  0.f,0.f,
        
        //正后方
        0.5,-0.5,-0.5,    1,1.0,
        -0.5,-0.5,-0.5,   0.0,1.0,
         -0.5,0.5,-0.5,   0.0,0.f,

         -0.5,0.5,-0.5,   0.f,0.f,
         0.5,0.5,-0.5,  1,0.f,
         0.5,-0.5,-0.5,  1.f,1.f,
  
        
        //左边
        -0.5,-0.5,-0.5,  0,0,
        -0.5,0.5,0.5,   1.0,1.f,
        -0.5,-0.5,0.5,   1.0,0,
              
        -0.5,0.5,0.5,  1,1,
        -0.5,-0.5,-0.5,  0,0.f,
        -0.5,0.5,-0.5,   .0,1.f,
        
        //右边
        0.5,-0.5,0.5,  0,0,
        0.5,-0.5,-0.5,   1.0,0,
        0.5,0.5,-0.5,   1.0,1.f,
              
        0.5,0.5,-0.5,   1.f,1.f,
        0.5,0.5,0.5,  0, 1.f,
        0.5,-0.5,0.5,  0.f,0.f,
        
        //上面
        -0.5,0.5,0.5,  0,0,
        0.5,0.5,0.5,   1.0,0,
        0.5,0.5,-0.5,   1.0,1.f,
                 
        0.5,0.5,-0.5,   1.f,1.f,
        -0.5,0.5,-0.5,  0, 1.f,
        -0.5,0.5,0.5,  0.f,0.f,
        
        //下面
        -0.5,-0.5,-0.5,  0,0,
        0.5,-0.5,-0.5,   1.0,0,
        0.5,-0.5,0.5,   1.0,1.f,
                     
        0.5,-0.5,0.5,   1.f,1.f,
        -0.5,-0.5,0.5,  0, 1.f,
        -0.5,-0.5,-0.5,  0.f,0.f,
    };
    
    glEnable(GL_DEPTH_TEST);
    glGenBuffers(1, &bufferID);
    glBindBuffer(GL_ARRAY_BUFFER, bufferID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertextData), vertextData, GL_STATIC_DRAW);
     //3.打开读取通道.
     /*
      (1)在iOS中, 默认情况下，出于性能考虑，所有顶点着色器的属性（Attribute）变量都是关闭的.
      意味着,顶点数据在着色器端(服务端)是不可用的. 即使你已经使用glBufferData方法,将顶点数据从内存拷贝到顶点缓存区中(GPU显存中).
      所以, 必须由glEnableVertexAttribArray 方法打开通道.指定访问属性.才能让顶点着色器能够访问到从CPU复制到GPU的数据.
      注意: 数据在GPU端是否可见，即，着色器能否读取到数据，由是否启用了对应的属性决定，这就是glEnableVertexAttribArray的功能，允许顶点着色器读取GPU（服务器端）数据。
    
     (2)方法简介
     glVertexAttribPointer (GLuint indx, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid* ptr)
    
     功能: 上传顶点数据到显存的方法（设置合适的方式从buffer里面读取数据）
     参数列表:
         index,指定要修改的顶点属性的索引值,例如
         size, 每次读取数量。（如position是由3个（x,y,z）组成，而颜色是4个（r,g,b,a）,纹理则是2个.）
         type,指定数组中每个组件的数据类型。可用的符号常量有GL_BYTE, GL_UNSIGNED_BYTE, GL_SHORT,GL_UNSIGNED_SHORT, GL_FIXED, 和 GL_FLOAT，初始值为GL_FLOAT。
         normalized,指定当被访问时，固定点数据值是否应该被归一化（GL_TRUE）或者直接转换为固定点值（GL_FALSE）
         stride,指定连续顶点属性之间的偏移量。如果为0，那么顶点属性会被理解为：它们是紧密排列在一起的。初始值为0
         ptr指定一个指针，指向数组中第一个顶点属性的第一个组件。初始值为0
      */
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(float)*5, (GLfloat*)NULL+0);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(float)*5, (GLfloat*)NULL+3);
    
}

-(void)setUpTexture {
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"huhu" ofType:@"jpg"];
    GLKTextureInfo *textInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:@{GLKTextureLoaderOriginBottomLeft:@(1)} error:nil];
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.texture2d0.enabled = YES;
    self.baseEffect.texture2d0.name = textInfo.name;
    self.baseEffect.texture2d0.target = textInfo.target;
    
    
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    
    [self.baseEffect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
}
- (void)glkViewControllerUpdate:(GLKViewController *)controller {
    static float angle = 0;
    angle +=0.1;
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Rotate(GLKMatrix4Identity, angle, 1, 1,0 );
    self.baseEffect.transform.modelviewMatrix = modelViewMatrix;
    [self.baseEffect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 36);

}

@end
