
#include "GLShaderManager.h"
/*
 `#include<GLShaderManager.h>` 移入了GLTool 着色器管理器（shader Mananger）类。没有着色器，我们就不能在OpenGL（核心框架）进行着色。着色器管理器不仅允许我们创建并管理着色器，还提供一组“存储着色器”，他们能够进行一些初步䄦基本的渲染操作。
 */

#include "GLTools.h"
#include "GLMatrixStack.h"
#include "GLGeometryTransform.h"
#include "GLFrustum.h"

/*
 `#include<GLTools.h>`  GLTool.h头文件包含了大部分GLTool中类似C语言的独立函数
*/

 
#include <GLUT/GLUT.h>
/*
 在Mac 系统下，`#include<glut/glut.h>`
 在Windows 和 Linux上，我们使用freeglut的静态库版本并且需要添加一个宏
*/

//定义一个，着色管理器
GLShaderManager shaderManager;
GLGeometryTransform transformPipeline;
GLFrustum viewFrustum;

GLMatrixStack pMatrixStack;
GLMatrixStack modelViewMatrixStack;

//简单的批次容器，是GLTools的一个简单的容器类。
GLBatch floorBatch;
GLBatch leftWallBatch;
GLBatch rightWallBatch;
GLBatch ceilingBatch;

// 纹理标识符号
#define TEXTURE_BRICK   0 //墙面
#define TEXTURE_FLOOR   1 //地板
#define TEXTURE_CEILING 2 //纹理天花板
#define TEXTURE_COUNT   3 //纹理个数

GLuint  textures[TEXTURE_COUNT];//纹理标记数组
GLfloat viewZ = -65.f;
//文件tag名字数组
const char *szTextureFiles[TEXTURE_COUNT] = { "brick.tga", "stone.tga", "ceiling.tga" };

/*
 在窗口大小改变时，接收新的宽度&高度。
 */
void changeSize(int w,int h)
{
    /*
      x,y 参数代表窗口中视图的左下角坐标，而宽度、高度是像素为表示，通常x,y 都是为0
     */
    glViewport(0, 0, w, h);
    
    viewFrustum.SetPerspective(45, floorf(w)/floorf(h), 1, 200);
    pMatrixStack.LoadMatrix(viewFrustum.GetProjectionMatrix());
    transformPipeline.SetMatrixStacks(modelViewMatrixStack, pMatrixStack);
    
}

void RenderScene(void)
{

    //1.清除一个或者一组特定的缓存区
    /*
     缓冲区是一块存在图像信息的储存空间，红色、绿色、蓝色和alpha分量通常一起分量通常一起作为颜色缓存区或像素缓存区引用。
     OpenGL 中不止一种缓冲区（颜色缓存区、深度缓存区和模板缓存区）
      清除缓存区对数值进行预置
     参数：指定将要清除的缓存的
     GL_COLOR_BUFFER_BIT :指示当前激活的用来进行颜色写入缓冲区
     GL_DEPTH_BUFFER_BIT :指示深度缓存区
     GL_STENCIL_BUFFER_BIT:指示模板缓冲区
     */
    modelViewMatrixStack.PushMatrix();
    modelViewMatrixStack.Translate(0, 0, viewZ);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);
    glBindTexture(GL_TEXTURE_2D, textures[TEXTURE_FLOOR]);
    shaderManager.UseStockShader(GLT_SHADER_TEXTURE_REPLACE, transformPipeline.GetModelViewProjectionMatrix(), 0);
    floorBatch.Draw();
    glBindTexture(GL_TEXTURE_2D, textures[TEXTURE_BRICK]);

    leftWallBatch.Draw();
    rightWallBatch.Draw();
    glBindTexture(GL_TEXTURE_2D, textures[TEXTURE_CEILING]);
    ceilingBatch.Draw();
    
    modelViewMatrixStack.PopMatrix();

    glutSwapBuffers();
    
}

void setupRC()
{
    //设置清屏颜色（背景颜色）
    glClearColor(0.f, 0.0f, 0.0f, 1);
    
    
    //没有着色器，在OpenGL 核心框架中是无法进行任何渲染的。初始化一个渲染管理器。
    //在前面的课程，我们会采用固管线渲染，后面会学着用OpenGL着色语言来写着色器
    shaderManager.InitializeStockShaders();
    glGenTextures(TEXTURE_COUNT, textures);
    
    for (int i = 0; i < TEXTURE_COUNT; i++) {
        glBindTexture(GL_TEXTURE_2D, textures[i]);
        GLint iWidth,iheight,iComponents;
        GLenum eFormat;
        GLbyte *pBytes;
        pBytes = gltReadTGABits(szTextureFiles[i], &iWidth, &iheight, &iComponents, &eFormat);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        
        glTexImage2D(GL_TEXTURE_2D, 0, iComponents, iWidth, iheight, 0, eFormat, GL_UNSIGNED_BYTE, pBytes);
        
        glGenerateMipmap(GL_TEXTURE_2D);
        free(pBytes);
    }
      GLfloat z;
        
        /*
         GLTools库中的容器类，GBatch，
         void GLBatch::Begin(GLenum primitive,GLuint nVerts,GLuint nTextureUnits = 0);
         参数1：图元枚举值
         参数2：顶点数
         参数3：1组或者2组纹理坐标
         */
        
        floorBatch.Begin(GL_TRIANGLE_STRIP, 28, 1);
        //参考PPT图6-10
        //Z表示深度，隧道的深度
        for(z = 60.0f; z >= 0.0f; z -=10.0f)
        {
            floorBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
            floorBatch.Vertex3f(-10.0f, -10.0f, z);
            
            floorBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
            floorBatch.Vertex3f(10.0f, -10.0f, z);
            
            floorBatch.MultiTexCoord2f(0, 0.0f, 1.0f);
            floorBatch.Vertex3f(-10.0f, -10.0f, z - 10.0f);
            
            floorBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
            floorBatch.Vertex3f(10.0f, -10.0f, z - 10.0f);
        }
        floorBatch.End();
       
       //参考PPT图6-11
    ceilingBatch.Begin(GL_TRIANGLE_STRIP, 28, 1);
        for(z = 60.0f; z >= 0.0f; z -=10.0f)
        {
            ceilingBatch.MultiTexCoord2f(0, 1, 1);
            ceilingBatch.Vertex3f(-10.0f, 10.0f, z - 10.0f);
            
            ceilingBatch.MultiTexCoord2f(0, 0, 1);

            ceilingBatch.Vertex3f(10.0f, 10.0f, z - 10.0f);
            
            ceilingBatch.MultiTexCoord2f(0, 1, 0);

            ceilingBatch.Vertex3f(-10.0f, 10.0f, z);
            
            ceilingBatch.MultiTexCoord2f(0, 0, 0);

            ceilingBatch.Vertex3f(10.0f, 10.0f, z);
        }
        ceilingBatch.End();
        
        //参考PPT图6-12
        leftWallBatch.Begin(GL_TRIANGLE_STRIP, 28, 1);
        for(z = 60.0f; z >= 0.0f; z -=10.0f)
        {
            leftWallBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
            leftWallBatch.Vertex3f(-10.0f, -10.0f, z);
            
            leftWallBatch.MultiTexCoord2f(0, 0.0f, 1.0f);
            leftWallBatch.Vertex3f(-10.0f, 10.0f, z);
            
            leftWallBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
            leftWallBatch.Vertex3f(-10.0f, -10.0f, z - 10.0f);
            
            leftWallBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
            leftWallBatch.Vertex3f(-10.0f, 10.0f, z - 10.0f);
        }
        leftWallBatch.End();
       
       //参考PPT图6-13
        rightWallBatch.Begin(GL_TRIANGLE_STRIP, 28, 1);
        for(z = 60.0f; z >= 0.0f; z -=10.0f)
        {
            rightWallBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
            rightWallBatch.Vertex3f(10.0f, -10.0f, z);
            
            rightWallBatch.MultiTexCoord2f(0, 0.0f, 1.0f);
            rightWallBatch.Vertex3f(10.0f, 10.0f, z);
            
            rightWallBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
            rightWallBatch.Vertex3f(10.0f, -10.0f, z - 10.0f);
            
            rightWallBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
            rightWallBatch.Vertex3f(10.0f, 10.0f, z - 10.0f);
        }
        rightWallBatch.End();
    
}
void ProcessMenu(int value)
{
    
}
void SpecialKeys(int key, int x, int y)
{
    if(key == GLUT_KEY_UP)
        //移动的是深度值，Z
        viewZ += 0.5f;
    
    if(key == GLUT_KEY_DOWN)
        viewZ -= 0.5f;
    
    //更新窗口，即可回调到RenderScene函数里
    glutPostRedisplay();
}

int main(int argc,char *argv[])
{

    //初始化GLUT库,这个函数只是传说命令参数并且初始化glut库
    glutInit(&argc, argv);
    
    /*
     初始化双缓冲窗口，其中标志GLUT_DOUBLE、GLUT_RGBA、GLUT_DEPTH、GLUT_STENCIL分别指
     双缓冲窗口、RGBA颜色模式、深度测试、模板缓冲区
     
     --GLUT_DOUBLE`：双缓存窗口，是指绘图命令实际上是离屏缓存区执行的，然后迅速转换成窗口视图，这种方式，经常用来生成动画效果；
     --GLUT_DEPTH`：标志将一个深度缓存区分配为显示的一部分，因此我们能够执行深度测试；
     --GLUT_STENCIL`：确保我们也会有一个可用的模板缓存区。
     深度、模板测试后面会细致讲到
     */
    glutInitDisplayMode(GLUT_DOUBLE|GLUT_RGBA|GLUT_DEPTH|GLUT_STENCIL);
    
    //GLUT窗口大小、窗口标题
    glutInitWindowSize(800, 600);
    glutCreateWindow("Triangle");
    
    /*
     GLUT 内部运行一个本地消息循环，拦截适当的消息。然后调用我们不同时间注册的回调函数。我们一共注册2个回调函数：
     1）为窗口改变大小而设置的一个回调函数
     2）包含OpenGL 渲染的回调函数
     */
    //注册重塑函数
    glutReshapeFunc(changeSize);
    //注册显示函数
    glutDisplayFunc(RenderScene);
    glutSpecialFunc(SpecialKeys);
    glutCreateMenu(ProcessMenu);

    /*
     初始化一个GLEW库,确保OpenGL API对程序完全可用。
     在试图做任何渲染之前，要检查确定驱动程序的初始化过程中没有任何问题
     */
    GLenum status = glewInit();
    if (GLEW_OK != status) {
        
        printf("GLEW Error:%s\n",glewGetErrorString(status));
        return 1;
        
    }
    
    //设置我们的渲染环境
    setupRC();
    glutMainLoop();
 
    return  0;
    
}
