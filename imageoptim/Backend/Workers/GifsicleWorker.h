@import Cocoa;
#import "CommandWorker.h"

@interface GifsicleWorker : CommandWorker {
    NSUInteger quality;
    BOOL interlace;
}

- (instancetype)initWithInterlace:(BOOL)yn quality:(NSUInteger)quality file:(Job *)aFile;
@end
