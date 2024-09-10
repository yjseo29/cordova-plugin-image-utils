#import "ImageUtils.h"
#import <Cordova/CDVPlugin.h>

@interface ImageUtils(){
    NSString* callbackId;
}
@end

@implementation ImageUtils

- (void)getExifForKey:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        @try{
            self->callbackId=command.callbackId;
            NSString *path= [command.arguments objectAtIndex: 0];
            NSString *key  = [command.arguments objectAtIndex: 1];

            NSData *imageData = [NSData dataWithContentsOfFile:path];
            CGImageSourceRef imageRef=CGImageSourceCreateWithData((CFDataRef)imageData, NULL);

            CFDictionaryRef imageInfo = CGImageSourceCopyPropertiesAtIndex(imageRef, 0,NULL);

            NSDictionary  *nsdic = (__bridge_transfer  NSDictionary*)imageInfo;
            NSString* orientation=[nsdic objectForKey:key];

            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:orientation] callbackId:self->callbackId];
        }@catch (NSException *exception) {
            NSLog(@"Exception: %@", exception);
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"error getExifForKey"] callbackId:self->callbackId];
        }
    }];
}


-(UIImage*)getThumbnailImage:(NSString*)path{
    return [[UIImage alloc] initWithContentsOfFile:path];
}

-(NSString*)thumbnailImage:(UIImage*)result quality:(NSInteger)quality width:(NSInteger)width height:(NSInteger)height{
    NSInteger qu = quality>0?quality:3;
    CGFloat q=qu/100.0f;

    float resizeWidth = width;
    float resizeHeight = result.size.height * (width / result.size.width);
    CGSize size = CGSizeMake(resizeWidth, resizeHeight);

    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    [result drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    NSString *thumbnail = [UIImageJPEGRepresentation(resizedImage, q) base64EncodedStringWithOptions:0];
    return thumbnail;
}

- (void)extractThumbnail:(CDVInvokedUrlCommand*)command
{
    callbackId=command.callbackId;
    NSMutableDictionary *options = [command.arguments objectAtIndex: 0];

    [self.commandDelegate runInBackground:^{
        @try {
            UIImage * image=[self getThumbnailImage:[options objectForKey:@"path"]];
            NSString *thumbnail=[self thumbnailImage:image quality:[[options objectForKey:@"thumbnailQuality"] integerValue] width:[[options objectForKey:@"thumbnailW"] integerValue] height:[[options objectForKey:@"thumbnailH"] integerValue]];

            [options setObject:thumbnail forKey:@"thumbnailBase64"];
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:options] callbackId:self->callbackId];
        } @catch (NSException *exception) {
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"error extractThumbnail"] callbackId:self->callbackId];
        }
    }];
}

- (void)compressImage:(CDVInvokedUrlCommand*)command
{
    callbackId=command.callbackId;
    NSMutableDictionary *options = [command.arguments objectAtIndex: 0];

    [self.commandDelegate runInBackground:^{
        @try {
            NSInteger quality=[[options objectForKey:@"quality"] integerValue];
            if(quality<100&&[@"image" isEqualToString: [options objectForKey:@"mediaType"]]){
                UIImage *result = [[UIImage alloc] initWithContentsOfFile: [options objectForKey:@"path"]];
                NSInteger qu = quality>0?quality:3;
                CGFloat q=qu/100.0f;
                NSData *data =UIImageJPEGRepresentation(result,q);
                NSString *compressImagePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"compressImage"];
                NSFileManager *fileManager = [NSFileManager defaultManager];
                if(![fileManager fileExistsAtPath:compressImagePath ]){
                   [fileManager createDirectoryAtPath:compressImagePath withIntermediateDirectories:YES attributes:nil error:nil];
                }
                NSString *filename=[NSString stringWithFormat:@"%@%@%@",@"compressImage_", [self currentTimeStr],@".jpg"];
                NSString *fullpath=[NSString stringWithFormat:@"%@/%@", compressImagePath,filename];
                NSNumber* size=[NSNumber numberWithLong: data.length];
                NSError *error = nil;
                if (![data writeToFile:fullpath options:NSAtomicWrite error:&error]) {
                    NSLog(@"%@", [error localizedDescription]);
                    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]] callbackId:self->callbackId];
                } else {
                    [options setObject:fullpath forKey:@"path"];
                    [options setObject:[[NSURL fileURLWithPath:fullpath] absoluteString] forKey:@"uri"];
                    [options setObject:size forKey:@"size"];
                    [options setObject:filename forKey:@"name"];
                    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:options] callbackId:self->callbackId];
                }

            }else{
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:options] callbackId:self->callbackId];
            }
        } @catch (NSException *exception) {
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"error compressImage"] callbackId:self->callbackId];
        }
    }];
}

- (NSString *)currentTimeStr{
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval time=[date timeIntervalSince1970]*1000;
    NSString *timeString = [NSString stringWithFormat:@"%.0f", time];
    return timeString;
}

- (void)getFileInfo:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        @try{
            self->callbackId=command.callbackId;
            NSString *type= [command.arguments objectAtIndex: 1];
            NSURL *url;
            NSString *path;
            if([type isEqualToString:@"uri"]){
                NSString *str=[command.arguments objectAtIndex: 0];
                url = [NSURL URLWithString:str];
                path= url.path;
            }else{
                path= [command.arguments objectAtIndex: 0];
                url =  [NSURL fileURLWithPath:path];
            }
            NSMutableDictionary *options = [NSMutableDictionary dictionaryWithCapacity:5];
            [options setObject:path forKey:@"path"];
            [options setObject:url.absoluteString forKey:@"uri"];

            NSNumber * size = [NSNumber numberWithUnsignedLongLong:[[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize]];
            [options setObject:size forKey:@"size"];
            NSString *fileName = [[NSFileManager defaultManager] displayNameAtPath:path];
            [options setObject:fileName forKey:@"name"];
            if([[self getMIMETypeURLRequestAtPath:path] containsString:@"video"]){
                [options setObject:@"video" forKey:@"mediaType"];
            }else{
                [options setObject:@"image" forKey:@"mediaType"];
            }
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:options] callbackId:self->callbackId];
        }@catch (NSException *exception) {
            NSLog(@"Exception: %@", exception);
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"error getFileInfo"] callbackId:self->callbackId];
        }
    }];
}


-(NSString *)getMIMETypeURLRequestAtPath:(NSString*)path
{
    NSURL *url = [NSURL fileURLWithPath:path];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    NSHTTPURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];

    NSString *mimeType = response.MIMEType;
    return mimeType;
}

@end
