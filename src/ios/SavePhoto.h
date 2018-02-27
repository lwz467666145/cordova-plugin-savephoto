#import <Cordova/CDVPlugin.h>

@interface SavePhoto : CDVPlugin

@property (nonatomic, copy) NSString *callbackId;

- (void)save:(CDVInvokedUrlCommand*)command;

@end
