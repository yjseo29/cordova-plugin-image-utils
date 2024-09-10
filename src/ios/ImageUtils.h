#import <Cordova/CDVPlugin.h>
@interface ImageUtils : CDVPlugin

- (void)getExifForKey:(CDVInvokedUrlCommand *)command;
- (void)extractThumbnail:(CDVInvokedUrlCommand *)command;
- (void)compressImage:(CDVInvokedUrlCommand *)command;
- (void)getFileInfo:(CDVInvokedUrlCommand *)command;

@end