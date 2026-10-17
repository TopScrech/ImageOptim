@import Cocoa;
#import "CommandWorker.h"

@interface OxiPngWorker : CommandWorker {
    NSInteger optlevel;
    BOOL strip;
}

- (instancetype)initWithLevel:(NSInteger)level stripMetadata:(BOOL)aStrip file:(Job *)aFile;
@end
