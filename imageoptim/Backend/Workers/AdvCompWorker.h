@import Cocoa;
#import "CommandWorker.h"

@interface AdvCompWorker : CommandWorker {
    NSInteger level;

    NSInteger fileSizeOptimized;
}

- (instancetype)initWithLevel:(NSInteger)opt file:(Job *)aFile;
@end
