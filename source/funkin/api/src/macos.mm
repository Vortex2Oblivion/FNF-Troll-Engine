#include "macos.hpp"

#include <Cocoa/Cocoa.h>

namespace macos{
    void fixWindowColorSpace(void* window) {
       auto nativeWindow = (NSWindow*)window;

       if (nativeWindow == nullptr) {
           return;
       }

       [nativeWindow setColorSpace: [NSColorSpace sRGBColorSpace]];
    }
}