extern int hideLogs;
void IOSetHideLogs(int value);

#define IODebug(...) if (!hideLogs) NSLog(@"" __VA_ARGS__);
#define IOWarn(...) NSLog(@"" __VA_ARGS__);
