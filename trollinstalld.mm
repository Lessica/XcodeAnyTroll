#import <Foundation/Foundation.h>
#import <HBLog.h>
#import <errno.h>
#import <spawn.h>
#import <sys/wait.h>

#import <libSandyXpc.h>

#import "LSApplicationProxy.h"
#import "MCMContainer.h"

#define TAG "TrollInstallerService : "

__used static const char *installer_binary(void) {
    static NSString *_binary = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      NSString *bundlePath = nil;
      if (!bundlePath) {
          LSApplicationProxy *appProxy = [LSApplicationProxy applicationProxyForIdentifier:@"com.opa334.TrollStore"];
          bundlePath = [appProxy.bundleURL path];
      }
      if (!bundlePath) {
          LSApplicationProxy *appProxy = [LSApplicationProxy applicationProxyForIdentifier:@"com.opa334.TrollStoreLite"];
          bundlePath = [appProxy.bundleURL path];
      }
      if (!bundlePath) {
          NSString *bundleContainerPath = [[[MCMAppContainer containerWithIdentifier:@"com.opa334.TrollStore"
                                                                               error:nil] url] path];
          NSArray<NSString *> *bundleItems =
              [[NSFileManager defaultManager] contentsOfDirectoryAtPath:bundleContainerPath error:nil];
          for (NSString *bundleItem in bundleItems) {
              if ([[bundleItem pathExtension] isEqualToString:@"app"]) {
                  bundlePath = [bundleContainerPath stringByAppendingPathComponent:bundleItem];
                  break;
              }
          }
      }
      if (!bundlePath) {
          NSString *bundleContainerPath = [[[MCMAppContainer containerWithIdentifier:@"com.opa334.TrollStoreLite"
                                                                               error:nil] url] path];
          NSArray<NSString *> *bundleItems =
              [[NSFileManager defaultManager] contentsOfDirectoryAtPath:bundleContainerPath error:nil];
          for (NSString *bundleItem in bundleItems) {
              if ([[bundleItem pathExtension] isEqualToString:@"app"]) {
                  bundlePath = [bundleContainerPath stringByAppendingPathComponent:bundleItem];
                  break;
              }
          }
      }
      _binary = [bundlePath stringByAppendingPathComponent:@"trollstorehelper"];
    });
    return [_binary fileSystemRepresentation];
}

@interface TrollInstallerService : NSObject
- (void)onOneWayMessage:(NSString *)message userInfo:(NSDictionary *)userInfo;
- (NSDictionary *)onTwoWayMessage:(NSString *)message userInfo:(NSDictionary *)userInfo;
- (NSDictionary *)onRemoteInstallPackage:(NSString *)message userInfo:(NSDictionary *)userInfo;
@end

@implementation TrollInstallerService

- (void)onOneWayMessage:(NSString *)message userInfo:(NSDictionary *)userInfo {
    HBLogDebug(@"Received one-way message %@ from %@", message, userInfo[@"name"]);
}

- (NSDictionary *)onTwoWayMessage:(NSString *)message userInfo:(NSDictionary *)userInfo {
    HBLogDebug(@"Received two-way message %@ from %@", message, userInfo[@"name"]);
    return @{
        @"reply" : [NSString
            stringWithFormat:@"Hello, %@! I am %@.", userInfo[@"name"], [[NSProcessInfo processInfo] processName]]
    };
}

- (NSDictionary *)onRemoteInstallPackage:(NSString *)message userInfo:(NSDictionary *)userInfo {
    NSString *packagePath = userInfo[@"PackagePath"];
    HBLogDebug(@"Received remote install request for package at path: %@", packagePath);

    if (!packagePath || ![[NSFileManager defaultManager] fileExistsAtPath:packagePath]) {
        HBLogError(@"Invalid package path: %@", packagePath);
        return @{@"error" : @"Invalid package path."};
    }

    HBLogDebug(@"Installing package at path: %@", packagePath);

    // trollstorehelper install <package_path>
    const char *trollHelper = installer_binary();
    HBLogDebug(@TAG "Using TrollStore helper at path: %s", trollHelper);

    if (access(trollHelper, F_OK) != 0) {
        HBLogDebug(@TAG "TrollStore helper binary not found!");
        return @{@"error" : @"TrollStore helper binary not found"};
    }

    // Prepare arguments for posix_spawn
    const char *args[] = {trollHelper, "install", "force", [packagePath UTF8String], NULL};
    pid_t pid;
    int status;

    // Execute trollstorehelper
    HBLogDebug(@TAG "Executing: %s install %@", trollHelper, packagePath);
    status = posix_spawn(&pid, trollHelper, NULL, NULL, (char *const *)args, NULL);

    if (status != 0) {
        HBLogDebug(@TAG "Failed to execute trollstorehelper: %s", strerror(status));
        return @{@"error" : [NSString stringWithFormat:@"Failed to execute process: %s", strerror(status)]};
    }

    HBLogDebug(@TAG "Successfully spawned trollstorehelper with pid: %d", pid);

    // Wait for the process to finish
    if (waitpid(pid, &status, 0) < 0) {
        HBLogDebug(@TAG "Error waiting for trollstorehelper: %s", strerror(errno));
        return @{@"error" : [NSString stringWithFormat:@"Error waiting for process: %s", strerror(errno)]};
    }

    if (!WIFEXITED(status)) {
        HBLogDebug(@TAG "trollstorehelper did not exit normally");
        return @{@"error" : @"Process did not exit normally"};
    }

    int exitStatus = WEXITSTATUS(status);
    HBLogDebug(@TAG "trollstorehelper exited with status: %d", exitStatus);

    if (exitStatus != 0) {
        return @{@"error" : [NSString stringWithFormat:@"Installation failed with exit code: %d", exitStatus]};
    }

    // It's ok that we don't return the installed app info here,
    // as the client actually doesn't care about it.
    return @{@"InstalledAppInfoArray" : @[@{
        
    }]};
}

@end

int main(int argc, const char *argv[]) {

    @autoreleasepool {
        static TrollInstallerService *server;
        server = [[TrollInstallerService alloc] init];

        static SandyXpcMessagingCenter *messagingCenter;
        messagingCenter = [SandyXpcMessagingCenter centerNamed:@"com.82flex.xcodeanytroll"];

        [messagingCenter registerForMessageName:@"OneWayMessage"
                                         target:server
                                       selector:@selector(onOneWayMessage:userInfo:)];

        [messagingCenter registerForMessageName:@"TwoWayMessage"
                                         target:server
                                       selector:@selector(onTwoWayMessage:userInfo:)];

        [messagingCenter registerForMessageName:@"InstallPackage"
                                         target:server
                                       selector:@selector(onRemoteInstallPackage:userInfo:)];

        [messagingCenter runServerOnCurrentThread];

        HBLogDebug(@TAG "Daemon is running...");
        CFRunLoopRun();
    }

    return EXIT_SUCCESS;
}
