#import <Foundation/Foundation.h>
#import <SSZipArchive/SSZipArchive.h>
#import <HBLog.h>

#import <dlfcn.h>
#import <libSandy.h>
#import <libSandyXpc.h>

#import "LSApplicationProxy.h"
#import "LSRecordPromise.h"
#import "MCMContainer.h"

#define TAG "[XcodeAnyTroll] "

static NSString *gPackageIdentifier = nil;
static NSString *gPackagePath = nil;

static SandyXpcMessagingCenter *GetXpcMessagingCenter(void) {
    static SandyXpcMessagingCenter *messagingCenter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        messagingCenter = [SandyXpcMessagingCenter centerNamed:@"com.82flex.xcodeanytroll"];
    });
    return messagingCenter;
}

#import <Foundation/Foundation.h>

struct BlockDescriptor {
    unsigned long reserved;
    unsigned long size;
    void *rest[1];
};

struct Block {
    void *isa;
    int flags;
    int reserved;
    void *invoke;
    struct BlockDescriptor *descriptor;
};

__used
static const char *BlockSig(id blockObj)
{
    struct Block *block = (__bridge struct Block *)blockObj;
    struct BlockDescriptor *descriptor = block->descriptor;

    int copyDisposeFlag = 1 << 25;
    int signatureFlag = 1 << 30;

    assert(block->flags & signatureFlag);

    int index = 0;
    if (block->flags & copyDisposeFlag)
        index += 2;

    return (const char *)descriptor->rest[index];
}

@interface MIInstallOptions : NSObject

@property (getter=isDeveloperInstall, nonatomic) bool developerInstall;

@end

%hook MICodeSigningVerifier

+ (id)_validateSignatureAndCopyInfoForURL:(NSURL *)url withOptions:(id)options error:(NSError **)errorPtr {
    id result = %orig(url, options, errorPtr);

    if (errorPtr && *errorPtr) {
        NSError *error = *errorPtr;
        if (![[error description] containsString:@"0xe800801c"] && ![[error description] containsString:@"0xe8008001"]) {
            return result;
        }

        // Extract source directory from error description instead of using url.path
        NSString *errorDesc = [error description];
        NSString *sourceDirectory = nil;
        
        // Find path that starts with /var/installd/ and ends with colon
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"/var/installd/[^:]+" options:0 error:nil];
        NSTextCheckingResult *match = [regex firstMatchInString:errorDesc options:0 range:NSMakeRange(0, errorDesc.length)];
        
        if (!match) {
            HBLogDebug(@TAG "Failed to extract source directory from error: %@", errorDesc);
            return result;
        }

        sourceDirectory = [[errorDesc substringWithRange:match.range] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        HBLogDebug(@TAG "Extracted source directory: %@", sourceDirectory);

        // Ensure sourceDirectory is valid
        NSString *infoPlistPath = [sourceDirectory stringByAppendingPathComponent:@"Info.plist"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:infoPlistPath]) {
            HBLogDebug(@TAG "Info.plist not found at path: %@", infoPlistPath);
            return result;
        }

        // Read Info.plist to get package identifier
        NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
        if (!infoPlist) {
            HBLogDebug(@TAG "Failed to read Info.plist at path: %@", infoPlistPath);
            return result;
        }

        gPackageIdentifier = infoPlist[@"CFBundleIdentifier"];
        if (!gPackageIdentifier) {
            HBLogDebug(@TAG "CFBundleIdentifier not found in Info.plist");
            return result;
        }

        HBLogDebug(@TAG "Package identifier extracted: %@", gPackageIdentifier);
        
        NSString *tempDir = NSTemporaryDirectory();
        NSString *workDir = [tempDir stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
        NSString *payloadDir = [workDir stringByAppendingPathComponent:@"Payload"];
        NSString *ipaFileName = [NSString stringWithFormat:@"XcodeAnyTroll_%@.ipa", [[NSUUID UUID] UUIDString]];
        NSString *ipaFilePath = [tempDir stringByAppendingPathComponent:ipaFileName];
        
        // Create directory structure
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager createDirectoryAtPath:payloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        
        // Get app name (last path component)
        NSString *appName = [sourceDirectory lastPathComponent];
        NSString *destAppPath = [payloadDir stringByAppendingPathComponent:appName];
        
        HBLogDebug(@TAG "Starting to copy app to Payload directory: %@", sourceDirectory);
        
        // Copy the app to Payload directory
        NSError *copyError;
        BOOL copySuccess = [fileManager copyItemAtPath:sourceDirectory toPath:destAppPath error:&copyError];
        
        if (!copySuccess) {
            HBLogDebug(@TAG "Failed to copy app to Payload directory: %@", copyError);
        } else {
            HBLogDebug(@TAG "Successfully copied app to Payload directory");
            
            // Create zip file (IPA)
            HBLogDebug(@TAG "Creating IPA file from Payload directory");
            BOOL success = [SSZipArchive createZipFileAtPath:ipaFilePath withContentsOfDirectory:workDir keepParentDirectory:NO compressionLevel:0 password:nil AES:NO progressHandler:nil];
            
            if (success) {
                HBLogDebug(@TAG "Successfully created IPA file: %@", ipaFilePath);
            } else {
                HBLogDebug(@TAG "Failed to create IPA file");
            }
            
            // Clean up temporary directory
            [fileManager removeItemAtPath:workDir error:nil];

            // Assign the IPA file path to the global variable
            gPackagePath = ipaFilePath;
        }
    }

    return result;
}

%end

%hook MIClientConnection

/* iOS 16.4+ */
- (void)_installURL:(NSURL *)url identity:(id)identity targetingDomain:(NSUInteger)domain options:(MIInstallOptions *)options completion:(void (^)(BOOL, NSArray *, id, NSError *))completion {
    HBLogDebug(@TAG "installURL:%@ withOptions:%@", url, options);

    void (^replCompletion)(BOOL, NSArray *, id, NSError *) = ^(BOOL succeed, NSArray *appList, id recordPromise, NSError *error) {
        HBLogDebug(@TAG "completion called with appList:%@ recordPromise:%@ error:%@", appList, recordPromise, error);
        if (!completion) {
            return;
        }

        if (gPackagePath && gPackageIdentifier && ([[error description] containsString:@"0xe800801c"] || [[error description] containsString:@"0xe8008001"])) {
            NSError *error = nil;
            NSDictionary *retVal = nil;

            retVal = [GetXpcMessagingCenter() sendMessageAndReceiveReplyName:@"InstallPackage" userInfo:@{
                @"PackagePath": gPackagePath,
                @"PackageIdentifier": gPackageIdentifier,
            } error:&error];
            if (error) {
                HBLogDebug(@TAG "XPC error occurred: %@", error);
                completion(succeed, appList, recordPromise, error);
                return;
            }

            HBLogDebug(@TAG "XPC reply received: %@", retVal);

            LSApplicationProxy *appProxy = [LSApplicationProxy applicationProxyForIdentifier:gPackageIdentifier];
            LSRecordPromise *recordPromise = [[LSRecordPromise alloc] initWithRecord:appProxy.correspondingApplicationRecord error:nil];

            completion(YES, retVal[@"InstalledAppInfoArray"], recordPromise, nil);
            return;
        }

        completion(succeed, appList, recordPromise, error);
    };

    %orig(url, identity, domain, options, replCompletion);
}

/* iOS 15 */
- (void)installURL:(NSURL *)url withOptions:(NSDictionary *)options completion:(void (^)(id, NSError *))completion {
    HBLogDebug(@TAG "installURL:%@ withOptions:%@", url, options);

    if (![options[@"PackageType"] isEqualToString:@"Developer"]) {
        %orig;
        return;
    }

    void (^replCompletion)(NSDictionary *, NSError *) = ^(NSDictionary *userInfo, NSError *error) {
        HBLogDebug(@TAG "completion called with userInfo:%@ error:%@", [userInfo[@"InstalledAppInfoArray"] firstObject], error);
        if (!completion) {
            return;
        }

        if (gPackagePath && gPackageIdentifier && ([[error description] containsString:@"0xe800801c"] || [[error description] containsString:@"0xe8008001"])) {
            NSError *error = nil;
            NSDictionary *retVal = nil;

            retVal = [GetXpcMessagingCenter() sendMessageAndReceiveReplyName:@"InstallPackage" userInfo:@{
                @"PackagePath": gPackagePath,
                @"PackageIdentifier": gPackageIdentifier,
            } error:&error];
            if (error) {
                HBLogDebug(@TAG "XPC error occurred: %@", error);
                completion(userInfo, error);
                return;
            }

            HBLogDebug(@TAG "XPC reply received: %@", retVal);
            
            completion(retVal, nil);
            return;
        }

        completion(userInfo, error);
    };

    %orig(url, options, replCompletion);
}

%end

#if DEBUG
static void TestConnection(void) {
    SandyXpcMessagingCenter *messagingCenter = GetXpcMessagingCenter();

    NSDictionary *msgBody = @{@"name" : [[NSBundle mainBundle] bundleIdentifier] ?: @"Sandy"};
    [messagingCenter sendMessageName:@"OneWayMessage" userInfo:msgBody];

    NSError *error = nil;
    NSDictionary *retVal = nil;

    retVal = [messagingCenter sendMessageAndReceiveReplyName:@"TwoWayMessage"
                                                    userInfo:msgBody
                                                       error:&error];

    if (error) {
        HBLogDebug(@TAG "Error occurred: %@", error);
        return;
    }

    if (!retVal[@"reply"]) {
        HBLogDebug(@TAG "No reply received");
        return;
    }

    HBLogDebug(@TAG "Received reply: %@", retVal[@"reply"]);
}
#endif

%ctor {
    @autoreleasepool {
        void *sandyHandle = dlopen("@rpath/libsandy.dylib", RTLD_LAZY);
        if (!sandyHandle) {
            sandyHandle = dlopen("/usr/lib/libsandy.dylib", RTLD_LAZY);
        }
        if (!sandyHandle) {
            sandyHandle = dlopen("@loader_path/.jbroot/usr/lib/libsandy.dylib", RTLD_LAZY);
        }
        if (sandyHandle) {
            int (*__dyn_libSandy_applyProfile)(const char *profileName) =
                (int (*)(const char *))dlsym(sandyHandle, "libSandy_applyProfile");
            if (__dyn_libSandy_applyProfile) {
                int sandyStatus = __dyn_libSandy_applyProfile("XcodeAnyTroll");
                if (sandyStatus == kLibSandyErrorXPCFailure) {
                    HBLogDebug(@TAG "Failed to apply profile");
                } else {
                    HBLogDebug(@TAG "Profile applied");
                }
            }
        }

#if DEBUG
        TestConnection();
#endif
    }
}
