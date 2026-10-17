#import "TempFile.h"

@implementation TempFile

- (void)dealloc {
    NSURL *path = self.path;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
      [[NSFileManager defaultManager] removeItemAtURL:path error:nil];
    });
}

@end
