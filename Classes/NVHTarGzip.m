//
//  NVHTarGzip.m
//  Pods
//
//  Created by Niels van Hoorn on 26/03/14.
//
//

#import "NVHTarGzip.h"
#import "NVHGzipFile.h"
#import "NVHTarFile.h"


@interface NVHTarGzip()

@end


@implementation NVHTarGzip

+ (NVHTarGzip *)sharedInstance {
    static dispatch_once_t onceToken;
    static NVHTarGzip *tarGzip;
    dispatch_once(&onceToken, ^{
        tarGzip = [NVHTarGzip new];
    });
    return tarGzip;
}

- (BOOL)unTarFileAtPath:(NSString *)sourcePath
                 toPath:(NSString *)destinationPath
                  error:(NSError **)error {
    NVHTarFile* tarFile = [[NVHTarFile alloc] initWithPath:sourcePath];
    return [tarFile createFilesAndDirectoriesAtPath:destinationPath error:error];
}

- (BOOL)unGzipFileAtPath:(NSString *)sourcePath
                  toPath:(NSString *)destinationPath
                   error:(NSError **)error {
    NVHGzipFile* gzipFile = [[NVHGzipFile alloc] initWithPath:sourcePath];
    return [gzipFile inflateToPath:destinationPath error:error];
}

- (BOOL)unTarGzipFileAtPath:(NSString *)sourcePath
                     toPath:(NSString *)destinationPath
                      error:(NSError **)error {
    NSString *temporaryPath = [self temporaryFilePathForPath:sourcePath];
    [self unGzipFileAtPath:sourcePath toPath:temporaryPath error:error];
    if (*error != nil) {
        return NO;
    }
    [self unTarFileAtPath:temporaryPath toPath:destinationPath error:error];
    NSError *removeTemporaryFileError = nil;
    [[NSFileManager defaultManager] removeItemAtPath:temporaryPath error:&removeTemporaryFileError];
    if (*error != nil) {
        return NO;
    }
    if (removeTemporaryFileError != nil) {
        *error = removeTemporaryFileError;
        return NO;
    }
    return YES;
}

- (BOOL)tarFileAtPath:(NSString *)sourcePath
               toPath:(NSString *)destinationPath
                error:(NSError **)error {
    NVHTarFile* tarFile = [[NVHTarFile alloc] initWithPath:destinationPath];
    return [tarFile packFilesAndDirectoriesAtPath:sourcePath error:error];
}

- (BOOL)gzipFileAtPath:(NSString *)sourcePath
                toPath:(NSString *)destinationPath
                 error:(NSError **)error {
    NVHGzipFile* gzipFile = [[NVHGzipFile alloc] initWithPath:destinationPath];
    return [gzipFile deflateFromPath:sourcePath error:error];
}

- (BOOL)tarGzipFileAtPath:(NSString *)sourcePath
                   toPath:(NSString *)destinationPath
                    error:(NSError **)error {
    NSString *temporaryPath = [self temporaryFilePathForPath:sourcePath];
    [self tarFileAtPath:sourcePath toPath:temporaryPath error:error];
    if (*error != nil) {
        return NO;
    }
    [self gzipFileAtPath:temporaryPath toPath:destinationPath error:error];
    NSError* removeCacheError = nil;
    [[NSFileManager defaultManager] removeItemAtPath:temporaryPath error:&removeCacheError];
    if (*error != nil) {
        return NO;
    }
    if (removeCacheError != nil) {
        *error = removeCacheError;
        return NO;
    }
    return YES;
}

- (void)unTarFileAtPath:(NSString *)sourcePath
                 toPath:(NSString *)destinationPath
             completion:(void(^)(NSError *))completion {
    NVHTarFile* tarFile = [[NVHTarFile alloc] initWithPath:sourcePath];
    [tarFile createFilesAndDirectoriesAtPath:destinationPath completion:completion];
}

- (void)unGzipFileAtPath:(NSString *)sourcePath
                  toPath:(NSString *)destinationPath
              completion:(void(^)(NSError *))completion {
    NVHGzipFile* gzipFile = [[NVHGzipFile alloc] initWithPath:sourcePath];
    [gzipFile inflateToPath:destinationPath completion:completion];
}

- (void)unTarGzipFileAtPath:(NSString*)sourcePath
                     toPath:(NSString*)destinationPath
                 completion:(void(^)(NSError *))completion {
    NSString *temporaryPath = [self temporaryFilePathForPath:sourcePath];
    [self unGzipFileAtPath:sourcePath toPath:temporaryPath completion:^(NSError *gzipError) {
        if (gzipError != nil) {
            completion(gzipError);
            return;
        }
        [self unTarFileAtPath:temporaryPath toPath:destinationPath completion:^(NSError *tarError) {
            NSError* error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:temporaryPath error:&error];
            if (tarError != nil) {
                error = tarError;
            }
            completion(error);
        }];
    }];
}

- (void)tarFileAtPath:(NSString *)sourcePath
               toPath:(NSString *)destinationPath
           completion:(void(^)(NSError *))completion {
    NVHTarFile *tarFile = [[NVHTarFile alloc] initWithPath:destinationPath];
    [tarFile packFilesAndDirectoriesAtPath:sourcePath completion:completion];
}

- (void)gzipFileAtPath:(NSString *)sourcePath
                toPath:(NSString *)destinationPath
            completion:(void(^)(NSError *))completion {
    NVHGzipFile *gzipFile = [[NVHGzipFile alloc] initWithPath:destinationPath];
    [gzipFile deflateFromPath:sourcePath completion:completion];
}

- (void)tarGzipFileAtPath:(NSString *)sourcePath
                   toPath:(NSString *)destinationPath
               completion:(void(^)(NSError *))completion {
    NSString *temporaryPath = [self temporaryFilePathForPath:destinationPath];
    [self tarFileAtPath:sourcePath toPath:temporaryPath completion:^(NSError *tarError) {
        if (tarError != nil) {
            completion(tarError);
            return;
        }
        [self gzipFileAtPath:temporaryPath toPath:destinationPath completion:^(NSError *gzipError) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:temporaryPath error:&error];
            if (gzipError != nil) {
                error = gzipError;
            }
            completion(error);
        }];
    }];
}

- (NSString *)temporaryFilePathForPath:(NSString *)path {
    NSString *UUIDString = [[NSUUID UUID] UUIDString];
    NSString *filename = [[path lastPathComponent] stringByDeletingPathExtension];
    NSString *temporaryFile = [filename stringByAppendingFormat:@"-%@",UUIDString];
    NSString *temporaryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:temporaryFile];
    if (![[temporaryPath pathExtension] isEqualToString:@"tar"]) {
        temporaryPath = [temporaryPath stringByAppendingPathExtension:@"tar"];
    }
    return temporaryPath;
}

@end
