/*
  Simple DirectMedia Layer
  Copyright (C) 1997-2023 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/
#include "../../SDL_internal.h"

#if SDL_VIDEO_DRIVER_UIKIT && (SDL_VIDEO_OPENGL_ES || SDL_VIDEO_OPENGL_ES2)


#import <GLES2/gl2.h>
#import <GLES2/gl2ext.h>
#import <GLES3/gl3.h>
#import <MGLKit.h>
#import "SDL_uikitopenglview.h"
#include "SDL_uikitwindow.h"

@implementation SDL_uikitopenglview {
    /* The renderbuffer and framebuffer used to render to this layer. */
    GLuint viewRenderbuffer, viewFramebuffer;

    /* The depth buffer that is attached to viewFramebuffer, if it exists. */
    // GLuint depthRenderbuffer;

    // GLenum colorBufferFormat;

    /* format of depthRenderbuffer */
    GLenum depthBufferFormat;

    /* The framebuffer and renderbuffer used for rendering with MSAA. */
    // GLuint msaaFramebuffer, msaaRenderbuffer;

    /* The number of MSAA samples. */
    int samples;

    BOOL retainedBacking;
}

@synthesize context;
@synthesize backingWidth;
@synthesize backingHeight;

+ (Class)layerClass
{
    return [MGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
                        scale:(CGFloat)scale
                retainBacking:(BOOL)retained
                        rBits:(int)rBits
                        gBits:(int)gBits
                        bBits:(int)bBits
                        aBits:(int)aBits
                    depthBits:(int)depthBits
                  stencilBits:(int)stencilBits
                         sRGB:(BOOL)sRGB
                 multisamples:(int)multisamples
                      context:(MGLContext *)glcontext
{
    if ((self = [super initWithFrame:frame])) {
        const BOOL useStencilBuffer = (stencilBits != 0);
        const BOOL useDepthBuffer = (depthBits != 0);
        int colorFormat;

        context = glcontext;
        samples = multisamples;
        retainedBacking = retained;
        
        MGLLayer *eaglLayer = (MGLLayer *)self.layer;

        if (samples > 0) {
            GLint maxsamples = 0;
            glGetIntegerv(GL_MAX_SAMPLES, &maxsamples);
            /* Clamp the samples to the max supported count. */
            samples = SDL_min(samples, maxsamples);
        }

        if (sRGB) {
            colorFormat = MGLDrawableColorFormatSRGBA8888;
        } else if (rBits >= 8 || gBits >= 8 || bBits >= 8 || aBits > 0) {
            /* if user specifically requests rbg888 or some color format higher than 16bpp */
            colorFormat = MGLDrawableColorFormatRGBA8888;
        } else {
            /* default case (potentially faster) */
            colorFormat = MGLDrawableColorFormatRGB565;;
        }

        eaglLayer.opaque = YES;
        
        eaglLayer.drawableColorFormat = colorFormat;
        eaglLayer.retainedBacking = retained;

        /* Set the appropriate scale (for retina display support) */
        self.contentScaleFactor = scale;
        
        eaglLayer.contentsScale = scale;
        
        if (!context || ![MGLContext setCurrentContext:context]) {
            SDL_SetError("Could not create OpenGL ES drawable (could not make context current)");
            return nil;
        }
        
        viewFramebuffer = eaglLayer.defaultOpenGLFrameBufferID;
        
        backingWidth = eaglLayer.drawableSize.width;
        backingHeight = eaglLayer.drawableSize.height;

        if (samples > 0) {
            eaglLayer.drawableMultisample = samples;
        }

        if (useDepthBuffer || useStencilBuffer) {
            if (useDepthBuffer) {
                eaglLayer.drawableDepthFormat = MGLDrawableDepthFormat16;
            }
            if (useStencilBuffer) {
                eaglLayer.drawableStencilFormat = MGLDrawableStencilFormat8;
            }
        }

        [self setDebugLabels];
    }

    return self;
}

- (GLuint)drawableRenderbuffer
{
    return viewFramebuffer;
}

- (GLuint)drawableFramebuffer
{
    return viewFramebuffer;
}

- (GLuint)msaaResolveFramebuffer
{
    return viewFramebuffer;
}

- (void)setDebugLabels
{
    /*
    if (viewFramebuffer != 0) {
        glLabelObjectEXT(GL_FRAMEBUFFER, viewFramebuffer, 0, "context FBO");
    }

    if (viewRenderbuffer != 0) {
        glLabelObjectEXT(GL_RENDERBUFFER, viewRenderbuffer, 0, "context color buffer");
    }

    if (depthRenderbuffer != 0) {
        if (depthBufferFormat == GL_DEPTH24_STENCIL8_OES) {
            glLabelObjectEXT(GL_RENDERBUFFER, depthRenderbuffer, 0, "context depth-stencil buffer");
        } else {
            glLabelObjectEXT(GL_RENDERBUFFER, depthRenderbuffer, 0, "context depth buffer");
        }
    }

    if (msaaFramebuffer != 0) {
        glLabelObjectEXT(GL_FRAMEBUFFER, msaaFramebuffer, 0, "context MSAA FBO");
    }

    if (msaaRenderbuffer != 0) {
        glLabelObjectEXT(GL_RENDERBUFFER, msaaRenderbuffer, 0, "context MSAA renderbuffer");
    }
     */
}

- (void)swapBuffers
{
    MGLLayer *eaglLayer = (MGLLayer *)self.layer;
    [MGLContext setCurrentContext:context forLayer:eaglLayer];
    [context present:eaglLayer];

}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    int width  = (int) (self.bounds.size.width * self.contentScaleFactor);
    int height = (int) (self.bounds.size.height * self.contentScaleFactor);

    /* Update the color and depth buffer storage if the layer size has changed. */
    
    if (width != backingWidth || height != backingHeight) {
            MGLLayer *eaglLayer = (MGLLayer *)self.layer;
            [MGLContext setCurrentContext:context forLayer:eaglLayer];
            backingWidth = eaglLayer.drawableSize.width;
            backingHeight = eaglLayer.drawableSize.height;
    }
}

- (void)destroyFramebuffer
{
    /*
    if (viewFramebuffer != 0) {
        glDeleteFramebuffers(1, &viewFramebuffer);
        viewFramebuffer = 0;
    }
    if (viewRenderbuffer != 0) {
        glDeleteRenderbuffers(1, &viewRenderbuffer);
        viewRenderbuffer = 0;
    }
    if (depthRenderbuffer != 0) {
        glDeleteRenderbuffers(1, &depthRenderbuffer);
        depthRenderbuffer = 0;
    }

    if (msaaFramebuffer != 0) {
        glDeleteFramebuffers(1, &msaaFramebuffer);
        msaaFramebuffer = 0;
    }

    if (msaaRenderbuffer != 0) {
        glDeleteRenderbuffers(1, &msaaRenderbuffer);
        msaaRenderbuffer = 0;
    }*/
}

- (void)dealloc
{
    if (context && context == [MGLContext currentContext]) {
        [self destroyFramebuffer];
        [MGLContext setCurrentContext:nil];
    }
}

@end

#endif /* SDL_VIDEO_DRIVER_UIKIT */

/* vi: set ts=4 sw=4 expandtab: */
