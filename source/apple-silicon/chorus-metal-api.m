/*
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
*/

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <string.h>
#import <stdlib.h>

static char *
copy_text(NSString *string, const char *fallback)
{
    const char *utf8;

    if (string == nil)
        return strdup(fallback);
    utf8 = string.UTF8String;
    if (utf8 == NULL)
        return strdup(fallback);
    return strdup(utf8);
}

static int
fail(char **error_out, const char *message)
{
    if (error_out != NULL)
        *error_out = strdup(message);
    return 1;
}

static int
fail_error(char **error_out, NSError *error, const char *fallback)
{
    if (error_out != NULL)
        *error_out = copy_text(error.localizedDescription, fallback);
    return 1;
}

static int
finish_command(id<MTLCommandBuffer> command, char **error_out)
{
    [command commit];
    [command waitUntilCompleted];
    if (command.status == MTLCommandBufferStatusError)
        return fail_error(error_out, command.error, "Metal command buffer failed.");
    return 0;
}

static id<MTLLibrary>
compile_library(id<MTLDevice> device, NSString *source, char **error_out)
{
    NSError *error = nil;
    id<MTLLibrary> library = [device newLibraryWithSource:source options:nil error:&error];

    if (library == nil && error_out != NULL)
        *error_out = copy_text(error.localizedDescription, "Metal library failed to compile.");
    return library;
}

static id<MTLComputePipelineState>
compute_pipeline(id<MTLDevice> device, NSString *source, NSString *name, char **error_out)
{
    NSError *error = nil;
    id<MTLLibrary> library = compile_library(device, source, error_out);
    id<MTLFunction> function;
    id<MTLComputePipelineState> pipeline;

    if (library == nil)
        return nil;
    function = [library newFunctionWithName:name];
    if (function == nil) {
        fail(error_out, "Metal function was not found.");
        return nil;
    }
    pipeline = [device newComputePipelineStateWithFunction:function error:&error];
    if (pipeline == nil && error_out != NULL)
        *error_out = copy_text(error.localizedDescription, "Metal compute pipeline failed.");
    return pipeline;
}

int
chorus_metal_copy_protocol_names(char **names, char **error_out)
{
    unsigned int count = 0;
    Protocol * __unsafe_unretained *protocols;
    NSMutableArray<NSString *> *found;
    unsigned int index;

    if (error_out != NULL)
        *error_out = NULL;
    protocols = objc_copyProtocolList(&count);
    found = [NSMutableArray array];
    for (index = 0; index < count; index++) {
        const char *name = protocol_getName(protocols[index]);

        if (name != NULL && strncmp(name, "MTL", 3) == 0)
            [found addObject:[NSString stringWithUTF8String:name]];
    }
    free(protocols);
    [found sortUsingSelector:@selector(compare:)];
    *names = strdup([[found componentsJoinedByString:@"\n"] UTF8String]);
    return 0;
}

void
chorus_metal_device_info(void *device_pointer,
                         unsigned long long *registry_id,
                         int *unified,
                         unsigned long *threadgroup_memory,
                         unsigned long long *working_set)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;

    *registry_id = device.registryID;
    *unified = device.hasUnifiedMemory ? 1 : 0;
    *threadgroup_memory = (unsigned long)device.maxThreadgroupMemoryLength;
    *working_set = device.recommendedMaxWorkingSetSize;
}

int
chorus_metal_device_supports_family(void *device_pointer, long family)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;

    return [device supportsFamily:(MTLGPUFamily)family] ? 1 : 0;
}

void *
chorus_metal_default_device(char **error_out)
{
    id<MTLDevice> device;

    if (error_out != NULL)
        *error_out = NULL;
    device = MTLCreateSystemDefaultDevice();
    if (device == nil) {
        fail(error_out, "Metal did not vend a default device.");
        return NULL;
    }
    return (__bridge_retained void *)device;
}

void
chorus_metal_queue_set_label(void *queue_pointer, const char *label)
{
    ((__bridge id<MTLCommandQueue>)queue_pointer).label =
        [NSString stringWithUTF8String:label];
}

char *
chorus_metal_queue_label(void *queue_pointer)
{
    return copy_text(((__bridge id<MTLCommandQueue>)queue_pointer).label, "");
}

void *
chorus_metal_buffer_with_options(void *device_pointer, unsigned long bytes,
                                 unsigned long options, char **error_out)
{
    id<MTLBuffer> buffer;

    if (error_out != NULL)
        *error_out = NULL;
    buffer = [(__bridge id<MTLDevice>)device_pointer
        newBufferWithLength:(NSUInteger)bytes
                    options:(MTLResourceOptions)options];
    if (buffer == nil) {
        fail(error_out, "Metal did not vend a buffer.");
        return NULL;
    }
    return (__bridge_retained void *)buffer;
}

unsigned long
chorus_metal_buffer_storage_mode(void *buffer_pointer)
{
    return (unsigned long)[(__bridge id<MTLBuffer>)buffer_pointer storageMode];
}

int
chorus_metal_buffer_has_contents(void *buffer_pointer)
{
    return [(__bridge id<MTLBuffer>)buffer_pointer contents] != NULL;
}

int
chorus_metal_blit_fill(void *queue_pointer, void *buffer_pointer,
                       unsigned char value, unsigned long size, char **error_out)
{
    id<MTLCommandQueue> queue = (__bridge id<MTLCommandQueue>)queue_pointer;
    id<MTLCommandBuffer> command = [queue commandBuffer];
    id<MTLBlitCommandEncoder> blit = [command blitCommandEncoder];

    if (error_out != NULL)
        *error_out = NULL;
    blit.label = @"chorus-blit-fill";
    [blit fillBuffer:(__bridge id<MTLBuffer>)buffer_pointer
               range:NSMakeRange(0, (NSUInteger)size)
               value:value];
    [blit endEncoding];
    return finish_command(command, error_out);
}

int
chorus_metal_blit_copy(void *queue_pointer, void *source_pointer,
                       void *destination_pointer, unsigned long size,
                       char **error_out)
{
    id<MTLCommandQueue> queue = (__bridge id<MTLCommandQueue>)queue_pointer;
    id<MTLCommandBuffer> command = [queue commandBuffer];
    id<MTLBlitCommandEncoder> blit = [command blitCommandEncoder];

    if (error_out != NULL)
        *error_out = NULL;
    [blit copyFromBuffer:(__bridge id<MTLBuffer>)source_pointer
            sourceOffset:0
                toBuffer:(__bridge id<MTLBuffer>)destination_pointer
       destinationOffset:0
                    size:(NSUInteger)size];
    [blit endEncoding];
    return finish_command(command, error_out);
}

int
chorus_metal_private_roundtrip(void *device_pointer, void *queue_pointer,
                               int *value, char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    id<MTLBuffer> source = [device newBufferWithLength:4
                                               options:MTLResourceStorageModeShared];
    id<MTLBuffer> private_buffer = [device newBufferWithLength:4
                                                       options:MTLResourceStorageModePrivate];
    id<MTLBuffer> destination = [device newBufferWithLength:4
                                                    options:MTLResourceStorageModeShared];
    id<MTLCommandBuffer> command;
    id<MTLBlitCommandEncoder> blit;

    if (error_out != NULL)
        *error_out = NULL;
    if (private_buffer == nil)
        return fail(error_out, "Metal did not vend a private buffer.");
    memset(source.contents, 42, 4);
    memset(destination.contents, 0, 4);
    command = [(__bridge id<MTLCommandQueue>)queue_pointer commandBuffer];
    blit = [command blitCommandEncoder];
    [blit copyFromBuffer:source sourceOffset:0 toBuffer:private_buffer
        destinationOffset:0 size:4];
    [blit copyFromBuffer:private_buffer sourceOffset:0 toBuffer:destination
        destinationOffset:0 size:4];
    [blit endEncoding];
    if (finish_command(command, error_out) != 0)
        return 1;
    *value = ((unsigned char *)destination.contents)[0];
    return 0;
}

int
chorus_metal_managed_roundtrip(void *device_pointer, void *queue_pointer,
                               unsigned long *mode, int *value, char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    id<MTLBuffer> managed = [device newBufferWithLength:4
                                                options:MTLResourceStorageModeManaged];
    id<MTLBuffer> destination = [device newBufferWithLength:4
                                                    options:MTLResourceStorageModeShared];
    id<MTLCommandBuffer> command;
    id<MTLBlitCommandEncoder> blit;

    if (error_out != NULL)
        *error_out = NULL;
    if (managed == nil)
        return fail(error_out, "Metal did not vend a managed buffer.");
    *mode = (unsigned long)managed.storageMode;
    if (managed.contents != NULL)
        memset(managed.contents, 19, 4);
    memset(destination.contents, 0, 4);
    command = [(__bridge id<MTLCommandQueue>)queue_pointer commandBuffer];
    blit = [command blitCommandEncoder];
    [blit copyFromBuffer:managed sourceOffset:0 toBuffer:destination
        destinationOffset:0 size:4];
    [blit endEncoding];
    if (finish_command(command, error_out) != 0)
        return 1;
    *value = ((unsigned char *)destination.contents)[0];
    return 0;
}

int
chorus_metal_texture_roundtrip(void *device_pointer, unsigned char pixel[4],
                               char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    MTLTextureDescriptor *descriptor =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                           width:1
                                                          height:1
                                                       mipmapped:NO];
    id<MTLTexture> texture;
    id<MTLTexture> view;
    unsigned char readback[4];

    if (error_out != NULL)
        *error_out = NULL;
    descriptor.storageMode = MTLStorageModeShared;
    descriptor.usage = MTLTextureUsageShaderRead;
    texture = [device newTextureWithDescriptor:descriptor];
    if (texture == nil)
        return fail(error_out, "Metal did not vend a texture.");
    [texture replaceRegion:MTLRegionMake2D(0, 0, 1, 1)
               mipmapLevel:0
                 withBytes:pixel
               bytesPerRow:4];
    view = [texture newTextureViewWithPixelFormat:MTLPixelFormatRGBA8Unorm];
    if (view == nil)
        return fail(error_out, "Metal did not vend a texture view.");
    [view getBytes:readback bytesPerRow:4 fromRegion:MTLRegionMake2D(0, 0, 1, 1)
        mipmapLevel:0];
    memcpy(pixel, readback, 4);
    return 0;
}

int
chorus_metal_heap_used(void *device_pointer, unsigned long *used, char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    MTLHeapDescriptor *descriptor = [MTLHeapDescriptor new];
    id<MTLHeap> heap;
    id<MTLBuffer> buffer;

    if (error_out != NULL)
        *error_out = NULL;
    descriptor.size = 4096;
    descriptor.storageMode = MTLStorageModeShared;
    heap = [device newHeapWithDescriptor:descriptor];
    if (heap == nil)
        return fail(error_out, "Metal did not vend a heap.");
    buffer = [heap newBufferWithLength:256 options:MTLResourceStorageModeShared];
    if (buffer == nil)
        return fail(error_out, "Metal did not vend a buffer from the heap.");
    *used = (unsigned long)heap.usedSize;
    return 0;
}

int
chorus_metal_make_states(void *device_pointer, char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    MTLSamplerDescriptor *sampler_descriptor = [MTLSamplerDescriptor new];
    MTLDepthStencilDescriptor *depth_descriptor = [MTLDepthStencilDescriptor new];
    id<MTLSamplerState> sampler;
    id<MTLDepthStencilState> depth;

    if (error_out != NULL)
        *error_out = NULL;
    sampler_descriptor.minFilter = MTLSamplerMinMagFilterLinear;
    sampler_descriptor.magFilter = MTLSamplerMinMagFilterLinear;
    sampler = [device newSamplerStateWithDescriptor:sampler_descriptor];
    depth_descriptor.depthCompareFunction = MTLCompareFunctionAlways;
    depth_descriptor.depthWriteEnabled = YES;
    depth = [device newDepthStencilStateWithDescriptor:depth_descriptor];
    if (sampler == nil || depth == nil)
        return fail(error_out, "Metal did not vend a sampler or depth state.");
    return 0;
}

int
chorus_metal_render_triangle(void *device_pointer, void *queue_pointer,
                             unsigned char *pixels, unsigned long width,
                             unsigned long height, unsigned int *fragment_writes,
                             char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    NSError *error = nil;
    NSString *source =
        @"#include <metal_stdlib>\n"
        "using namespace metal;\n"
        "struct Out { float4 position [[position]]; };\n"
        "vertex Out triangle_vertex(uint vid [[vertex_id]]) {\n"
        "  float2 positions[3] = { float2(-1.0, -1.0), float2(1.0, -1.0), float2(0.0, 1.0) };\n"
        "  Out out;\n"
        "  out.position = float4(positions[vid], 0.0, 1.0);\n"
        "  return out;\n"
        "}\n"
        "fragment float4 triangle_fragment(device atomic_uint *counter [[buffer(0), raster_order_group(0)]]) {\n"
        "  atomic_fetch_add_explicit(counter, 1, memory_order_relaxed);\n"
        "  return float4(1.0, 0.0, 0.0, 1.0);\n"
        "}\n";
    id<MTLLibrary> library = compile_library(device, source, error_out);
    id<MTLFunction> vertex;
    id<MTLFunction> fragment;
    MTLRenderPipelineDescriptor *pipeline_descriptor;
    id<MTLRenderPipelineState> pipeline;
    MTLTextureDescriptor *color_descriptor;
    MTLTextureDescriptor *depth_descriptor;
    id<MTLTexture> color;
    id<MTLTexture> depth;
    id<MTLBuffer> counter;
    MTLDepthStencilDescriptor *depth_state_descriptor;
    id<MTLDepthStencilState> depth_state;
    MTLRenderPassDescriptor *pass;
    id<MTLCommandBuffer> command;
    id<MTLRenderCommandEncoder> encoder;

    if (library == nil)
        return 1;
    vertex = [library newFunctionWithName:@"triangle_vertex"];
    fragment = [library newFunctionWithName:@"triangle_fragment"];
    pipeline_descriptor = [MTLRenderPipelineDescriptor new];
    pipeline_descriptor.vertexFunction = vertex;
    pipeline_descriptor.fragmentFunction = fragment;
    pipeline_descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA8Unorm;
    pipeline_descriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    pipeline = [device newRenderPipelineStateWithDescriptor:pipeline_descriptor error:&error];
    if (pipeline == nil)
        return fail_error(error_out, error, "Metal render pipeline failed.");
    color_descriptor =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                           width:(NSUInteger)width
                                                          height:(NSUInteger)height
                                                       mipmapped:NO];
    color_descriptor.storageMode = MTLStorageModeShared;
    color_descriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    color = [device newTextureWithDescriptor:color_descriptor];
    depth_descriptor =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                           width:(NSUInteger)width
                                                          height:(NSUInteger)height
                                                       mipmapped:NO];
    depth_descriptor.storageMode = MTLStorageModePrivate;
    depth_descriptor.usage = MTLTextureUsageRenderTarget;
    depth = [device newTextureWithDescriptor:depth_descriptor];
    counter = [device newBufferWithLength:sizeof(unsigned int)
                                  options:MTLResourceStorageModeShared];
    memset(counter.contents, 0, sizeof(unsigned int));
    depth_state_descriptor = [MTLDepthStencilDescriptor new];
    depth_state_descriptor.depthCompareFunction = MTLCompareFunctionAlways;
    depth_state_descriptor.depthWriteEnabled = YES;
    depth_state = [device newDepthStencilStateWithDescriptor:depth_state_descriptor];
    pass = [MTLRenderPassDescriptor renderPassDescriptor];
    pass.colorAttachments[0].texture = color;
    pass.colorAttachments[0].loadAction = MTLLoadActionClear;
    pass.colorAttachments[0].storeAction = MTLStoreActionStore;
    pass.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
    pass.depthAttachment.texture = depth;
    pass.depthAttachment.loadAction = MTLLoadActionClear;
    pass.depthAttachment.storeAction = MTLStoreActionStore;
    pass.depthAttachment.clearDepth = 1.0;
    command = [(__bridge id<MTLCommandQueue>)queue_pointer commandBuffer];
    encoder = [command renderCommandEncoderWithDescriptor:pass];
    encoder.label = @"chorus-render";
    [encoder pushDebugGroup:@"chorus-triangle"];
    [encoder insertDebugSignpost:@"draw"];
    [encoder setRenderPipelineState:pipeline];
    [encoder setDepthStencilState:depth_state];
    [encoder setFragmentBuffer:counter offset:0 atIndex:0];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    [encoder popDebugGroup];
    [encoder endEncoding];
    if (finish_command(command, error_out) != 0)
        return 1;
    [color getBytes:pixels
        bytesPerRow:width * 4
         fromRegion:MTLRegionMake2D(0, 0, width, height)
        mipmapLevel:0];
    *fragment_writes = *(unsigned int *)counter.contents;
    return 0;
}

int
chorus_metal_timed_dispatch(void *device_pointer, void *queue_pointer,
                            int *handler_ran, int *status, double *gpu_start,
                            double *gpu_end, char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    id<MTLComputePipelineState> pipeline = compute_pipeline
        (device,
         @"#include <metal_stdlib>\nusing namespace metal;\n"
         "kernel void tick(device int *out [[buffer(0)]]) { out[0] = 1; }\n",
         @"tick", error_out);
    id<MTLBuffer> buffer;
    id<MTLCommandBuffer> command;
    dispatch_semaphore_t semaphore;
    __block int ran = 0;
    __block int command_status = 0;
    __block double start = 0;
    __block double end = 0;

    if (pipeline == nil)
        return 1;
    buffer = [device newBufferWithLength:4 options:MTLResourceStorageModeShared];
    memset(buffer.contents, 0, 4);
    command = [(__bridge id<MTLCommandQueue>)queue_pointer commandBuffer];
    semaphore = dispatch_semaphore_create(0);
    [command addCompletedHandler:^(id<MTLCommandBuffer> completed) {
        ran = 1;
        command_status = (int)completed.status;
        start = completed.GPUStartTime;
        end = completed.GPUEndTime;
        dispatch_semaphore_signal(semaphore);
    }];
    {
        id<MTLComputeCommandEncoder> encoder = [command computeCommandEncoder];

        [encoder setComputePipelineState:pipeline];
        [encoder setBuffer:buffer offset:0 atIndex:0];
        [encoder dispatchThreads:MTLSizeMake(1, 1, 1)
           threadsPerThreadgroup:MTLSizeMake(1, 1, 1)];
        [encoder endEncoding];
    }
    [command commit];
    if (dispatch_semaphore_wait(semaphore,
                                dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)) != 0)
        return fail(error_out, "Metal completion handler did not run.");
    *handler_ran = ran;
    *status = command_status;
    *gpu_start = start;
    *gpu_end = end;
    return command_status == MTLCommandBufferStatusCompleted
        ? 0
        : fail(error_out, "Metal command buffer did not complete.");
}

int
chorus_metal_fence_order(void *device_pointer, void *queue_pointer,
                         int *value, char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    id<MTLBuffer> source = [device newBufferWithLength:4
                                               options:MTLResourceStorageModeShared];
    id<MTLBuffer> destination = [device newBufferWithLength:4
                                                    options:MTLResourceStorageModeShared];
    id<MTLFence> fence = [device newFence];
    id<MTLCommandBuffer> command;
    id<MTLBlitCommandEncoder> producer;
    id<MTLBlitCommandEncoder> consumer;

    if (error_out != NULL)
        *error_out = NULL;
    memset(source.contents, 0, 4);
    memset(destination.contents, 0, 4);
    command = [(__bridge id<MTLCommandQueue>)queue_pointer commandBuffer];
    producer = [command blitCommandEncoder];
    [producer fillBuffer:source range:NSMakeRange(0, 4) value:9];
    [producer updateFence:fence];
    [producer endEncoding];
    consumer = [command blitCommandEncoder];
    [consumer waitForFence:fence];
    [consumer copyFromBuffer:source sourceOffset:0 toBuffer:destination
            destinationOffset:0 size:4];
    [consumer endEncoding];
    if (finish_command(command, error_out) != 0)
        return 1;
    *value = ((unsigned char *)destination.contents)[0];
    return 0;
}

int
chorus_metal_shared_event_order(void *device_pointer, int *value, char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    id<MTLCommandQueue> producer_queue = [device newCommandQueue];
    id<MTLCommandQueue> consumer_queue = [device newCommandQueue];
    id<MTLSharedEvent> event = [device newSharedEvent];
    id<MTLBuffer> source = [device newBufferWithLength:4
                                               options:MTLResourceStorageModeShared];
    id<MTLBuffer> destination = [device newBufferWithLength:4
                                                    options:MTLResourceStorageModeShared];
    id<MTLCommandBuffer> producer;
    id<MTLBlitCommandEncoder> fill;
    id<MTLCommandBuffer> consumer;
    id<MTLBlitCommandEncoder> copy;

    if (error_out != NULL)
        *error_out = NULL;
    memset(destination.contents, 0, 4);
    producer = [producer_queue commandBuffer];
    fill = [producer blitCommandEncoder];
    [fill fillBuffer:source range:NSMakeRange(0, 4) value:8];
    [fill endEncoding];
    [producer encodeSignalEvent:event value:1];
    consumer = [consumer_queue commandBuffer];
    [consumer encodeWaitForEvent:event value:1];
    copy = [consumer blitCommandEncoder];
    [copy copyFromBuffer:source sourceOffset:0 toBuffer:destination
        destinationOffset:0 size:4];
    [copy endEncoding];
    [producer commit];
    [consumer commit];
    [consumer waitUntilCompleted];
    [producer waitUntilCompleted];
    if (consumer.status == MTLCommandBufferStatusError)
        return fail_error(error_out, consumer.error, "Metal consumer queue failed.");
    *value = ((unsigned char *)destination.contents)[0];
    return 0;
}

int
chorus_metal_indirect_dispatch(void *device_pointer, void *queue_pointer,
                               int *value, char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    id<MTLComputePipelineState> pipeline = compute_pipeline
        (device,
         @"#include <metal_stdlib>\nusing namespace metal;\n"
         "kernel void mark(device int *out [[buffer(0)]]) { out[0] = 1; }\n",
         @"mark", error_out);
    id<MTLBuffer> arguments;
    id<MTLBuffer> output;
    MTLDispatchThreadgroupsIndirectArguments counts;
    id<MTLCommandBuffer> command;
    id<MTLComputeCommandEncoder> encoder;

    if (pipeline == nil)
        return 1;
    arguments = [device newBufferWithLength:sizeof(counts)
                                    options:MTLResourceStorageModeShared];
    output = [device newBufferWithLength:4 options:MTLResourceStorageModeShared];
    memset(output.contents, 0, 4);
    counts.threadgroupsPerGrid[0] = 1;
    counts.threadgroupsPerGrid[1] = 1;
    counts.threadgroupsPerGrid[2] = 1;
    memcpy(arguments.contents, &counts, sizeof(counts));
    command = [(__bridge id<MTLCommandQueue>)queue_pointer commandBuffer];
    encoder = [command computeCommandEncoder];
    [encoder setComputePipelineState:pipeline];
    [encoder setBuffer:output offset:0 atIndex:0];
    [encoder dispatchThreadgroupsWithIndirectBuffer:arguments
                               indirectBufferOffset:0
                              threadsPerThreadgroup:MTLSizeMake(1, 1, 1)];
    [encoder endEncoding];
    if (finish_command(command, error_out) != 0)
        return 1;
    *value = *(int *)output.contents;
    return 0;
}

int
chorus_metal_indirect_commands(void *device_pointer, void *queue_pointer,
                               int *value, char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    NSError *error = nil;
    id<MTLLibrary> library = compile_library
        (device,
         @"#include <metal_stdlib>\nusing namespace metal;\n"
         "kernel void mark(device int *out [[buffer(0)]]) { out[0] = 2; }\n",
         error_out);
    MTLComputePipelineDescriptor *pipeline_descriptor;
    id<MTLComputePipelineState> pipeline;
    MTLIndirectCommandBufferDescriptor *descriptor;
    id<MTLIndirectCommandBuffer> indirect;
    id<MTLIndirectComputeCommand> compute;
    id<MTLBuffer> output;
    id<MTLCommandBuffer> command;
    id<MTLComputeCommandEncoder> encoder;

    if (library == nil)
        return 1;
    pipeline_descriptor = [MTLComputePipelineDescriptor new];
    pipeline_descriptor.computeFunction = [library newFunctionWithName:@"mark"];
    pipeline_descriptor.supportIndirectCommandBuffers = YES;
    pipeline = [device newComputePipelineStateWithDescriptor:pipeline_descriptor
                                                    options:MTLPipelineOptionNone
                                                 reflection:nil
                                                      error:&error];
    if (pipeline == nil)
        return fail_error(error_out, error, "Metal indirect pipeline failed.");
    descriptor = [MTLIndirectCommandBufferDescriptor new];
    descriptor.commandTypes = MTLIndirectCommandTypeConcurrentDispatch;
    descriptor.inheritPipelineState = NO;
    descriptor.inheritBuffers = NO;
    descriptor.maxKernelBufferBindCount = 1;
    indirect = [device newIndirectCommandBufferWithDescriptor:descriptor
                                              maxCommandCount:1
                                                      options:MTLResourceStorageModeShared];
    if (indirect == nil)
        return fail(error_out, "Metal did not vend an indirect command buffer.");
    [indirect resetWithRange:NSMakeRange(0, 1)];
    compute = [indirect indirectComputeCommandAtIndex:0];
    output = [device newBufferWithLength:4 options:MTLResourceStorageModeShared];
    memset(output.contents, 0, 4);
    [compute setComputePipelineState:pipeline];
    [compute setKernelBuffer:output offset:0 atIndex:0];
    [compute concurrentDispatchThreadgroups:MTLSizeMake(1, 1, 1)
                      threadsPerThreadgroup:MTLSizeMake(1, 1, 1)];
    command = [(__bridge id<MTLCommandQueue>)queue_pointer commandBuffer];
    encoder = [command computeCommandEncoderWithDispatchType:MTLDispatchTypeConcurrent];
    [encoder useResource:output usage:MTLResourceUsageWrite];
    [encoder executeCommandsInBuffer:indirect withRange:NSMakeRange(0, 1)];
    [encoder endEncoding];
    if (finish_command(command, error_out) != 0)
        return 1;
    *value = *(int *)output.contents;
    return 0;
}

int
chorus_metal_argument_buffer(void *device_pointer, void *queue_pointer,
                             int *value, char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    MTLArgumentDescriptor *argument = [MTLArgumentDescriptor argumentDescriptor];
    id<MTLArgumentEncoder> encoder;
    id<MTLBuffer> data;
    id<MTLBuffer> table;
    id<MTLBuffer> output;
    id<MTLComputePipelineState> pipeline;
    id<MTLCommandBuffer> command;
    id<MTLComputeCommandEncoder> compute;

    if (error_out != NULL)
        *error_out = NULL;
    argument.dataType = MTLDataTypePointer;
    argument.index = 0;
    argument.access = MTLBindingAccessReadOnly;
    encoder = [device newArgumentEncoderWithArguments:@[argument]];
    if (encoder == nil)
        return fail(error_out, "Metal did not vend an argument encoder.");
    data = [device newBufferWithLength:4 options:MTLResourceStorageModeShared];
    table = [device newBufferWithLength:encoder.encodedLength
                                options:MTLResourceStorageModeShared];
    output = [device newBufferWithLength:4 options:MTLResourceStorageModeShared];
    *(int *)data.contents = 11;
    memset(output.contents, 0, 4);
    [encoder setArgumentBuffer:table offset:0];
    [encoder setBuffer:data offset:0 atIndex:0];
    pipeline = compute_pipeline
        (device,
         @"#include <metal_stdlib>\nusing namespace metal;\n"
         "struct Args { device int *value [[id(0)]]; };\n"
         "kernel void read_arg(constant Args &args [[buffer(0)]], device int *out [[buffer(1)]]) {\n"
         "  out[0] = args.value[0];\n"
         "}\n",
         @"read_arg", error_out);
    if (pipeline == nil)
        return 1;
    command = [(__bridge id<MTLCommandQueue>)queue_pointer commandBuffer];
    compute = [command computeCommandEncoder];
    [compute setComputePipelineState:pipeline];
    [compute setBuffer:table offset:0 atIndex:0];
    [compute setBuffer:output offset:0 atIndex:1];
    [compute useResource:data usage:MTLResourceUsageRead];
    [compute dispatchThreads:MTLSizeMake(1, 1, 1)
       threadsPerThreadgroup:MTLSizeMake(1, 1, 1)];
    [compute endEncoding];
    if (finish_command(command, error_out) != 0)
        return 1;
    *value = *(int *)output.contents;
    return 0;
}

int
chorus_metal_function_constant(void *device_pointer, void *queue_pointer,
                               int constant, int *value, char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    NSError *error = nil;
    id<MTLLibrary> library = compile_library
        (device,
         @"#include <metal_stdlib>\nusing namespace metal;\n"
         "constant int k [[function_constant(0)]];\n"
         "kernel void write_k(device int *out [[buffer(0)]]) { out[0] = k; }\n",
         error_out);
    MTLFunctionConstantValues *values;
    id<MTLFunction> function;
    id<MTLComputePipelineState> pipeline;
    id<MTLBuffer> output;
    id<MTLCommandBuffer> command;
    id<MTLComputeCommandEncoder> encoder;

    if (library == nil)
        return 1;
    values = [MTLFunctionConstantValues new];
    [values setConstantValue:&constant type:MTLDataTypeInt atIndex:0];
    function = [library newFunctionWithName:@"write_k" constantValues:values error:&error];
    if (function == nil)
        return fail_error(error_out, error, "Metal function constant failed.");
    pipeline = [device newComputePipelineStateWithFunction:function error:&error];
    if (pipeline == nil)
        return fail_error(error_out, error, "Metal compute pipeline failed.");
    output = [device newBufferWithLength:4 options:MTLResourceStorageModeShared];
    memset(output.contents, 0, 4);
    command = [(__bridge id<MTLCommandQueue>)queue_pointer commandBuffer];
    encoder = [command computeCommandEncoder];
    [encoder setComputePipelineState:pipeline];
    [encoder setBuffer:output offset:0 atIndex:0];
    [encoder dispatchThreads:MTLSizeMake(1, 1, 1)
       threadsPerThreadgroup:MTLSizeMake(1, 1, 1)];
    [encoder endEncoding];
    if (finish_command(command, error_out) != 0)
        return 1;
    *value = *(int *)output.contents;
    return 0;
}

int
chorus_metal_threadgroup(void *device_pointer, void *queue_pointer,
                         int *value, char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    id<MTLComputePipelineState> pipeline = compute_pipeline
        (device,
         @"#include <metal_stdlib>\nusing namespace metal;\n"
         "kernel void reduce(device int *out [[buffer(0)]],\n"
         "                   threadgroup int *scratch [[threadgroup(0)]],\n"
         "                   uint tid [[thread_index_in_threadgroup]]) {\n"
         "  scratch[tid] = (int)tid;\n"
         "  threadgroup_barrier(mem_flags::mem_threadgroup);\n"
         "  if (tid == 0) {\n"
         "    int sum = 0;\n"
         "    for (uint i = 0; i < 4; i++) sum += scratch[i];\n"
         "    out[0] = sum;\n"
         "  }\n"
         "}\n",
         @"reduce", error_out);
    id<MTLBuffer> output;
    id<MTLCommandBuffer> command;
    id<MTLComputeCommandEncoder> encoder;

    if (pipeline == nil)
        return 1;
    output = [device newBufferWithLength:4 options:MTLResourceStorageModeShared];
    memset(output.contents, 0, 4);
    command = [(__bridge id<MTLCommandQueue>)queue_pointer commandBuffer];
    encoder = [command computeCommandEncoder];
    [encoder setComputePipelineState:pipeline];
    [encoder setBuffer:output offset:0 atIndex:0];
    [encoder setThreadgroupMemoryLength:16 atIndex:0];
    [encoder dispatchThreads:MTLSizeMake(4, 1, 1)
       threadsPerThreadgroup:MTLSizeMake(4, 1, 1)];
    [encoder endEncoding];
    if (finish_command(command, error_out) != 0)
        return 1;
    *value = *(int *)output.contents;
    return 0;
}

int
chorus_metal_sample_texture(void *device_pointer, void *queue_pointer,
                            float *value, char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    MTLTextureDescriptor *descriptor =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                           width:1 height:1 mipmapped:NO];
    id<MTLTexture> texture;
    unsigned char pixel[4] = {255, 0, 0, 255};
    MTLSamplerDescriptor *sampler_descriptor = [MTLSamplerDescriptor new];
    id<MTLSamplerState> sampler;
    id<MTLComputePipelineState> pipeline;
    id<MTLBuffer> output;
    id<MTLCommandBuffer> command;
    id<MTLComputeCommandEncoder> encoder;

    if (error_out != NULL)
        *error_out = NULL;
    descriptor.storageMode = MTLStorageModeShared;
    descriptor.usage = MTLTextureUsageShaderRead;
    texture = [device newTextureWithDescriptor:descriptor];
    [texture replaceRegion:MTLRegionMake2D(0, 0, 1, 1) mipmapLevel:0
                 withBytes:pixel bytesPerRow:4];
    sampler = [device newSamplerStateWithDescriptor:sampler_descriptor];
    pipeline = compute_pipeline
        (device,
         @"#include <metal_stdlib>\nusing namespace metal;\n"
         "kernel void sample_red(texture2d<float> tex [[texture(0)]],\n"
         "                       sampler samp [[sampler(0)]],\n"
         "                       device float *out [[buffer(0)]]) {\n"
         "  out[0] = tex.sample(samp, float2(0.5, 0.5)).r;\n"
         "}\n",
         @"sample_red", error_out);
    if (pipeline == nil)
        return 1;
    output = [device newBufferWithLength:sizeof(float)
                                options:MTLResourceStorageModeShared];
    memset(output.contents, 0, sizeof(float));
    command = [(__bridge id<MTLCommandQueue>)queue_pointer commandBuffer];
    encoder = [command computeCommandEncoder];
    [encoder setComputePipelineState:pipeline];
    [encoder setTexture:texture atIndex:0];
    [encoder setSamplerState:sampler atIndex:0];
    [encoder setBuffer:output offset:0 atIndex:0];
    [encoder dispatchThreads:MTLSizeMake(1, 1, 1)
       threadsPerThreadgroup:MTLSizeMake(1, 1, 1)];
    [encoder endEncoding];
    if (finish_command(command, error_out) != 0)
        return 1;
    *value = *(float *)output.contents;
    return 0;
}

int
chorus_metal_mipmap(void *device_pointer, void *queue_pointer,
                    unsigned char pixel[4], char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    MTLTextureDescriptor *descriptor =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                           width:2 height:2 mipmapped:YES];
    id<MTLTexture> texture;
    unsigned char pixels[16];
    id<MTLCommandBuffer> command;
    id<MTLBlitCommandEncoder> blit;

    if (error_out != NULL)
        *error_out = NULL;
    descriptor.storageMode = MTLStorageModeShared;
    descriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsagePixelFormatView;
    texture = [device newTextureWithDescriptor:descriptor];
    if (texture == nil)
        return fail(error_out, "Metal did not vend a mipmapped texture.");
    memset(pixels, 255, sizeof(pixels));
    [texture replaceRegion:MTLRegionMake2D(0, 0, 2, 2) mipmapLevel:0
                 withBytes:pixels bytesPerRow:8];
    command = [(__bridge id<MTLCommandQueue>)queue_pointer commandBuffer];
    blit = [command blitCommandEncoder];
    [blit generateMipmapsForTexture:texture];
    [blit endEncoding];
    if (finish_command(command, error_out) != 0)
        return 1;
    [texture getBytes:pixel bytesPerRow:4 fromRegion:MTLRegionMake2D(0, 0, 1, 1)
          mipmapLevel:1];
    return 0;
}

int
chorus_metal_trace_ray(void *device_pointer, void *queue_pointer,
                       float *distance, char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    float vertices[9] = {0.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f};
    id<MTLBuffer> vertex_buffer = [device newBufferWithBytes:vertices
                                                     length:sizeof(vertices)
                                                    options:MTLResourceStorageModeShared];
    MTLAccelerationStructureTriangleGeometryDescriptor *geometry =
        [MTLAccelerationStructureTriangleGeometryDescriptor descriptor];
    MTLPrimitiveAccelerationStructureDescriptor *primitive =
        [MTLPrimitiveAccelerationStructureDescriptor descriptor];
    MTLAccelerationStructureSizes sizes;
    id<MTLAccelerationStructure> structure;
    id<MTLBuffer> scratch;
    id<MTLComputePipelineState> pipeline;
    id<MTLBuffer> output;
    id<MTLCommandBuffer> command;
    id<MTLAccelerationStructureCommandEncoder> builder;
    id<MTLComputeCommandEncoder> compute;

    if (error_out != NULL)
        *error_out = NULL;
    geometry.vertexBuffer = vertex_buffer;
    geometry.triangleCount = 1;
    primitive.geometryDescriptors = @[geometry];
    sizes = [device accelerationStructureSizesWithDescriptor:primitive];
    structure = [device newAccelerationStructureWithSize:sizes.accelerationStructureSize];
    scratch = [device newBufferWithLength:sizes.buildScratchBufferSize
                                  options:MTLResourceStorageModePrivate];
    if (structure == nil || scratch == nil)
        return fail(error_out, "Metal did not vend an acceleration structure.");
    pipeline = compute_pipeline
        (device,
         @"#include <metal_stdlib>\nusing namespace metal;\n"
         "using namespace metal::raytracing;\n"
         "kernel void trace(device float *distance [[buffer(0)]],\n"
         "                  primitive_acceleration_structure accel [[buffer(1)]]) {\n"
         "  ray r;\n"
         "  r.origin = float3(0.2, 0.2, 1.0);\n"
         "  r.direction = float3(0.0, 0.0, -1.0);\n"
         "  r.min_distance = 0.0;\n"
         "  r.max_distance = 10.0;\n"
         "  intersector<triangle_data> query;\n"
         "  intersection_result<triangle_data> hit = query.intersect(r, accel);\n"
         "  distance[0] = hit.type == intersection_type::triangle ? hit.distance : -1.0;\n"
         "}\n",
         @"trace", error_out);
    if (pipeline == nil)
        return 1;
    output = [device newBufferWithLength:sizeof(float)
                                options:MTLResourceStorageModeShared];
    *(float *)output.contents = -2.0f;
    command = [(__bridge id<MTLCommandQueue>)queue_pointer commandBuffer];
    builder = [command accelerationStructureCommandEncoder];
    [builder buildAccelerationStructure:structure descriptor:primitive
                         scratchBuffer:scratch scratchBufferOffset:0];
    [builder endEncoding];
    compute = [command computeCommandEncoder];
    [compute setComputePipelineState:pipeline];
    [compute setBuffer:output offset:0 atIndex:0];
    [compute setAccelerationStructure:structure atBufferIndex:1];
    [compute dispatchThreads:MTLSizeMake(1, 1, 1)
       threadsPerThreadgroup:MTLSizeMake(1, 1, 1)];
    [compute endEncoding];
    if (finish_command(command, error_out) != 0)
        return 1;
    *distance = *(float *)output.contents;
    return 0;
}

static int
metal4_wait(id<MTLDevice> device, id<MTL4CommandQueue> queue, char **error_out)
{
    id<MTLSharedEvent> event = [device newSharedEvent];

    [queue signalEvent:event value:1];
    if (![event waitUntilSignaledValue:1 timeoutMS:5000])
        return fail(error_out, "Metal 4 command queue did not signal.");
    return 0;
}

int
chorus_metal4_compute(void *device_pointer, int *value, int *machine_learning,
                      char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    id<MTL4CommandQueue> queue;
    id<MTL4CommandAllocator> allocator;
    id<MTL4CommandBuffer> command;
    id<MTLComputePipelineState> pipeline;
    id<MTLBuffer> source;
    id<MTLBuffer> destination;
    MTLResidencySetDescriptor *residency_descriptor;
    id<MTLResidencySet> residency;
    MTL4ArgumentTableDescriptor *table_descriptor;
    NSError *error = nil;
    id<MTL4ArgumentTable> table;
    id<MTL4ComputeCommandEncoder> encoder;
    id<MTL4MachineLearningCommandEncoder> learning;

    if (error_out != NULL)
        *error_out = NULL;
    if (![device supportsFamily:MTLGPUFamilyMetal4])
        return fail(error_out, "This device does not support Metal 4.");
    queue = [device newMTL4CommandQueue];
    allocator = [device newCommandAllocator];
    command = [device newCommandBuffer];
    if (queue == nil || allocator == nil || command == nil)
        return fail(error_out, "Metal 4 did not vend a command queue.");
    pipeline = compute_pipeline
        (device,
         @"#include <metal_stdlib>\nusing namespace metal;\n"
         "kernel void write_five(device int *out [[buffer(0)]]) { out[0] = 5; }\n",
         @"write_five", error_out);
    if (pipeline == nil)
        return 1;
    source = [device newBufferWithLength:4 options:MTLResourceStorageModeShared];
    destination = [device newBufferWithLength:4 options:MTLResourceStorageModeShared];
    memset(source.contents, 0, 4);
    memset(destination.contents, 0, 4);
    residency_descriptor = [MTLResidencySetDescriptor new];
    residency = [device newResidencySetWithDescriptor:residency_descriptor error:&error];
    if (residency == nil)
        return fail_error(error_out, error, "Metal did not vend a residency set.");
    [residency addAllocation:source];
    [residency addAllocation:destination];
    [residency commit];
    [residency requestResidency];
    table_descriptor = [MTL4ArgumentTableDescriptor new];
    table_descriptor.maxBufferBindCount = 1;
    table = [device newArgumentTableWithDescriptor:table_descriptor error:&error];
    if (table == nil)
        return fail_error(error_out, error, "Metal 4 did not vend an argument table.");
    [command beginCommandBufferWithAllocator:allocator];
    [command useResidencySet:residency];
    [queue addResidencySet:residency];
    encoder = [command computeCommandEncoder];
    if (encoder == nil)
        return fail(error_out, "Metal 4 did not vend a compute encoder.");
    [encoder setComputePipelineState:pipeline];
    [encoder setArgumentTable:table];
    [table setAddress:source.gpuAddress atIndex:0];
    [encoder dispatchThreads:MTLSizeMake(1, 1, 1)
       threadsPerThreadgroup:MTLSizeMake(1, 1, 1)];
    [encoder barrierAfterEncoderStages:MTLStageDispatch
                   beforeEncoderStages:MTLStageBlit
                     visibilityOptions:MTL4VisibilityOptionDevice];
    [encoder copyFromBuffer:source sourceOffset:0 toBuffer:destination
           destinationOffset:0 size:4];
    [encoder endEncoding];
    learning = [command machineLearningCommandEncoder];
    *machine_learning = learning != nil;
    if (learning != nil)
        [learning endEncoding];
    [command endCommandBuffer];
    [queue commit:(id<MTL4CommandBuffer> []){command} count:1];
    if (metal4_wait(device, queue, error_out) != 0)
        return 1;
    *value = *(int *)destination.contents;
    return 0;
}

int
chorus_metal_residency_count(void *device_pointer, unsigned long *count,
                             char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    NSError *error = nil;
    id<MTLResidencySet> residency =
        [device newResidencySetWithDescriptor:[MTLResidencySetDescriptor new] error:&error];
    id<MTLBuffer> buffer;

    if (residency == nil)
        return fail_error(error_out, error, "Metal did not vend a residency set.");
    buffer = [device newBufferWithLength:16 options:MTLResourceStorageModePrivate];
    [residency addAllocation:buffer];
    [residency commit];
    *count = (unsigned long)residency.allocationCount;
    return [residency containsAllocation:buffer] ? 0 : fail(error_out, "Residency set lost its buffer.");
}

int
chorus_metal_tensor(void *device_pointer, long *extent0, long *extent1,
                    char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    NSInteger values[2] = {3, 2};
    MTLTensorExtents *extents = [[MTLTensorExtents alloc] initWithRank:2 values:values];
    MTLTensorDescriptor *descriptor = [MTLTensorDescriptor new];
    NSError *error = nil;
    id<MTLTensor> tensor;

    descriptor.dimensions = extents;
    descriptor.dataType = MTLTensorDataTypeFloat32;
    descriptor.usage = MTLTensorUsageCompute | MTLTensorUsageMachineLearning;
    tensor = [device newTensorWithDescriptor:descriptor error:&error];
    if (tensor == nil)
        return fail_error(error_out, error, "Metal did not vend a tensor.");
    *extent0 = [tensor.dimensions extentAtDimensionIndex:0];
    *extent1 = [tensor.dimensions extentAtDimensionIndex:1];
    return 0;
}

int
chorus_metal_shader_log(void *device_pointer, void *queue_pointer,
                        char **message, char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    NSError *error = nil;
    MTLLogStateDescriptor *log_descriptor = [MTLLogStateDescriptor new];
    NSMutableString *logged = [NSMutableString string];
    id<MTLLogState> log_state;
    id<MTLComputePipelineState> pipeline;
    MTLCommandBufferDescriptor *command_descriptor;
    id<MTLCommandBuffer> command;
    id<MTLBuffer> output;

    if (error_out != NULL)
        *error_out = NULL;
    log_descriptor.level = MTLLogLevelDebug;
    log_descriptor.bufferSize = 4096;
    log_state = [device newLogStateWithDescriptor:log_descriptor error:&error];
    if (log_state == nil)
        return fail_error(error_out, error, "Metal did not vend a log state.");
    [log_state addLogHandler:^(NSString *subSystem, NSString *category,
                               MTLLogLevel level, NSString *text) {
        (void)subSystem;
        (void)category;
        (void)level;
        if (text != nil)
            [logged appendString:text];
    }];
    {
        MTLCompileOptions *compile_options = [MTLCompileOptions new];
        id<MTLLibrary> library;
        id<MTLFunction> function;

        compile_options.enableLogging = YES;
        library = [device newLibraryWithSource:
                @"#include <metal_stdlib>\nusing namespace metal;\n"
                "kernel void announce(device int *out [[buffer(0)]]) {\n"
                "  os_log_default.log(\"chorus-log-token\");\n"
                "  out[0] = 1;\n"
                "}\n"
                                      options:compile_options
                                        error:&error];
        if (library == nil)
            return fail_error(error_out, error, "Metal log library failed to compile.");
        function = [library newFunctionWithName:@"announce"];
        pipeline = [device newComputePipelineStateWithFunction:function error:&error];
    }
    if (pipeline == nil)
        return fail_error(error_out, error, "Metal log pipeline failed.");
    output = [device newBufferWithLength:4 options:MTLResourceStorageModeShared];
    command_descriptor = [MTLCommandBufferDescriptor new];
    command_descriptor.logState = log_state;
    command = [(__bridge id<MTLCommandQueue>)queue_pointer
        commandBufferWithDescriptor:command_descriptor];
    {
        id<MTLComputeCommandEncoder> encoder = [command computeCommandEncoder];

        [encoder setComputePipelineState:pipeline];
        [encoder setBuffer:output offset:0 atIndex:0];
        [encoder dispatchThreads:MTLSizeMake(1, 1, 1)
           threadsPerThreadgroup:MTLSizeMake(1, 1, 1)];
        [encoder endEncoding];
    }
    if (finish_command(command, error_out) != 0)
        return 1;
    *message = copy_text(logged, "");
    return 0;
}

int
chorus_metal_capture(void *device_pointer, void *queue_pointer, const char *path,
                     int *supported, char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    MTLCaptureManager *manager = [MTLCaptureManager sharedCaptureManager];
    MTLCaptureDescriptor *descriptor;
    NSError *error = nil;
    id<MTLCommandBuffer> command;

    if (error_out != NULL)
        *error_out = NULL;
    *supported = [manager supportsDestination:MTLCaptureDestinationGPUTraceDocument] ? 1 : 0;
    if (*supported == 0)
        return 0;
    descriptor = [MTLCaptureDescriptor new];
    descriptor.captureObject = device;
    descriptor.destination = MTLCaptureDestinationGPUTraceDocument;
    descriptor.outputURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:path]];
    if (![manager startCaptureWithDescriptor:descriptor error:&error])
        return fail_error(error_out, error, "Metal capture did not start.");
    command = [(__bridge id<MTLCommandQueue>)queue_pointer commandBuffer];
    [command commit];
    [command waitUntilCompleted];
    [manager stopCapture];
    return 0;
}

int
chorus_metal_counter(void *device_pointer, void *queue_pointer, int *supported,
                     unsigned long *bytes, char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    id<MTLCounterSet> counter_set;
    MTLCounterSampleBufferDescriptor *descriptor;
    NSError *error = nil;
    id<MTLCounterSampleBuffer> sample;
    id<MTLCommandBuffer> command;
    id<MTLComputeCommandEncoder> encoder;
    NSData *resolved;

    if (error_out != NULL)
        *error_out = NULL;
    *supported = [device supportsCounterSampling:MTLCounterSamplingPointAtDispatchBoundary] ? 1 : 0;
    *bytes = 0;
    if (*supported == 0)
        return 0;
    counter_set = device.counterSets.firstObject;
    if (counter_set == nil)
        return 0;
    descriptor = [MTLCounterSampleBufferDescriptor new];
    descriptor.counterSet = counter_set;
    descriptor.sampleCount = 1;
    descriptor.storageMode = MTLStorageModeShared;
    sample = [device newCounterSampleBufferWithDescriptor:descriptor error:&error];
    if (sample == nil)
        return fail_error(error_out, error, "Metal did not vend a counter sample buffer.");
    command = [(__bridge id<MTLCommandQueue>)queue_pointer commandBuffer];
    encoder = [command computeCommandEncoder];
    [encoder sampleCountersInBuffer:sample atSampleIndex:0 withBarrier:YES];
    [encoder endEncoding];
    if (finish_command(command, error_out) != 0)
        return 1;
    resolved = [sample resolveCounterRange:NSMakeRange(0, 1)];
    *bytes = resolved == nil ? 0 : (unsigned long)resolved.length;
    return 0;
}

int
chorus_metal_io_load(void *device_pointer, const char *path, unsigned long size,
                     void *bytes, char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    NSError *error = nil;
    id<MTLIOFileHandle> handle =
        [device newIOFileHandleWithURL:[NSURL fileURLWithPath:
                                        [NSString stringWithUTF8String:path]]
                                 error:&error];
    id<MTLIOCommandQueue> queue;
    id<MTLIOCommandBuffer> command;
    id<MTLBuffer> buffer;

    if (handle == nil)
        return fail_error(error_out, error, "Metal did not vend an IO file handle.");
    queue = [device newIOCommandQueueWithDescriptor:[MTLIOCommandQueueDescriptor new]
                                              error:&error];
    if (queue == nil)
        return fail_error(error_out, error, "Metal did not vend an IO command queue.");
    buffer = [device newBufferWithLength:(NSUInteger)size
                                options:MTLResourceStorageModeShared];
    command = [queue commandBuffer];
    [command loadBuffer:buffer offset:0 size:(NSUInteger)size
           sourceHandle:handle sourceHandleOffset:0];
    [command commit];
    [command waitUntilCompleted];
    if (command.status != MTLIOStatusComplete)
        return fail(error_out, "Metal IO command did not complete.");
    memcpy(bytes, buffer.contents, size);
    return 0;
}

int
chorus_metal_binary_archive(void *device_pointer, void *queue_pointer,
                            const char *path, int *value, char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    NSError *error = nil;
    id<MTLLibrary> library = compile_library
        (device,
         @"#include <metal_stdlib>\nusing namespace metal;\n"
         "kernel void from_archive(device int *out [[buffer(0)]]) { out[0] = 6; }\n",
         error_out);
    MTLComputePipelineDescriptor *pipeline_descriptor;
    id<MTLBinaryArchive> archive;
    NSURL *url;
    id<MTLBinaryArchive> loaded;
    id<MTLComputePipelineState> pipeline;
    id<MTLBuffer> output;
    id<MTLCommandBuffer> command;
    id<MTLComputeCommandEncoder> encoder;

    if (library == nil)
        return 1;
    pipeline_descriptor = [MTLComputePipelineDescriptor new];
    pipeline_descriptor.computeFunction = [library newFunctionWithName:@"from_archive"];
    archive = [device newBinaryArchiveWithDescriptor:[MTLBinaryArchiveDescriptor new]
                                               error:&error];
    if (archive == nil)
        return fail_error(error_out, error, "Metal did not vend a binary archive.");
    if (![archive addComputePipelineFunctionsWithDescriptor:pipeline_descriptor error:&error])
        return fail_error(error_out, error, "Metal did not add a pipeline to the archive.");
    url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:path]];
    if (![archive serializeToURL:url error:&error])
        return fail_error(error_out, error, "Metal did not serialize the binary archive.");
    {
        MTLBinaryArchiveDescriptor *loaded_descriptor = [MTLBinaryArchiveDescriptor new];

        loaded_descriptor.url = url;
        loaded = [device newBinaryArchiveWithDescriptor:loaded_descriptor error:&error];
    }
    if (loaded == nil)
        return fail_error(error_out, error, "Metal did not load the binary archive.");
    pipeline_descriptor.binaryArchives = @[loaded];
    pipeline = [device newComputePipelineStateWithDescriptor:pipeline_descriptor
                                                    options:MTLPipelineOptionNone
                                                 reflection:nil
                                                      error:&error];
    if (pipeline == nil)
        return fail_error(error_out, error, "Metal did not build a pipeline from the archive.");
    output = [device newBufferWithLength:4 options:MTLResourceStorageModeShared];
    memset(output.contents, 0, 4);
    command = [(__bridge id<MTLCommandQueue>)queue_pointer commandBuffer];
    encoder = [command computeCommandEncoder];
    [encoder setComputePipelineState:pipeline];
    [encoder setBuffer:output offset:0 atIndex:0];
    [encoder dispatchThreads:MTLSizeMake(1, 1, 1)
       threadsPerThreadgroup:MTLSizeMake(1, 1, 1)];
    [encoder endEncoding];
    if (finish_command(command, error_out) != 0)
        return 1;
    *value = *(int *)output.contents;
    return 0;
}

int
chorus_metal_compile_async(void *device_pointer, int *function_found, char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block id<MTLLibrary> library = nil;
    __block NSError *error = nil;

    if (error_out != NULL)
        *error_out = NULL;
    [device newLibraryWithSource:
            @"#include <metal_stdlib>\nusing namespace metal;\n"
            "kernel void async_kernel(device int *out [[buffer(0)]]) { out[0] = 1; }\n"
                            options:nil
                  completionHandler:^(id<MTLLibrary> compiled, NSError *compile_error) {
                      library = compiled;
                      error = compile_error;
                      dispatch_semaphore_signal(semaphore);
                  }];
    if (dispatch_semaphore_wait(semaphore,
                                dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)) != 0)
        return fail(error_out, "Metal asynchronous compile did not finish.");
    if (library == nil)
        return fail_error(error_out, error, "Metal asynchronous compile failed.");
    *function_found = [library newFunctionWithName:@"async_kernel"] != nil;
    return 0;
}

int
chorus_metal_drawable(void *device_pointer, void *queue_pointer,
                      unsigned char pixel[4], char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    NSWindow *window;
    CAMetalLayer *layer;
    id<CAMetalDrawable> drawable;
    MTLRenderPassDescriptor *pass;
    id<MTLCommandBuffer> command;
    id<MTLRenderCommandEncoder> encoder;
    id<MTLBuffer> readback;
    id<MTLBlitCommandEncoder> blit;

    if (error_out != NULL)
        *error_out = NULL;
    [NSApplication sharedApplication];
    window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 16, 16)
                                         styleMask:NSWindowStyleMaskBorderless
                                           backing:NSBackingStoreBuffered
                                             defer:NO];
    layer = [CAMetalLayer layer];
    layer.device = device;
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    layer.drawableSize = CGSizeMake(16, 16);
    layer.framebufferOnly = NO;
    window.contentView.wantsLayer = YES;
    window.contentView.layer = layer;
    drawable = [layer nextDrawable];
    if (drawable == nil)
        return fail(error_out, "Metal did not vend a drawable.");
    pass = [MTLRenderPassDescriptor renderPassDescriptor];
    pass.colorAttachments[0].texture = drawable.texture;
    pass.colorAttachments[0].loadAction = MTLLoadActionClear;
    pass.colorAttachments[0].storeAction = MTLStoreActionStore;
    pass.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 1.0);
    command = [(__bridge id<MTLCommandQueue>)queue_pointer commandBuffer];
    encoder = [command renderCommandEncoderWithDescriptor:pass];
    [encoder endEncoding];
    readback = [device newBufferWithLength:4 options:MTLResourceStorageModeShared];
    blit = [command blitCommandEncoder];
    [blit copyFromTexture:drawable.texture sourceSlice:0 sourceLevel:0
             sourceOrigin:MTLOriginMake(0, 0, 0) sourceSize:MTLSizeMake(1, 1, 1)
                 toBuffer:readback destinationOffset:0 destinationBytesPerRow:4
        destinationBytesPerImage:4];
    [blit endEncoding];
    [command presentDrawable:drawable];
    if (finish_command(command, error_out) != 0)
        return 1;
    memcpy(pixel, readback.contents, 4);
    return 0;
}

int
chorus_metal_tile(void *device_pointer, void *queue_pointer,
                  unsigned char pixel[4], char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    NSError *error = nil;
    id<MTLLibrary> library = compile_library
        (device,
         @"#include <metal_stdlib>\nusing namespace metal;\n"
         "struct Color { float4 value [[color(0)]]; };\n"
         "kernel void tile_kernel(imageblock<Color> block,\n"
         "                        ushort2 tid [[thread_position_in_threadgroup]]) {\n"
         "  Color color;\n"
         "  color.value = float4(0.0, 1.0, 0.0, 1.0);\n"
         "  block.write(color, tid);\n"
         "}\n",
         error_out);
    MTLTileRenderPipelineDescriptor *pipeline_descriptor;
    id<MTLRenderPipelineState> pipeline;
    MTLTextureDescriptor *texture_descriptor;
    id<MTLTexture> texture;
    MTLRenderPassDescriptor *pass;
    id<MTLCommandBuffer> command;
    id<MTLRenderCommandEncoder> encoder;

    if (library == nil)
        return 1;
    pipeline_descriptor = [MTLTileRenderPipelineDescriptor new];
    pipeline_descriptor.tileFunction = [library newFunctionWithName:@"tile_kernel"];
    pipeline_descriptor.threadgroupSizeMatchesTileSize = YES;
    pipeline_descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA8Unorm;
    pipeline = [device newRenderPipelineStateWithTileDescriptor:pipeline_descriptor
                                                       options:MTLPipelineOptionNone
                                                    reflection:nil
                                                         error:&error];
    if (pipeline == nil)
        return fail_error(error_out, error, "Metal tile pipeline failed.");
    texture_descriptor =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                           width:32 height:32 mipmapped:NO];
    texture_descriptor.storageMode = MTLStorageModeShared;
    texture_descriptor.usage = MTLTextureUsageRenderTarget;
    texture = [device newTextureWithDescriptor:texture_descriptor];
    pass = [MTLRenderPassDescriptor renderPassDescriptor];
    pass.colorAttachments[0].texture = texture;
    pass.colorAttachments[0].loadAction = MTLLoadActionClear;
    pass.colorAttachments[0].storeAction = MTLStoreActionStore;
    pass.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
    command = [(__bridge id<MTLCommandQueue>)queue_pointer commandBuffer];
    encoder = [command renderCommandEncoderWithDescriptor:pass];
    if (encoder.tileWidth == 0 || encoder.tileHeight == 0)
        return fail(error_out, "Metal did not choose a tile size.");
    [encoder setRenderPipelineState:pipeline];
    [encoder dispatchThreadsPerTile:MTLSizeMake(encoder.tileWidth, encoder.tileHeight, 1)];
    [encoder endEncoding];
    if (finish_command(command, error_out) != 0)
        return 1;
    [texture getBytes:pixel bytesPerRow:128 fromRegion:MTLRegionMake2D(0, 0, 1, 1)
          mipmapLevel:0];
    return 0;
}

int
chorus_metal_mesh(void *device_pointer, void *queue_pointer,
                  unsigned char pixel[4], char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    NSError *error = nil;
    id<MTLLibrary> library = compile_library
        (device,
         @"#include <metal_stdlib>\nusing namespace metal;\n"
         "struct Vertex { float4 position [[position]]; };\n"
         "using Mesh = mesh<Vertex, void, 3, 1, topology::triangle>;\n"
         "[[mesh]] void mesh_main(Mesh output, uint tid [[thread_index_in_threadgroup]]) {\n"
         "  if (tid == 0) {\n"
         "    output.set_primitive_count(1);\n"
         "    Vertex point;\n"
         "    point.position = float4(-1.0, -1.0, 0.0, 1.0);\n"
         "    output.set_vertex(0, point);\n"
         "    point.position = float4(1.0, -1.0, 0.0, 1.0);\n"
         "    output.set_vertex(1, point);\n"
         "    point.position = float4(0.0, 1.0, 0.0, 1.0);\n"
         "    output.set_vertex(2, point);\n"
         "    output.set_index(0, 0);\n"
         "    output.set_index(1, 1);\n"
         "    output.set_index(2, 2);\n"
         "  }\n"
         "}\n"
         "fragment float4 mesh_fragment() { return float4(0.0, 0.0, 1.0, 1.0); }\n",
         error_out);
    MTLMeshRenderPipelineDescriptor *pipeline_descriptor;
    id<MTLRenderPipelineState> pipeline;
    MTLTextureDescriptor *texture_descriptor;
    id<MTLTexture> texture;
    MTLRenderPassDescriptor *pass;
    id<MTLCommandBuffer> command;
    id<MTLRenderCommandEncoder> encoder;

    if (library == nil)
        return 1;
    pipeline_descriptor = [MTLMeshRenderPipelineDescriptor new];
    pipeline_descriptor.meshFunction = [library newFunctionWithName:@"mesh_main"];
    pipeline_descriptor.fragmentFunction = [library newFunctionWithName:@"mesh_fragment"];
    pipeline_descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA8Unorm;
    pipeline = [device newRenderPipelineStateWithMeshDescriptor:pipeline_descriptor
                                                       options:MTLPipelineOptionNone
                                                    reflection:nil
                                                         error:&error];
    if (pipeline == nil)
        return fail_error(error_out, error, "Metal mesh pipeline failed.");
    texture_descriptor =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                           width:8 height:8 mipmapped:NO];
    texture_descriptor.storageMode = MTLStorageModeShared;
    texture_descriptor.usage = MTLTextureUsageRenderTarget;
    texture = [device newTextureWithDescriptor:texture_descriptor];
    pass = [MTLRenderPassDescriptor renderPassDescriptor];
    pass.colorAttachments[0].texture = texture;
    pass.colorAttachments[0].loadAction = MTLLoadActionClear;
    pass.colorAttachments[0].storeAction = MTLStoreActionStore;
    pass.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
    command = [(__bridge id<MTLCommandQueue>)queue_pointer commandBuffer];
    encoder = [command renderCommandEncoderWithDescriptor:pass];
    [encoder setRenderPipelineState:pipeline];
    [encoder drawMeshThreadgroups:MTLSizeMake(1, 1, 1)
      threadsPerObjectThreadgroup:MTLSizeMake(1, 1, 1)
        threadsPerMeshThreadgroup:MTLSizeMake(1, 1, 1)];
    [encoder endEncoding];
    if (finish_command(command, error_out) != 0)
        return 1;
    [texture getBytes:pixel bytesPerRow:32 fromRegion:MTLRegionMake2D(4, 4, 1, 1)
          mipmapLevel:0];
    return 0;
}

int
chorus_metal_memoryless(void *device_pointer, unsigned long *mode, char **error_out)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)device_pointer;
    MTLTextureDescriptor *descriptor =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                           width:4 height:4 mipmapped:NO];
    id<MTLTexture> texture;

    if (error_out != NULL)
        *error_out = NULL;
    descriptor.storageMode = MTLStorageModeMemoryless;
    descriptor.usage = MTLTextureUsageRenderTarget;
    texture = [device newTextureWithDescriptor:descriptor];
    if (texture == nil)
        return fail(error_out, "Metal did not vend a memoryless texture.");
    *mode = (unsigned long)texture.storageMode;
    return 0;
}
