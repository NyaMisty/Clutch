//
//  Dumper.m
//  Clutch
//
//  Created by Anton Titkov on 22.03.15.
//
//

#import "Dumper.h"
#import "Device.h"
#import <spawn.h>
#import <FrontBoardServices/FrontBoardServices.h>
#import <SpringBoardServices/SpringBoardServices.h>
#import <BackBoardServices/BackBoardServices.h>
#import <FrontBoardServices/FBSSystemService.h>
#import "FBApplicationInfo.h"
#import "LSApplicationWorkspace.h"
#import "LSApplicationProxy.h"

#ifndef _POSIX_SPAWN_DISABLE_ASLR
#define _POSIX_SPAWN_DISABLE_ASLR 0x0100
#endif

@implementation Dumper

- (nullable instancetype)init {
    return [self initWithHeader:(thin_header){0} originalBinary:nil];
}	

- (nullable instancetype)initWithHeader:(thin_header)macho originalBinary:(nullable Binary *)binary {
    self = [super init];
    if (self) {
        _thinHeader = macho;
        if (binary) {
            _originalBinary = binary;
        }
        _shouldDisableASLR = NO;
        _isASLRProtected = (_thinHeader.header.flags & MH_PIE) ? YES : NO;
    }

    return self;
}

+ (NSString *)readableArchFromMachHeader:(struct mach_header)header {
    if (header.cpusubtype == CPU_SUBTYPE_ARM64_ALL)
        return @"arm64";
    else if (header.cpusubtype == CPU_SUBTYPE_ARM64_V8)
        return @"arm64v8";
    else if (header.cpusubtype == CPU_SUBTYPE_ARM_V6)
        return @"armv6";
    else if (header.cpusubtype == CPU_SUBTYPE_ARM_V7)
        return @"armv7";
    else if (header.cpusubtype == CPU_SUBTYPE_ARM_V7K)
        return @"armv7k";
    else if (header.cpusubtype == CPU_SUBTYPE_ARM_V7S)
        return @"armv7s";
    else if (header.cpusubtype == CPU_SUBTYPE_ARM_V8)
        return @"armv8";

    return @"unknown";
}

+ (NSString *)readableArchFromHeader:(thin_header)macho {
    return [Dumper readableArchFromMachHeader:macho.header];
}


- (pid_t)posix_spawn:(NSString *)binaryPath disableASLR:(BOOL)yrn suspend:(BOOL)suspend {
    KJDebug(@"doing posix spawn for %@!", binaryPath);
    NSString *bundlePath = [binaryPath stringByDeletingLastPathComponent];

    NSMutableDictionary *debug_options = [NSMutableDictionary dictionary];

//    if (launch_argv != nil)
//      [debug_options setObject:launch_argv forKey:FBSDebugOptionKeyArguments];
//    if (launch_envp != nil)
//      [debug_options setObject:launch_envp forKey:FBSDebugOptionKeyEnvironment];

    //[debug_options setObject:stdio_path forKey:FBSDebugOptionKeyStandardOutPath];
    //[debug_options setObject:stdio_path
    //                  forKey:FBSDebugOptionKeyStandardErrorPath];
    [debug_options setObject:[NSNumber numberWithBool:YES]
                      forKey:FBSDebugOptionKeyWaitForDebugger];
    if (yrn)
      [debug_options setObject:[NSNumber numberWithBool:YES]
                        forKey:FBSDebugOptionKeyDisableASLR];

    // That will go in the overall dictionary:

    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    [options setObject:debug_options
                forKey:FBSOpenApplicationOptionKeyDebuggingOptions];
    // And there are some other options at the top level in this dictionary:
    [options setObject:[NSNumber numberWithBool:YES]
                forKey:FBSOpenApplicationOptionKeyUnlockDevice];

    // We have to get the "sequence ID & UUID" for this app bundle path and send
    // them to FBS:

    NSURL *app_bundle_url =
        [NSURL fileURLWithPath:bundlePath isDirectory:YES];
    LSApplicationProxy *app_proxy =
        [LSApplicationProxy applicationProxyForBundleURL:app_bundle_url];
    
    NSString *bundleIDNSStr = nil;
    
    NSString *infoPlist = [NSString stringWithFormat:@"%@/Info.plist", bundlePath];
    NSMutableDictionary *bundleInfo = [NSMutableDictionary dictionaryWithContentsOfFile:infoPlist];
    if (bundleInfo != nil) {
        bundleIDNSStr = [bundleInfo objectForKey:@"CFBundleIdentifier"];
    } else {
        KJDebug(@"Failed to get Info.plist at %@", infoPlist);
    }
    
    if (app_proxy && app_proxy.bundleIdentifier) {
        KJDebug(@"Sending AppProxy info: sequence no: %lu, GUID: %s.",
             app_proxy.sequenceNumber,
             [app_proxy.cacheGUID.UUIDString UTF8String]);
        bundleIDNSStr = app_proxy.bundleIdentifier;
        [options
            setObject:[NSNumber numberWithUnsignedInteger:(unsigned int)app_proxy.sequenceNumber]
                forKey:FBSOpenApplicationOptionKeyLSSequenceNumber];
        [options setObject:app_proxy.cacheGUID.UUIDString
                    forKey:FBSOpenApplicationOptionKeyLSCacheGUID];
    } else {
        KJDebug(@"Failed to get app_proxy for %@, using old posix spawn!", bundlePath);
        return [self posix_spawn_old:bundlePath disableASLR:yrn suspend:suspend];
    }

    //NSError error;
    //FBSAddEventDataToOptions(options, event_data, error);

    //return options;

    //typename FBSSystemService, typename FBSOpenApplicationErrorCode,
    //FBSOpenApplicationErrorCode FBSOpenApplicationErrorCodeNone, SetErrorFunction SetFBSError

    pid_t return_pid = -1;

    KJDebug(@"finished options, launching %@", bundleIDNSStr);
    // Now make our systemService:
    FBSSystemService *system_service = [[FBSSystemService alloc] init];


      mach_port_t client_port = [system_service createClientPort];
      __block dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
      __block FBSOpenApplicationErrorCode open_app_error = FBSOpenApplicationErrorCodeNone;
      bool wants_pid = true;
      __block pid_t pid_in_block;

      const char *cstr = [bundleIDNSStr UTF8String];
      if (!cstr)
        cstr = "<Unknown Bundle ID>";

      NSString *description = [options description];
      KJDebug(@"About to launch process for bundle ID: %s - options:\n%s", cstr,
        [description UTF8String]);
      [system_service
          openApplication:bundleIDNSStr
                  options:options
               clientPort:client_port
               withResult:^(NSError *bks_error) {
                 // The system service will cleanup the client port we created for
                 // us.
                 if (bks_error)
                   open_app_error = (FBSOpenApplicationErrorCode)[bks_error code];

                 if (open_app_error == FBSOpenApplicationErrorCodeNone) {
                   if (wants_pid) {
                     pid_in_block =
                         [system_service pidForApplication:bundleIDNSStr];
                     KJDebug(
                         @"In completion handler, got pid for bundle id, pid: %d.",
                         pid_in_block);
                    KJDebug(
                         @"In completion handler, got pid for bundle id, pid: %d.",
                         pid_in_block);
                   } else
                       KJDebug(@"In completion handler: success.");
                 } else {
                   const char *error_str =
                       [(NSString *)[bks_error localizedDescription] UTF8String];
                     KJDebug(@"In completion handler for send "
                                                 "event, got error \"%s\"(%ld).",
                                    error_str ? error_str : "<unknown error>",
                                    open_app_error);
                   // REMOVE ME
                     KJDebug(@"In completion handler for send event, got error "
                               "\"%s\"(%ld).",
                               error_str ? error_str : "<unknown error>",
                               open_app_error);
                 }

                 dispatch_semaphore_signal(semaphore);
               }

      ];

      const uint32_t timeout_secs = 30;

      dispatch_time_t timeout =
          dispatch_time(DISPATCH_TIME_NOW, timeout_secs * NSEC_PER_SEC);

      long success = dispatch_semaphore_wait(semaphore, timeout) == 0;

      if (!success) {
        KJPrint(@"timed out trying to send openApplication to %s.", cstr);
        return 99999999;
      } else if (open_app_error != FBSOpenApplicationErrorCodeNone) {
        KJDebug(@"unable to launch the application with CFBundleIdentifier '%s' "
                    "bks_error = %u",
                    cstr, open_app_error);
          return 99999999;
      } else if (wants_pid) {
        return_pid = pid_in_block;
        KJDebug(
            @"Out of completion handler, pid from block %d and passing out: %d",
            pid_in_block, return_pid);
      }

      return return_pid;
}

- (pid_t)posix_spawn:(NSString *)binaryPath disableASLR:(BOOL)yrn {
    return [self posix_spawn:binaryPath disableASLR:yrn suspend:YES];
}

- (pid_t)posix_spawn_old:(NSString *)binaryPath disableASLR:(BOOL)yrn suspend:(BOOL)suspend {

    if ((_thinHeader.header.flags & MH_PIE) && yrn) {

        KJDebug(@"disabling MH_PIE!!!!");

        _thinHeader.header.flags &= ~(uint32_t)MH_PIE;
        [self.originalFileHandle replaceBytesInRange:NSMakeRange(_thinHeader.offset, sizeof(_thinHeader.header))
                                           withBytes:&_thinHeader.header];
    } else if (_isASLRProtected && !yrn && !(_thinHeader.header.flags & MH_PIE)) {

        // thinHeader.header.flags |= MH_PIE;
        //[self.originalFileHandle replaceBytesInRange:NSMakeRange(_thinHeader.offset, sizeof(_thinHeader.header))
        // withBytes:&_thinHeader.header];
    } else {
        KJDebug(@"to MH_PIE or not to MH_PIE, that is the question");
    }

    pid_t pid = 0;

    const char *path = binaryPath.UTF8String;

    posix_spawnattr_t attr;

    exit_with_errno(posix_spawnattr_init(&attr), "::posix_spawnattr_init (&attr) error: ");

    short flags = 0;

    if (suspend) {
        flags = POSIX_SPAWN_START_SUSPENDED;
    }
    if (yrn)
        flags |= _POSIX_SPAWN_DISABLE_ASLR;

    // Set the flags we just made into our posix spawn attributes
    exit_with_errno(posix_spawnattr_setflags(&attr, flags), "::posix_spawnattr_setflags (&attr, flags) error: ");

    posix_spawnp(&pid, path, NULL, &attr, NULL, NULL);

    posix_spawnattr_destroy(&attr);

    KJDebug(@"got the pid %u %@", pid, binaryPath);

    return pid;
}

- (cpu_type_t)supportedCPUType {
    return 0;
}

- (BOOL)dumpBinary {
    return NO;
}

- (void)swapArch {

    KJPrint(@"Swapping architectures..");

    // time to swap
    NSString *suffix = [NSString stringWithFormat:@"_%@", [Dumper readableArchFromHeader:_thinHeader]];

    NSString *swappedBinaryPath = [_originalBinary.binaryPath stringByAppendingString:suffix];
    NSString *newSinf = [_originalBinary.sinfPath.stringByDeletingPathExtension
        stringByAppendingString:[suffix stringByAppendingPathExtension:_originalBinary.sinfPath.pathExtension]];
    NSString *newSupp = [_originalBinary.suppPath.stringByDeletingPathExtension
        stringByAppendingString:[suffix stringByAppendingPathExtension:_originalBinary.suppPath.pathExtension]];

    NSString *newSupf;
    if ([[NSFileManager defaultManager] fileExistsAtPath:_originalBinary.supfPath]) {
        newSupf = [_originalBinary.supfPath.stringByDeletingPathExtension
            stringByAppendingString:[suffix stringByAppendingPathExtension:_originalBinary.supfPath.pathExtension]];
    }

    NSError *error;
    BOOL isDirectory;

    if ([[NSFileManager defaultManager] fileExistsAtPath:swappedBinaryPath isDirectory:&isDirectory]) {
        [[NSFileManager defaultManager] removeItemAtPath:swappedBinaryPath error:nil];
    }

    [[NSFileManager defaultManager] copyItemAtPath:_originalBinary.binaryPath toPath:swappedBinaryPath error:&error];

    KJDebug(@"%@", error);

    [[NSFileManager defaultManager] copyItemAtPath:_originalBinary.sinfPath toPath:newSinf error:nil];

    [[NSFileManager defaultManager] copyItemAtPath:_originalBinary.suppPath toPath:newSupp error:nil];

    if (newSupf) {
        [[NSFileManager defaultManager] copyItemAtPath:_originalBinary.supfPath toPath:newSupf error:nil];
    }

    [self.originalFileHandle closeFile];
    self.originalFileHandle =
        [NSFileHandle fileHandleForReadingAtPath:swappedBinaryPath];

    uint32_t magic = [self.originalFileHandle unsignedInt32Atoffset:0];
    bool shouldSwap = magic == FAT_CIGAM;
#define SWAP(NUM) (shouldSwap ? CFSwapInt32((uint32_t)NUM) : (uint32_t)NUM)

    NSData *buffer = [self.originalFileHandle readDataOfLength:4096];

    struct fat_header fat = *(struct fat_header *)buffer.bytes;
    fat.nfat_arch = SWAP(fat.nfat_arch);
    int offset = sizeof(struct fat_header);

    for (unsigned int i = 0; i < fat.nfat_arch; i++) {
        struct fat_arch arch;
        arch = *(struct fat_arch *)((char *)buffer.bytes + offset);

        if (!(((int)SWAP(arch.cputype) == _thinHeader.header.cputype) &&
              ((int)SWAP(arch.cpusubtype) == _thinHeader.header.cpusubtype))) {

            if (SWAP(arch.cputype) == CPU_TYPE_ARM) {
                switch (SWAP(arch.cpusubtype)) {
                    case CPU_SUBTYPE_ARM_V6:
                        arch.cputype = (cpu_type_t)SWAP(CPU_TYPE_I386);
                        arch.cpusubtype = (cpu_subtype_t)SWAP(CPU_SUBTYPE_PENTIUM_3_XEON);
                        break;
                    case CPU_SUBTYPE_ARM_V7:
                        arch.cputype = (cpu_type_t)SWAP(CPU_TYPE_I386);
                        arch.cpusubtype = (cpu_subtype_t)SWAP(CPU_SUBTYPE_PENTIUM_4);
                        break;
                    case CPU_SUBTYPE_ARM_V7S:
                        arch.cputype = (cpu_type_t)SWAP(CPU_TYPE_I386);
                        arch.cpusubtype = (cpu_subtype_t)SWAP(CPU_SUBTYPE_ITANIUM);
                        break;
                    case CPU_SUBTYPE_ARM_V7K: // Apple Watch FTW
                        arch.cputype = (cpu_type_t)SWAP(CPU_TYPE_I386);
                        arch.cpusubtype = (cpu_subtype_t)SWAP(CPU_SUBTYPE_XEON);
                        break;
                    default:
                        KJPrint(@"Warning: A wild 32-bit cpusubtype appeared! %u", SWAP(arch.cpusubtype));
                        arch.cputype = (cpu_type_t)SWAP(CPU_TYPE_I386);
                        arch.cpusubtype = (cpu_subtype_t)SWAP(CPU_SUBTYPE_PENTIUM_3_XEON); // pentium 3 ftw
                        break;
                }
            } else {

                switch (SWAP(arch.cpusubtype)) {
                    case CPU_SUBTYPE_ARM64_ALL:
                        arch.cputype = (int)SWAP(CPU_TYPE_X86_64);
                        arch.cpusubtype = (int)SWAP(CPU_SUBTYPE_X86_64_ALL);
                        break;
                    case CPU_SUBTYPE_ARM64_V8:
                        arch.cputype = (int)SWAP(CPU_TYPE_X86_64);
                        arch.cpusubtype = (int)SWAP(CPU_SUBTYPE_X86_64_H);
                        break;
                    default:
                        KJPrint(@"Warning: A wild 64-bit cpusubtype appeared! %u", SWAP(arch.cpusubtype));
                        arch.cputype = (int)SWAP(CPU_TYPE_X86_64);
                        arch.cpusubtype = (int)SWAP(CPU_SUBTYPE_X86_64_ALL);
                        break;
                }
            }

            [self.originalFileHandle replaceBytesInRange:NSMakeRange((NSUInteger)offset, sizeof(struct fat_arch))
                                               withBytes:&arch];
        }

        offset += sizeof(struct fat_arch);
    }

    KJDebug(@"wrote new header to binary");
    // we don't close file handle here since it's reused later in dumping!
}

- (BOOL)_dumpToFileHandle:(NSFileHandle *)fileHandle
                withDumpSize:(uint32_t)togo
                       pages:(uint32_t)pages
                    fromPort:(mach_port_t)port
                         pid:(pid_t)pid
                   aslrSlide:(mach_vm_address_t)__text_start
    codeSignature_hashOffset:(uint32_t)hashOffset
              codesign_begin:(uint32_t)begin {
    KJDebug(@"checksum size %u", pages * 20);
    void *checksum = malloc(pages * 20); // 160 bits for each hash (SHA1)

    uint32_t headerProgress =
        _thinHeader.header.cputype == CPU_TYPE_ARM64 ? sizeof(struct mach_header_64) : sizeof(struct mach_header);

    uint32_t i_lcmd = 0;
    kern_return_t err;
    uint32_t pages_d = 0;
    BOOL header = TRUE;

    uint8_t buf_d[0x1000];         // create a single page buffer
    uint8_t *buf = &buf_d[0];      // store the location of the buffer
    mach_vm_size_t local_size = 0; // amount of data moved into the buffer

    KJPrint(@"Dumping %@ (%@)", _originalBinary, [Dumper readableArchFromHeader:_thinHeader]);

    while (togo > 0) {
        if ((err = mach_vm_read_overwrite(port,
                                          (mach_vm_address_t)__text_start + (pages_d * 0x1000),
                                          (vm_size_t)0x1000,
                                          (pointer_t)buf,
                                          &local_size)) != KERN_SUCCESS) {

            KJPrint(@"Failed to dump a page :(");
            free(checksum); // free checksum table

            _kill(pid);

            return NO;
        }

        if (header) {

            // iterate over the header (or resume iteration)
            uint8_t *curloc = buf + headerProgress;
            for (; i_lcmd < _thinHeader.header.ncmds; i_lcmd++) {
                struct load_command *l_cmd = (struct load_command *)curloc;
                // is the load command size in a different page?
                uint32_t lcmd_size;
                if ((int)((curloc - buf) + 4) == 0x1000) {
                    // load command size is at the start of the next page
                    // we need to get it
                    mach_vm_read_overwrite(port,
                                           (mach_vm_address_t)__text_start + ((pages_d + 1) * 0x1000),
                                           (vm_size_t)0x1,
                                           (mach_vm_address_t)&lcmd_size,
                                           &local_size);
                } else {
                    lcmd_size = l_cmd->cmdsize;
                }

                if (l_cmd->cmd == LC_ENCRYPTION_INFO) {
                    struct encryption_info_command *newcrypt = (struct encryption_info_command *)curloc;
                    newcrypt->cryptid = 0; // change the cryptid to 0
                    KJPrint(@"Patched cryptid (32bit segment)");
                } else if (l_cmd->cmd == LC_ENCRYPTION_INFO_64) {
                    struct encryption_info_command_64 *newcrypt = (struct encryption_info_command_64 *)curloc;
                    newcrypt->cryptid = 0; // change the cryptid to 0
                    KJPrint(@"Patched cryptid (64bit segment)");
                }

                curloc += lcmd_size;
                if (curloc >= buf + 0x1000) {
                    // we are currently extended past the header page
                    // offset for the next round:
                    headerProgress = (uint32_t)(((char *)curloc - (char *)buf) % 0x1000);
                    // prevent attaching overdrive dylib by skipping
                    goto writedata;
                }
            }

            header = FALSE;
        }

    writedata:
        [fileHandle writeData:[NSData dataWithBytes:buf length:0x1000]]; // write the page
        sha1((uint8_t *)checksum + (20 * pages_d), buf, 0x1000);         // perform checksum on the page
        togo -= 0x1000;                                                  // remove a page from the togo
        pages_d += 1;                                                    // increase the amount of completed pages
    }

    // nice! now let's write the new checksum data
    KJPrint(@"Writing new checksum");
    [fileHandle seekToFileOffset:(begin + hashOffset)];

    NSData *trimmed_checksum = [[NSData dataWithBytes:checksum
                                               length:pages * 20] subdataWithRange:NSMakeRange(0, 20 * pages_d)];
    free(checksum);
    [fileHandle writeData:trimmed_checksum];

    KJDebug(@"Done writing checksum");

    return YES;
}

void *safe_trim(void *p, size_t n) {
    void *p2 = realloc(p, n);
    return p2 ? p2 : p;
}

- (NSData *)getSubData:(NSData *)source withRange:(NSRange)range {
    UInt8 bytes[range.length];
    [source getBytes:&bytes range:range];
    NSData *result = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    return result;
}

- (ArchCompatibility)compatibilityMode {

    KJDebug(@"Segment cputype: %u, cpusubtype: %u", _thinHeader.header.cputype, _thinHeader.header.cpusubtype);
    KJDebug(@"Device cputype: %u, cpusubtype: %u", Device.cpu_type, Device.cpu_subtype);
    KJDebug(@"Dumper supports cputype %u", self.supportedCPUType);

    if (self.supportedCPUType != _thinHeader.header.cputype) {
        KJDebug(@"Dumper <%@> does not support the %@ architecture",
                NSStringFromClass([self class]),
                [Dumper readableArchFromHeader:_thinHeader]);
        return ArchCompatibilityNotCompatible;
    }

    else if ((Device.cpu_type == CPU_TYPE_ARM64) && (_thinHeader.header.cputype == CPU_TYPE_ARM)) {
        KJDebug(@"God Mode On");
        return ArchCompatibilityCompatible;
    }

    else if ((_thinHeader.header.cpusubtype > Device.cpu_subtype) || (_thinHeader.header.cputype > Device.cpu_type)) {
        KJDebug(@"Cannot use dumper %@, device not supported", NSStringFromClass([self class]));
        return ArchCompatibilityNotCompatible;
    }

    return ArchCompatibilityCompatible;
}

@end
