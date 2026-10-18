@import Cocoa;
#import "CommandWorker.h"

@interface PngCrushWorker : CommandWorker {
    BOOL strip, brute;
}

- (instancetype)initWithLevel:(NSInteger)level defaults:(NSUserDefaults *)defaults file:(Job *)aFile;
@property (readonly) BOOL makesNonOptimizingModifications;

@end
