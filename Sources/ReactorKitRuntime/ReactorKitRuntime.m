#import "ReactorKitRuntime.h"
#import <objc/runtime.h>

@implementation ReactorKitRuntime

+ (void)load {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self swizzleViewDidLoad:@"UIViewController"];
    [self swizzleViewDidLoad:@"NSViewController"];
  });
}

+ (void)swizzleViewDidLoad:(NSString *)className {
  Class class = NSClassFromString(className);
  if (!class) {
    return;
  }
  SEL oldSelector = @selector(viewDidLoad);
  SEL newSelector = @selector(reactorkit_viewDidLoad);
  SEL performBindingSelector = @selector(reactorkit_performBinding);

  Method oldMethod = class_getInstanceMethod(class, oldSelector);
  const char *types = method_getTypeEncoding(oldMethod);

  IMP newMethodImp = imp_implementationWithBlock(^(__unsafe_unretained id self, va_list arguments) {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:newSelector]; // call original method
    if ([self respondsToSelector:performBindingSelector]) {
      [self performSelector:performBindingSelector];
    }
    #pragma clang diagnostic pop
  });
  class_addMethod(class, newSelector, newMethodImp, types);
  method_exchangeImplementations(class_getInstanceMethod(class, oldSelector),
                                 class_getInstanceMethod(class, newSelector));
}

@end
