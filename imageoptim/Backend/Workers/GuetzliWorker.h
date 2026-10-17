#ifndef GuetzliWorker_h
#define GuetzliWorker_h

@import Cocoa;
#import "CommandWorker.h"

@interface GuetzliWorker : CommandWorker {
    NSInteger level;
    dispatch_queue_t queue;
}

- (instancetype)initWithDefaults:(NSUserDefaults *)defaults serialQueue:(dispatch_queue_t)q file:(Job *)aFile;
@end

#endif /* GuetzliWorker_h */
