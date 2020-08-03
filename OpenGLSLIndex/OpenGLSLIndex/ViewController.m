//
//  ViewController.m
//  OpenGLSLIndex
//
//  Created by MacW on 2020/8/2.
//  Copyright © 2020 MacW. All rights reserved.
//

#import "ViewController.h"
#import "MyView.h"

@interface ViewController ()

@property (nonatomic ,strong)MyView *myView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.myView = (MyView *)self.view;
}


@end
