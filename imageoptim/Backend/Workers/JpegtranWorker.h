@import Cocoa;
#import "CommandWorker.h"

@interface JpegtranWorker : CommandWorker {
    BOOL strip;
}

- (instancetype)initWithDefaults:(NSUserDefaults *)defaults file:(Job *)aFile;
@end
