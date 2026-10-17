@import Cocoa;
#import "CommandWorker.h"

@interface JpegoptimWorker : CommandWorker {
    NSInteger maxquality;
    NSInteger fileSizeOptimized;
    BOOL strip;
}

- (instancetype)initWithDefaults:(NSUserDefaults *)defaults file:(Job *)aFile;
@end
