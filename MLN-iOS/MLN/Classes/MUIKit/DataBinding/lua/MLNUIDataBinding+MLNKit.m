//
//  MLNUIDataBinding+MLNUIKit.m
// MLNUI
//
//  Created by Dai Dongpeng on 2020/3/3.
//

#import "MLNUIDataBinding+MLNKit.h"
#import "MLNUIStaticExporterMacro.h"
#import "MLNUIKitHeader.h"
#import "MLNUIKitViewController.h"
#import "MLNUIBlock.h"
#import "MLNUIBlockObserver.h"
#import "MLNUIListViewObserver.h"
#import "NSObject+MLNUIKVO.h"
#import "NSArray+MLNUIKVO.h"
#import "NSDictionary+MLNUIKVO.h"
#import "NSArray+MLNUISafety.h"
#import "MLNUITableView.h"
#import "NSObject+MLNUIReflect.h"

@implementation MLNUIDataBinding (MLNUIKit)

+ (NSString *)lua_watchDataForKeys:(NSArray *)keys handler:(MLNUIBlock *)handler {
    NSParameterAssert(keys && handler);
    if(!keys || !handler)  return nil;
    UIViewController<MLNUIDataBindingProtocol> *kitViewController = (UIViewController<MLNUIDataBindingProtocol> *)MLNUI_KIT_INSTANCE([self mln_currentLuaCore]).viewController;
    
    if ([keys isKindOfClass:[NSArray class]]) {
        NSString *keyPath = [keys componentsJoinedByString:@"."];
        NSObject<MLNUIKVOObserverProtol> *observer = [MLNUIBlockObserver observerWithBlock:handler keyPath:keyPath];
        return [kitViewController.mln_dataBinding addMLNUIObserver:observer forKeys:keys];
    } else if([keys isKindOfClass:[NSString class]]){
        NSString *keyPath = (NSString *)keys;
        NSObject<MLNUIKVOObserverProtol> *observer = [MLNUIBlockObserver observerWithBlock:handler keyPath:keyPath];
        return [kitViewController.mln_dataBinding addMLNUIObserver:observer forKeyPath:keyPath];
    }
    return nil;
}

+ (void)lua_updateDataForKeys:(NSArray *)keys value:(id)value {
    NSParameterAssert(keys);
    if(!keys) return;
    
    UIViewController<MLNUIDataBindingProtocol> *kitViewController = (UIViewController<MLNUIDataBindingProtocol> *)MLNUI_KIT_INSTANCE([self mln_currentLuaCore]).viewController;
    NSObject *obj = [value mln_convertToNativeObject];
    
    if ([keys isKindOfClass:[NSArray class]]) {
        [kitViewController.mln_dataBinding updateDataForKeys:keys value:obj];
    } else if([keys isKindOfClass:[NSString class]]) {
        [kitViewController.mln_dataBinding updateDataForKeyPath:(NSString *)keys value:obj];
    }
}

+ (id __nullable)lua_dataForKeys:(NSArray *)keys {
    NSParameterAssert(keys);
    if(!keys) return nil;
    UIViewController<MLNUIDataBindingProtocol> *kitViewController = (UIViewController<MLNUIDataBindingProtocol> *)MLNUI_KIT_INSTANCE([self mln_currentLuaCore]).viewController;
    NSObject *obj;

    if ([keys isKindOfClass:[NSArray class]]) {
        obj = [kitViewController.mln_dataBinding dataForKeys:keys];
    } else if ([keys isKindOfClass:[NSString class]]) {
       obj = [self mln_dataForKeyPath:(NSString *)keys];
    }
    return [obj mln_convertToLuaObject];
}

+ (id)mln_dataForKeyPath:(NSString *)keyPath {
    NSParameterAssert(keyPath);
    if(!keyPath) return nil;
    
    UIViewController<MLNUIDataBindingProtocol> *kitViewController = (UIViewController<MLNUIDataBindingProtocol> *)MLNUI_KIT_INSTANCE([self mln_currentLuaCore]).viewController;
    NSObject *obj = [kitViewController.mln_dataBinding dataForKeyPath:keyPath];
    return obj;
}

+ (void)lua_removeMLNUIObserverByID:(NSString *)observerID {
    NSParameterAssert(observerID);
    if(!observerID) return;
    UIViewController<MLNUIDataBindingProtocol> *kitViewController = (UIViewController<MLNUIDataBindingProtocol> *)MLNUI_KIT_INSTANCE([self mln_currentLuaCore]).viewController;
    [kitViewController.mln_dataBinding removeMLNUIObserverByID:observerID];
}

+ (void)lua_mockForKey:(NSString *)key data:(NSDictionary *)dic {
    NSParameterAssert(key);
    if(!key) return;
    
    UIViewController<MLNUIDataBindingProtocol> *kitViewController = (UIViewController<MLNUIDataBindingProtocol> *)MLNUI_KIT_INSTANCE([self mln_currentLuaCore]).viewController;
//    if ([dic isKindOfClass:[NSArray class]]) {
//        return [self lua_mockArrayForKey:key data:(NSArray *)dic callbackDic:nil];
//    }
    if (![dic isKindOfClass:[NSDictionary class]]) {
        NSLog(@"error %s, should be NSDictionary",__func__);
        return;
    }
//    NSMutableDictionary *map = dic.mln_mutalbeCopy;
    NSMutableDictionary *map = [dic mln_convertToNativeObject];
    [kitViewController.mln_dataBinding bindData:map forKey:key];
}

+ (void)lua_mockArrayForKey:(NSString *)key data:(NSArray *)data callbackDic:(NSDictionary *)callbackDic {
    NSParameterAssert(key && data);
    if(!key || !data) return;
    
    UIViewController<MLNUIDataBindingProtocol> *kitViewController = (UIViewController<MLNUIDataBindingProtocol> *)MLNUI_KIT_INSTANCE([self mln_currentLuaCore]).viewController;
    
    NSMutableArray *existData = [kitViewController.mln_dataBinding dataForKeyPath:key];
    if ([existData isKindOfClass:[NSMutableArray class]]) {
        [existData mln_startKVOIfMutable];
        return;
    }
    
    if (![data isKindOfClass:[NSArray class]]) {
        NSLog(@"error %s, should be NSArray",__func__);
        return;
    }
    NSMutableArray *array = [data mln_convertToNativeObject];
    [array mln_startKVOIfMutable];
    [kitViewController.mln_dataBinding bindArray:array forKey:key];

//    NSMutableArray *arr = [[kitViewController.mln_dataBinding dataForKeyPath:key] mutableCopy];
//    if (![arr isKindOfClass:[NSMutableArray class]]) {
//        NSLog(@"data of keypath: %@ is %@ , it should be NSMutableArray!",key, data);
//        return nil;
//    }
//    [kitViewController.mln_dataBinding updateDataForKeyPath:key value:arr];
//    [arr mln_startKVOIfMutable];
//    return arr;
}

#pragma mark - ListView
//+ (void)lua_bindListViewForKey:(NSString *)key listView:(UIView *)listView {
//    MLNUIKitViewController *kitViewController = (MLNUIKitViewController *)MLNUI_KIT_INSTANCE([self mln_currentLuaCore]).viewController;
//    MLNUIListViewObserver *observer = [MLNUIListViewObserver observerWithListView:listView keyPath:key];
//    [kitViewController.dataBinding addArrayObserver:observer forKey:key];
//}

// userData.source
+ (void)lua_bindListViewForKey:(NSString *)key listView:(UIView *)listView {
    NSParameterAssert(key && listView);
    if(!key || !listView) return;
    
    UIViewController<MLNUIDataBindingProtocol> *kitViewController = (UIViewController<MLNUIDataBindingProtocol> *)MLNUI_KIT_INSTANCE([self mln_currentLuaCore]).viewController;
    MLNUIListViewObserver *observer = [MLNUIListViewObserver observerWithListView:listView keyPath:key];
    
    [kitViewController.mln_dataBinding addMLNUIObserver:observer forKeyPath:key];
}

+ (NSUInteger)lua_sectionCountForKey:(NSString *)key {
    NSParameterAssert(key);
    if(!key) return 0;
    
    NSArray *arr = [self mln_dataForKeyPath:key];
    if (arr.mln_is2D) {
        return arr.count;
    }
    return 1;
}

+ (NSUInteger)lua_rowCountForKey:(NSString *)key section:(NSUInteger)section{
    NSParameterAssert(key);
    if(!key) return 0;
    
    NSArray *arr = [self mln_dataForKeyPath:key];
    if (section > arr.count || section == 0) {
        return 0;
    }
    
    if (arr.mln_is2D) {
        return [[arr mln_objectAtIndex:section - 1] count];
    }

    return arr.count;
}

+ (id)lua_modelForKey:(NSString *)key section:(NSUInteger)section row:(NSUInteger)row path:(NSString *)path {
    NSParameterAssert(key);
    if(!key) return nil;
    
    NSArray *array = [self mln_dataForKeyPath:key];
    id resust;
    @try {
        id tmp;
        if (array.mln_is2D) {
            tmp = [[[array mln_objectAtIndex:section - 1] mln_objectAtIndex:row - 1] mln_valueForKeyPath:path];
        } else {
            tmp = [[array mln_objectAtIndex:row - 1] mln_valueForKeyPath:path];
        }
        resust = [tmp mln_convertToLuaObject];
    } @catch (NSException *exception) {
        NSLog(@"%s exception: %@",__func__, exception);
    }
    return resust;
}

+ (void)lua_updateModelForKey:(NSString *)key section:(NSUInteger)section row:(NSUInteger)row path:(NSString *)path value:(id)value {
    NSParameterAssert(key);
    if(!key) return;
    
    NSArray *array = [self mln_dataForKeyPath:key];
    @try {
        NSObject *object;
        if (array.mln_is2D) {
            object = [[array mln_objectAtIndex:section - 1] mln_objectAtIndex:row - 1];
        } else {
            object = [array mln_objectAtIndex:row - 1];
        }
        
//        id oldValue = [object valueForKeyPath:path];
        NSObject *newValue = [value mln_convertToNativeObject];
        [object setValue:newValue forKeyPath:path];
        
    } @catch (NSException *exception) {
        NSLog(@"%s exception: %@",__func__, exception);
    }
}

+ (void)lua_bindCellForKey:(NSString *)key section:(NSUInteger)section row:(NSUInteger)row paths:(NSArray *)paths {
    NSParameterAssert(key && paths);
    if (!key || !paths) return;
    
    UIViewController<MLNUIDataBindingProtocol> *kitViewController = (UIViewController<MLNUIDataBindingProtocol> *)MLNUI_KIT_INSTANCE([self mln_currentLuaCore]).viewController;

    NSArray *array = [self mln_dataForKeyPath:key];
    MLNUIListViewObserver *listObserver = (MLNUIListViewObserver *)[kitViewController.mln_dataBinding observersForKeyPath:key].lastObject;
    if (![listObserver isKindOfClass:[MLNUIListViewObserver class]]) {
        NSLog(@"error: not found observer for key %@",key);
        return;
    }
    
    NSObject *model;
    if (array.mln_is2D) {
        model = [[array mln_objectAtIndex:section - 1] mln_objectAtIndex:row - 1];
    } else {
        model = [array mln_objectAtIndex:row - 1];
    }
    
    for (NSString *k in paths) {
        [model mln_removeObervationsForOwner:kitViewController.mln_dataBinding keyPath:k];
    }

    //TODO: 如果paths中有属性对应可变数组？
    [kitViewController.mln_dataBinding mln_observeObject:model properties:paths withBlock:^(id  _Nonnull observer, id  _Nonnull object, NSString * _Nonnull keyPath, id  _Nonnull oldValue, id  _Nonnull newValue, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull change) {
        UIView *listView = [listObserver listView];
        if ([listView isKindOfClass:[MLNUITableView class]]) {
            MLNUITableView *table = (MLNUITableView *)listView;
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row - 1 inSection:section - 1];
            [table.adapter tableView:table.adapter.targetTableView reloadRowsAtIndexPaths:@[indexPath]];
            [table.adapter.targetTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        } else {
            
        }
    }];
}

#pragma mark - BindArray

+ (void)lua_bindArrayForKeyPath:(NSString *)keyPath handler:(MLNUIBlock *)handler {
    NSParameterAssert(handler && keyPath);
    if (!handler || !keyPath) return;
    
    UIViewController<MLNUIDataBindingProtocol> *kitViewController = (UIViewController<MLNUIDataBindingProtocol> *)MLNUI_KIT_INSTANCE([self mln_currentLuaCore]).viewController;
//    __weak id<MLNUIDataBindingProtocol> weakController = kitViewController;
    __block __weak NSObject<MLNUIKVOObserverProtol>* weakOb;
    
    NSObject<MLNUIKVOObserverProtol> *observer = [[MLNUIKVOObserver alloc] initWithViewController:kitViewController callback:^(NSString * _Nonnull kp, NSArray *  _Nonnull object, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull change) {
        /*
        if (!handler.luaCore && weakOb) {
            [weakController.mln_dataBinding removeArrayObserver:weakOb forKeyPath:keyPath];
            weakOb = nil;
            return;
        }
         */
        NSKeyValueChange type = [[change objectForKey:NSKeyValueChangeKindKey] unsignedIntegerValue];
        if (type == NSKeyValueChangeSetting) {
            object = [change objectForKey:NSKeyValueChangeNewKey];
        }
        if (handler && [object isKindOfClass:[NSArray class]]) {
            NSArray *n = [object mln_convertToLuaObject];
            [handler addObjArgument:n];
            [handler callIfCan];
        } else {
            NSAssert(false, @"object: %@ should be array",object);
        }
        
    } keyPath:keyPath];
    
    weakOb = observer;
    [kitViewController.mln_dataBinding addMLNUIObserver:observer forKeyPath:keyPath];
}

+ (void)lua_bindArrayDataForKey:(NSString *)key index:(NSUInteger)index dataKeyPath:(NSString *)dataKeyPath handler:(MLNUIBlock *)handler {
    NSParameterAssert(key && handler && dataKeyPath);
    if(!key || !handler || !dataKeyPath) return;
    
    index -= 1;
    UIViewController<MLNUIDataBindingProtocol> *kitViewController = (UIViewController<MLNUIDataBindingProtocol> *)MLNUI_KIT_INSTANCE([self mln_currentLuaCore]).viewController;
    NSArray *array = [kitViewController.mln_dataBinding dataForKeyPath:key];
    if ([array isKindOfClass:[NSArray class]] && index < [array count]) {
        NSObject *obj = [array objectAtIndex:index];
        [kitViewController.mln_dataBinding mln_observeObject:obj property:dataKeyPath withBlock:^(id  _Nonnull observer, id  _Nonnull object, id  _Nonnull oldValue, id  _Nonnull newValue, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull change) {
            [handler addObjArgument:[newValue mln_convertToLuaObject]];
            [handler addObjArgument:[oldValue mln_convertToLuaObject]];
            [handler callIfCan];
        }];
    }
}

+ (void)lua_updateArrayDataForKey:(NSString *)key index:(NSUInteger)index dataKeyPath:(NSString *)dataKeyPath newValue:(id)newValue {
    NSParameterAssert(key && dataKeyPath);
    if(!key || !dataKeyPath) return;
    
    index -= 1;
    UIViewController<MLNUIDataBindingProtocol> *kitViewController = (UIViewController<MLNUIDataBindingProtocol> *)MLNUI_KIT_INSTANCE([self mln_currentLuaCore]).viewController;
    NSArray *array = [kitViewController.mln_dataBinding dataForKeyPath:key];
    if ([array isKindOfClass:[NSArray class]] && index < [array count]) {
        NSObject *obj = [array objectAtIndex:index];
        @try {
            [obj setValue:[newValue mln_convertToNativeObject] forKey:dataKeyPath];
        } @catch (NSException *exception) {
            NSLog(@"%s exception: %@",__func__,exception);
        }
    }
}

+ (id)lua_getArrayDataForKey:(NSString *)key index:(NSUInteger)index dataKeyPath:(NSString *)dataKeyPath {
    NSParameterAssert(key);
    if(!key) return nil;
    
    index -= 1;
    id ret;
    UIViewController<MLNUIDataBindingProtocol> *kitViewController = (UIViewController<MLNUIDataBindingProtocol> *)MLNUI_KIT_INSTANCE([self mln_currentLuaCore]).viewController;
    NSArray *array = [kitViewController.mln_dataBinding dataForKeyPath:key];
    if ([array isKindOfClass:[NSArray class]] && index < [array count]) {
        @try {
            NSObject *obj = [array objectAtIndex:index];
            id newObj = [obj mln_valueForKeyPath:dataKeyPath];
            ret = [newObj mln_convertToLuaObject];
        } @catch (NSException *exception) {
            NSLog(@"%s exception: %@",__func__,exception);
        }
    }
    return ret;
}

+ (void)lua_aliasArrayDataForKey:(NSString *)key index:(NSUInteger)index alias:(NSString *)alias {
    NSParameterAssert(key && alias);
    if(!key || !alias)  return;
    
    index -= 1;
    UIViewController<MLNUIDataBindingProtocol> *kitViewController = (UIViewController<MLNUIDataBindingProtocol> *)MLNUI_KIT_INSTANCE([self mln_currentLuaCore]).viewController;
    NSArray *array = [kitViewController.mln_dataBinding dataForKeyPath:key];
    if ([array isKindOfClass:[NSArray class]] && index < [array count]) {
        @try {
            NSObject *obj = [array objectAtIndex:index];
            if (obj) {
                [kitViewController.mln_dataBinding bindData:obj forKey:alias];
            }
        } @catch (NSException *exception) {
            NSLog(@"%s exception: %@",__func__,exception);
        }
    }
}

#pragma mark - Setup For Lua
LUA_EXPORT_STATIC_BEGIN(MLNUIDataBinding)
LUA_EXPORT_STATIC_METHOD(bind, "lua_watchDataForKeys:handler:", MLNUIDataBinding)
LUA_EXPORT_STATIC_METHOD(update, "lua_updateDataForKeys:value:", MLNUIDataBinding)
LUA_EXPORT_STATIC_METHOD(get, "lua_dataForKeys:", MLNUIDataBinding)
LUA_EXPORT_STATIC_METHOD(remove, "lua_removeMLNUIObserverByID:", MLNUIDataBinding)

LUA_EXPORT_STATIC_METHOD(mock, "lua_mockForKey:data:", MLNUIDataBinding)
LUA_EXPORT_STATIC_METHOD(mockArray, "lua_mockArrayForKey:data:callbackDic:", MLNUIDataBinding)

LUA_EXPORT_STATIC_METHOD(bindListView, "lua_bindListViewForKey:listView:", MLNUIDataBinding)
LUA_EXPORT_STATIC_METHOD(getSectionCount, "lua_sectionCountForKey:", MLNUIDataBinding)
LUA_EXPORT_STATIC_METHOD(getRowCount, "lua_rowCountForKey:section:", MLNUIDataBinding)
LUA_EXPORT_STATIC_METHOD(getModel, "lua_modelForKey:section:row:path:", MLNUIDataBinding)
LUA_EXPORT_STATIC_METHOD(updateModel, "lua_updateModelForKey:section:row:path:value:", MLNUIDataBinding)
//LUA_EXPORT_STATIC_METHOD(getReuseId, "lua_reuseIdForKey:section:row:", MLNUIDataBinding)
//LUA_EXPORT_STATIC_METHOD(getHeight, "lua_heightForKey:section:row:", MLNUIDataBinding)
LUA_EXPORT_STATIC_METHOD(bindCell, "lua_bindCellForKey:section:row:paths:", MLNUIDataBinding)

//LUA_EXPORT_STATIC_METHOD(getSize, "lua_sizeForKey:section:row:", MLNUIDataBinding)
LUA_EXPORT_STATIC_METHOD(bindArray, "lua_bindArrayForKeyPath:handler:", MLNUIDataBinding)
LUA_EXPORT_STATIC_METHOD(bindArrayData, "lua_bindArrayDataForKey:index:dataKeyPath:handler:", MLNUIDataBinding)
LUA_EXPORT_STATIC_METHOD(updateArrayData, "lua_updateArrayDataForKey:index:dataKeyPath:newValue:", MLNUIDataBinding)
LUA_EXPORT_STATIC_METHOD(getArrayData, "lua_getArrayDataForKey:index:dataKeyPath:", MLNUIDataBinding)
LUA_EXPORT_STATIC_METHOD(aliasArrayData, "lua_aliasArrayDataForKey:index:alias:", MLNUIDataBinding)

LUA_EXPORT_STATIC_END(MLNUIDataBinding, DataBinding, NO, NULL)

@end
