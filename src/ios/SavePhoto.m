#import "SavePhoto.h"
#import <Cordova/CDV.h>
#import <Photos/Photos.h>
#import <Photos/PHPhotoLibrary.h>

@interface SavePhoto ()

@property (nonatomic, copy) NSString *plistName;
@property (nonatomic, copy) NSString *folderName;
@property (nonatomic, copy) NSString *savePath;

@end

@implementation SavePhoto

- (void)save:(CDVInvokedUrlCommand *)command{
    NSDictionary *plistDic = [[NSBundle mainBundle] infoDictionary];
    self.callbackId = command.callbackId;
    self.plistName = @"Asset";
    self.folderName = [[plistDic objectForKey:@"SavePhoto"] objectForKey:@"FLODER_NAME"];
    self.savePath = command.arguments[0];
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status == PHAuthorizationStatusRestricted || status == PHAuthorizationStatusDenied) {
                CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Authorized Failed"];
                [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
            } else if (status == PHAuthorizationStatusAuthorized) {
                [self createFolder:self.folderName];
            }
        });
    }];
}

- (void)saveImagePath:(NSString *)imagePath{
    __block NSString *localIdentifier;
    PHFetchResult *collectonResuts = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    [collectonResuts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        PHAssetCollection *assetCollection = obj;
        if ([assetCollection.localizedTitle isEqualToString:_folderName])  {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                UIImage *myImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imagePath]]];
                PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:myImage];
                PHAssetCollectionChangeRequest *collectonRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
                PHObjectPlaceholder *placeHolder = [assetRequest placeholderForCreatedAsset];
                [collectonRequest addAssets:@[placeHolder]];
                localIdentifier = placeHolder.localIdentifier;
            } completionHandler:^(BOOL success, NSError *error) {
                if (success) {
                    NSLog(@"Save Photo Success");
                    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[self readFromPlist]];
                    [dict setObject:localIdentifier forKey:[self showFileNameFromPath:imagePath]];
                    [self writeDicToPlist:dict];
                    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
                } else {
                    NSLog(@"Save Photo Error: %@", error);
                    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
                    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
                }
            }];
        }
    }];
}

- (void)createFolder:(NSString *)folderName {
    if (![self isExistFolder:folderName]) {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:folderName];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                NSLog(@"Create Folder Success");
                [self createPlist: self.plistName];
            } else {
                NSLog(@"Create Folder Error: %@", error);
                CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
                [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
            }
        }];
    } else {
        NSLog(@"Folder Already Exist");
        [self createPlist: self.plistName];
    }
}

- (BOOL)isExistFolder:(NSString *)folderName {
    PHFetchResult *collectonResuts = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    __block BOOL isExisted = NO;
    [collectonResuts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        PHAssetCollection *assetCollection = obj;
        if ([assetCollection.localizedTitle isEqualToString:folderName])
            isExisted = YES;
    }];
    return isExisted;
}

- (void)createPlist:(NSString *)plistName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filePath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", plistName]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSLog(@"PList Path: %@", filePath);
    if (![fileManager fileExistsAtPath:filePath]) {
        BOOL success = [fileManager createFileAtPath:filePath contents:nil attributes:nil];
        if (success) {
            NSLog(@"Create PList File Success");
            [self saveImagePath: self.savePath];
        } else {
            NSLog(@"Create PList File Error");
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Create PList File Error"];
            [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
        }
    } else {
        NSLog(@"Plist Already Exist");
        [self saveImagePath: self.savePath];
    }
}

- (void)writeDicToPlist:(NSDictionary *)dict {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filePath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", _plistName]];
    [dict writeToFile:filePath atomically:YES];
}

- (NSDictionary *)readFromPlist {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filePath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", _plistName]];
    return [NSDictionary dictionaryWithContentsOfFile:filePath];
}

- (NSString *)showFileNameFromPath:(NSString *)path {
    return [NSString stringWithFormat:@"%@", [[path componentsSeparatedByString:@"/"] lastObject]];
}

@end
