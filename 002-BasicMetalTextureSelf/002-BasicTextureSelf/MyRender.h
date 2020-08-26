//
//  MyRender.h
//  002-BasicTextureSelf
//
//  Created by MacW on 2020/8/25.
//  Copyright © 2020 MacW. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MetalKit;
NS_ASSUME_NONNULL_BEGIN

@interface MyRender : NSObject<MTKViewDelegate>
-(instancetype)initWithView:(MTKView *)view;
@end

NS_ASSUME_NONNULL_END
