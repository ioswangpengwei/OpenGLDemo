//
//  ViewController.m
//  CombinateVideo
//
//  Created by MacW on 2020/9/3.
//  Copyright © 2020 MacW. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong)AVMutableComposition *composition;

@property (nonatomic, strong) AVMutableAudioMix *myMutableAudioMix;

@property (nonatomic, strong) AVAssetExportSession *exportSession;

@property (nonatomic, strong) NSArray *passThroughTimeRanges;
@property (nonatomic, strong) NSArray *transitionTimeRanges;
@property (nonatomic, strong) AVVideoComposition *videoComposition;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self combinateVideo];
    
}

-(void)combinateVideo {
    dispatch_queue_t queue = dispatch_queue_create("1222", NULL);
    dispatch_async(queue, ^{
        
        self.composition = [AVMutableComposition composition];
        AVAsset *firstVideoAsset = [AVAsset assetWithURL:[[NSBundle mainBundle] URLForResource:@"01_nebula" withExtension:@"mp4"]];
        AVAsset *secondVideoAsset = [AVAsset assetWithURL:[[NSBundle mainBundle] URLForResource:@"03_nebula" withExtension:@"mp4"]];
        AVAsset *thirdVideoAsset = [AVAsset assetWithURL:[[NSBundle mainBundle] URLForResource:@"04_quasar" withExtension:@"mp4"]];
        AVAsset *firstAudioAsset =[AVAsset assetWithURL:[[NSBundle mainBundle] URLForResource:@"02 Keep Going" withExtension:@"m4a"]];
        AVMutableCompositionTrack *videoTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
         AVMutableCompositionTrack *videoTrack2 = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        AVMutableCompositionTrack *audioTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        NSArray *videoAssets = @[firstVideoAsset,secondVideoAsset,thirdVideoAsset];
        NSArray *videoTracks = @[videoTrack,videoTrack2];
        CMTime cursorTime = kCMTimeZero;
        for (int i = 0; i< videoAssets.count; i++) {
            NSUInteger trackIndex = i % 2;
            AVMutableCompositionTrack *currentTrack = videoTracks[trackIndex];
            AVAsset *asset = videoAssets[i];
            AVAssetTrack *assetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
            CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
            [currentTrack insertTimeRange:timeRange ofTrack:assetTrack atTime:cursorTime error:nil];
            cursorTime = CMTimeAdd(cursorTime, timeRange.duration);
            cursorTime = CMTimeSubtract(cursorTime, CMTimeMake(2, 1));
            
        }
        
        NSError *error;
        AVAssetTrack *assetTrack =[[firstAudioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(26, 1)) ofTrack:assetTrack atTime:kCMTimeZero error:&error];
        
        AVMutableAudioMixInputParameters *audioMixInputParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
        [audioMixInputParameters setVolumeRampFromStartVolume:0.0 toEndVolume:0.5 timeRange:CMTimeRangeMake(CMTimeMake(0, 1), CMTimeMake(5, 1))];
           [audioMixInputParameters setVolumeRampFromStartVolume:0.5 toEndVolume:0.0 timeRange:CMTimeRangeMake(CMTimeMake(5, 1), CMTimeMake(25, 1))];

        self.myMutableAudioMix = [AVMutableAudioMix audioMix];
        self.myMutableAudioMix.inputParameters = @[audioMixInputParameters];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self videoCompo:videoAssets];

            [self playe];
            [self save];
        });
        
        
    });
    
}
- (void)videoCompo:(NSArray *)assets {
    
    CMTime cursorTime = kCMTimeZero;
    CMTime transDuration = CMTimeMake(2, 1);
    NSMutableArray *passThroughTimeRanges = [NSMutableArray array];
    NSMutableArray *transitionTimeRanges= [NSMutableArray array];
    NSInteger videoCount = assets.count;
    for (int i = 0; i < videoCount; i++) {
        AVAsset *asset = assets[i];
        CMTimeRange timeRange = CMTimeRangeMake(cursorTime, asset.duration);
        if (i > 0) {
            timeRange.start = CMTimeAdd(timeRange.start, transDuration);
            timeRange.duration = CMTimeSubtract(timeRange.duration, transDuration);
        }
        if (i+1 < videoCount) {
            timeRange.duration = CMTimeSubtract(timeRange.duration, transDuration);
        }
        [passThroughTimeRanges addObject:[NSValue valueWithCMTimeRange:timeRange]];
        cursorTime = CMTimeAdd(cursorTime, asset.duration);
        cursorTime = CMTimeSubtract(cursorTime, transDuration);
        if (i + 1 <videoCount) {
            timeRange = CMTimeRangeMake(cursorTime, transDuration);
            [transitionTimeRanges addObject:[NSValue valueWithCMTimeRange:timeRange]];
        }
    }
    self.passThroughTimeRanges = passThroughTimeRanges;
    self.transitionTimeRanges = transitionTimeRanges;
    self.videoComposition = [self buildVideoCompositionAndInstructions];
    
    
}

- (AVMutableVideoComposition *)buildVideoCompositionAndInstructions {

NSMutableArray *compositionInstructions = [NSMutableArray array];

// Look up all of the video tracks in the composition
NSArray *tracks = [self.composition tracksWithMediaType:AVMediaTypeVideo];

for (NSUInteger i = 0; i < self.passThroughTimeRanges.count; i++) {         // 1

    // Calculate the trackIndex to operate upon: 0, 1, 0, 1, etc.
    NSUInteger trackIndex = i % 2;

    AVMutableCompositionTrack *currentTrack = tracks[trackIndex];

    AVMutableVideoCompositionInstruction *instruction =                     // 2
        [AVMutableVideoCompositionInstruction videoCompositionInstruction];

    instruction.timeRange =                                                 // 3
        [self.passThroughTimeRanges[i] CMTimeRangeValue];

    AVMutableVideoCompositionLayerInstruction *layerInstruction =           // 4
        [AVMutableVideoCompositionLayerInstruction
            videoCompositionLayerInstructionWithAssetTrack:currentTrack];

    instruction.layerInstructions = @[layerInstruction];

    [compositionInstructions addObject:instruction];

    if (i < self.transitionTimeRanges.count) {

        AVCompositionTrack *foregroundTrack = tracks[trackIndex];           // 5
        AVCompositionTrack *backgroundTrack = tracks[1 - trackIndex];

        AVMutableVideoCompositionInstruction *instruction =                 // 6
            [AVMutableVideoCompositionInstruction videoCompositionInstruction];

        CMTimeRange timeRange = [self.transitionTimeRanges[i] CMTimeRangeValue];
        instruction.timeRange = timeRange;

        AVMutableVideoCompositionLayerInstruction *fromLayerInstruction =   // 7
            [AVMutableVideoCompositionLayerInstruction
                videoCompositionLayerInstructionWithAssetTrack:foregroundTrack];
        //溶解过渡效果
//        [fromLayerInstruction setOpacityRampFromStartOpacity:1.0 toEndOpacity:0.0 timeRange:timeRange];
        AVMutableVideoCompositionLayerInstruction *toLayerInstruction =
            [AVMutableVideoCompositionLayerInstruction
                videoCompositionLayerInstructionWithAssetTrack:backgroundTrack];


        //擦除
        if(i %2 == 0){
            CGRect startRect = CGRectMake(0, 0, 1280.0f, 720.0f);
            CGRect endRect = CGRectMake(0, 720, 1280.0f, 0.0f);
            [fromLayerInstruction setCropRectangleRampFromStartCropRectangle:startRect toEndCropRectangle:endRect timeRange:timeRange];

        }else {
            //推入过滤效果
            CGAffineTransform identityTransform = CGAffineTransformIdentity;


                CGAffineTransform fromDestTransform =
                             CGAffineTransformMakeTranslation(-1280.0f, 0.0);

            CGAffineTransform toStartTransform =
                             CGAffineTransformMakeTranslation(1280.0f, 0.0);

            [fromLayerInstruction setTransformRampFromStartTransform:identityTransform
                                                        toEndTransform:fromDestTransform
                                                             timeRange:timeRange];

            [toLayerInstruction setTransformRampFromStartTransform:toStartTransform
                                                      toEndTransform:identityTransform
                                                           timeRange:timeRange];
        }
         
        
        
        instruction.layerInstructions = @[fromLayerInstruction,             // 8
                                          toLayerInstruction];

        [compositionInstructions addObject:instruction];
    }

}
    AVMutableVideoComposition *videoComposition =
        [AVMutableVideoComposition videoComposition];

    videoComposition.instructions = compositionInstructions;
    videoComposition.renderSize = CGSizeMake(1280.0f, 720.0f);
    videoComposition.frameDuration = CMTimeMake(1, 30);
    videoComposition.renderScale = 1.0f;

        return videoComposition;
    
}

-(void)playe {
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithAsset:[self.composition copy]];
    item.audioMix = self.myMutableAudioMix;
    item.videoComposition =self.videoComposition;
//    [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:self.composition];
    AVPlayerViewController *playerVC = [[AVPlayerViewController alloc] init];
    //创建AVPlayer
    AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:item];
        
    //将Player赋值给AVPlayerViewController
    playerVC.player = player;

    [self presentViewController:playerVC animated:YES completion:nil];
    
}
-(void)save {
    
  NSString *preset = AVAssetExportPresetHighestQuality;
    self.exportSession = [AVAssetExportSession exportSessionWithAsset:self.composition presetName:preset];
     self.exportSession.outputURL = [self exportURL];
    self.exportSession.outputFileType = AVFileTypeMPEG4;
    self.exportSession.audioMix = self.myMutableAudioMix;
    self.exportSession.videoComposition = self.videoComposition;

    [self.exportSession exportAsynchronouslyWithCompletionHandler:^{

        dispatch_async(dispatch_get_main_queue(), ^{
            AVAssetExportSessionStatus status = self.exportSession.status;
            if (status == AVAssetExportSessionStatusCompleted) {
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    [PHAssetChangeRequest  creationRequestForAssetFromVideoAtFileURL:self.exportSession.outputURL];

                } completionHandler:^(BOOL success, NSError * _Nullable error) {
                    if (success) {
                        NSLog(@"成功");
                    }else {
                        NSLog(@"失败");
                    }
                    
                }];
                
            }
        });
    }];
    
    
}
- (NSURL *)exportURL {
    NSString *filePath = nil;
    NSUInteger count = 0;
    do {
        filePath = NSTemporaryDirectory();
        NSString *numberString = count > 0 ?
            [NSString stringWithFormat:@"-%li", (unsigned long) count] : @"";
        NSString *fileNameString =
            [NSString stringWithFormat:@"Masterpiece-%@.m4v", numberString];
        filePath = [filePath stringByAppendingPathComponent:fileNameString];
        count++;
    } while ([[NSFileManager defaultManager] fileExistsAtPath:filePath]);

    return [NSURL fileURLWithPath:filePath];
}

@end
