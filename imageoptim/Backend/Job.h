@import Cocoa;
#import "Workers/Worker.h"

@class ResultsDb, File, TempFile;

NS_ASSUME_NONNULL_BEGIN
@interface Job : NSObject {
    NSURL *filePath;
    NSString *displayName;

    NSString *bestToolName;
    NSMutableDictionary *bestTools;

    NSString *statusText;

    NSMutableArray *workers;
    NSMutableDictionary *workersPreviousResults;

    NSOperationQueue *fileIOQueue;
    ResultsDb *db;
    uint32_t settingsHash[4];
    uint32_t inputFileHash[4];

    BOOL stopping, lossyConverted;
}

@property (readonly) BOOL isBusy, isStoppable, isOptimized;

- (BOOL)stop;
- (BOOL)revert;

@property (readonly) BOOL canRevert;
@property (readonly) BOOL isDone, isFailed;

- (void)enqueueWorkersInCPUQueue:(NSOperationQueue *)queue fileIOQueue:(NSOperationQueue *)fileIOQueue serialQueue:(dispatch_queue_t)serialQueue defaults:(NSUserDefaults *)defaults;

- (BOOL)setFileOptimized:(nullable TempFile *)f toolName:(NSString *)s;

- (nullable instancetype)initWithFilePath:(NSURL *)aPath resultsDatabase:(nullable ResultsDb *)aDb;
- (void)updateStatusOfWorker:(nullable Worker *)currentWorker running:(BOOL)started;

- (void)setFilePath:(NSURL *)s;

@property (readonly, nullable) File *initialInput, *unoptimizedInput, *wipInput, *savedOutput, *revertFile;
@property (readonly, copy) NSString *fileName;

@property (strong, nullable) NSString *statusText, *bestToolName;
@property (strong) NSString *displayName;
@property (strong, nonatomic) NSURL *filePath;
@property (readonly, nonatomic, nullable) NSNumber *byteSizeOriginal;
@property (readonly, nonatomic, nullable) NSNumber *byteSizeOptimized;
@property (strong, readonly) NSMutableDictionary *workersPreviousResults;

- (void)setStatus:(NSString *)name text:(NSString *)text;
- (void)setError:(NSString *)text;
- (void)cleanup;

- (void)doEnqueueWorkersInCPUQueue:(NSOperationQueue *)queue serialQueue:(dispatch_queue_t)serialQueue defaults:(NSUserDefaults *)defaults;
@end
NS_ASSUME_NONNULL_END
