
#import <Foundation/Foundation.h>

@class Job;

NS_ASSUME_NONNULL_BEGIN
@interface JobQueue : NSObject

- (void)addJob:(Job *)f;
- (void)wait;
- (void)cleanup;
- (NSNumber *)queueCount;
@property (assign, atomic) BOOL isBusy;

- (nullable instancetype)initWithCPUs:(NSInteger)cpus files:(NSInteger)fileops defaults:(NSUserDefaults *)defaults;
@end
NS_ASSUME_NONNULL_END
