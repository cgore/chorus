/*
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
*/

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include <stdlib.h>
#include <string.h>

static char *
copy_nsstring(NSString *string)
{
    const char *utf8;

    if (string == nil)
        return strdup("Metal error");
    utf8 = string.UTF8String;
    if (utf8 == NULL)
        return strdup("Metal error");
    return strdup(utf8);
}

void *
chorus_metal_new_queue(void *device)
{
    id<MTLDevice> metal_device = (__bridge id<MTLDevice>)device;
    id<MTLCommandQueue> queue = [metal_device newCommandQueue];

    return (__bridge_retained void *)queue;
}

void *
chorus_metal_new_buffer(void *device, unsigned long bytes)
{
    id<MTLDevice> metal_device = (__bridge id<MTLDevice>)device;
    id<MTLBuffer> buffer =
        [metal_device newBufferWithLength:(NSUInteger)bytes
                                  options:MTLResourceStorageModeShared];

    return (__bridge_retained void *)buffer;
}

void *
chorus_metal_buffer_contents(void *buffer)
{
    return [(__bridge id<MTLBuffer>)buffer contents];
}

unsigned long
chorus_metal_buffer_length(void *buffer)
{
    return (unsigned long)[(__bridge id<MTLBuffer>)buffer length];
}

void *
chorus_metal_compile(void *device, const char *source, char **error_out)
{
    *error_out = NULL;
    @autoreleasepool {
        id<MTLDevice> metal_device = (__bridge id<MTLDevice>)device;
        NSString *text = [NSString stringWithUTF8String:source];
        NSError *error = nil;
        id<MTLLibrary> library =
            [metal_device newLibraryWithSource:text options:nil error:&error];

        if (library == nil) {
            *error_out = copy_nsstring(error.localizedDescription);
            return NULL;
        }
        return (__bridge_retained void *)library;
    }
}

void *
chorus_metal_function(void *library, const char *name, char **error_out)
{
    *error_out = NULL;
    @autoreleasepool {
        id<MTLLibrary> metal_library = (__bridge id<MTLLibrary>)library;
        NSString *function_name = [NSString stringWithUTF8String:name];
        id<MTLFunction> function = [metal_library newFunctionWithName:function_name];

        if (function == nil) {
            *error_out = copy_nsstring(
                [NSString stringWithFormat:@"Metal function %s was not found.", name]);
            return NULL;
        }
        return (__bridge_retained void *)function;
    }
}

void *
chorus_metal_pipeline(void *device, void *function, char **error_out)
{
    *error_out = NULL;
    @autoreleasepool {
        id<MTLDevice> metal_device = (__bridge id<MTLDevice>)device;
        id<MTLFunction> metal_function = (__bridge id<MTLFunction>)function;
        NSError *error = nil;
        id<MTLComputePipelineState> pipeline =
            [metal_device newComputePipelineStateWithFunction:metal_function
                                                        error:&error];

        if (pipeline == nil) {
            *error_out = copy_nsstring(error.localizedDescription);
            return NULL;
        }
        return (__bridge_retained void *)pipeline;
    }
}

unsigned long
chorus_metal_execution_width(void *pipeline)
{
    return (unsigned long)[(__bridge id<MTLComputePipelineState>)pipeline
        threadExecutionWidth];
}

unsigned long
chorus_metal_max_threads(void *pipeline)
{
    return (unsigned long)[(__bridge id<MTLComputePipelineState>)pipeline
        maxTotalThreadsPerThreadgroup];
}

int
chorus_metal_dispatch(void *queue,
                      void *pipeline,
                      void **buffers,
                      unsigned long buffer_count,
                      void **scalar_bytes,
                      unsigned long *scalar_lengths,
                      unsigned long scalar_count,
                      unsigned long grid_x,
                      unsigned long grid_y,
                      unsigned long grid_z,
                      unsigned long group_x,
                      unsigned long group_y,
                      unsigned long group_z,
                      char **error_out)
{
    *error_out = NULL;
    @autoreleasepool {
        id<MTLCommandQueue> metal_queue = (__bridge id<MTLCommandQueue>)queue;
        id<MTLComputePipelineState> metal_pipeline =
            (__bridge id<MTLComputePipelineState>)pipeline;
        id<MTLCommandBuffer> command = [metal_queue commandBuffer];
        id<MTLComputeCommandEncoder> encoder;
        unsigned long index;

        if (command == nil) {
            *error_out = strdup("Metal did not vend a command buffer.");
            return 1;
        }
        encoder = [command computeCommandEncoder];
        [encoder setComputePipelineState:metal_pipeline];
        for (index = 0; index < buffer_count; index++) {
            [encoder setBuffer:(__bridge id<MTLBuffer>)buffers[index]
                        offset:0
                       atIndex:(NSUInteger)index];
        }
        for (index = 0; index < scalar_count; index++) {
            [encoder setBytes:scalar_bytes[index]
                       length:(NSUInteger)scalar_lengths[index]
                      atIndex:(NSUInteger)(buffer_count + index)];
        }
        [encoder dispatchThreads:MTLSizeMake(grid_x, grid_y, grid_z)
           threadsPerThreadgroup:MTLSizeMake(group_x, group_y, group_z)];
        [encoder endEncoding];
        [command commit];
        [command waitUntilCompleted];
        if (command.status == MTLCommandBufferStatusError) {
            *error_out = copy_nsstring(command.error.localizedDescription);
            return 1;
        }
        return 0;
    }
}

void
chorus_metal_release(void *object)
{
    if (object != NULL)
        CFRelease(object);
}

void
chorus_metal_free_string(char *string)
{
    free(string);
}
