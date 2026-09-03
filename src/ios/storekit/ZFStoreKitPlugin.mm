// Godot <-> StoreKit 2 bridge for iOS.
//
// This file owns no commerce logic. It registers one Godot singleton whose four
// methods forward to ZFStoreKit.swift, and turns that class's delegate callbacks
// into Godot signals. The GDScript side (core/commerce/store_backend.gd)
// documents the same contract from the other direction.

#import <Foundation/Foundation.h>

#include "core/config/engine.h"
#include "core/object/class_db.h"
#include "core/variant/array.h"
#include "core/variant/dictionary.h"

#import "ZFStoreKitSwift-Swift.h"

class ZombieFireStoreKit;

// Objective-C shim: Swift needs an NSObject delegate, Godot needs a C++ object.
@interface ZFStoreKitForwarder : NSObject <ZFStoreKitDelegate>
@property(nonatomic, assign) ZombieFireStoreKit *owner;
@end

class ZombieFireStoreKit : public Object {
	GDCLASS(ZombieFireStoreKit, Object);

	static ZombieFireStoreKit *instance;
	ZFStoreKitForwarder *forwarder = nil;

protected:
	static void _bind_methods() {
		ClassDB::bind_method(D_METHOD("initialize", "product_ids"), &ZombieFireStoreKit::initialize);
		ClassDB::bind_method(D_METHOD("purchase", "product_id"), &ZombieFireStoreKit::purchase);
		ClassDB::bind_method(D_METHOD("restore"), &ZombieFireStoreKit::restore);
		ClassDB::bind_method(D_METHOD("refresh_entitlements"), &ZombieFireStoreKit::refresh_entitlements);

		ADD_SIGNAL(MethodInfo("products_loaded", PropertyInfo(Variant::ARRAY, "products")));
		ADD_SIGNAL(MethodInfo("transaction_updated", PropertyInfo(Variant::DICTIONARY, "transaction")));
		ADD_SIGNAL(MethodInfo("entitlements_synced", PropertyInfo(Variant::ARRAY, "product_ids")));
		ADD_SIGNAL(MethodInfo("store_error", PropertyInfo(Variant::STRING, "message")));
	}

public:
	static ZombieFireStoreKit *get_singleton() { return instance; }

	void initialize(const PackedStringArray &p_product_ids) {
		if (@available(iOS 15.0, *)) {
			NSMutableArray<NSString *> *ids = [NSMutableArray arrayWithCapacity:p_product_ids.size()];
			for (int i = 0; i < p_product_ids.size(); i++) {
				[ids addObject:[NSString stringWithUTF8String:p_product_ids[i].utf8().get_data()]];
			}
			[[ZFStoreKit shared] initialize:ids];
		} else {
			emit_signal("store_error", String("storekit_requires_ios_15"));
		}
	}

	void purchase(const String &p_product_id) {
		if (@available(iOS 15.0, *)) {
			[[ZFStoreKit shared] purchase:[NSString stringWithUTF8String:p_product_id.utf8().get_data()]];
		}
	}

	void restore() {
		if (@available(iOS 15.0, *)) {
			[[ZFStoreKit shared] restore];
		}
	}

	void refresh_entitlements() {
		if (@available(iOS 15.0, *)) {
			[[ZFStoreKit shared] refreshEntitlements];
		}
	}

	// Called from the forwarder, always on the main thread.
	void on_products_loaded(NSArray<NSDictionary<NSString *, NSString *> *> *p_products) {
		Array products;
		for (NSDictionary<NSString *, NSString *> *entry in p_products) {
			Dictionary row;
			for (NSString *key in entry) {
				row[String::utf8([key UTF8String])] = String::utf8([entry[key] UTF8String]);
			}
			products.push_back(row);
		}
		emit_signal("products_loaded", products);
	}

	void on_transaction_updated(NSDictionary<NSString *, NSString *> *p_transaction) {
		Dictionary transaction;
		for (NSString *key in p_transaction) {
			transaction[String::utf8([key UTF8String])] = String::utf8([p_transaction[key] UTF8String]);
		}
		emit_signal("transaction_updated", transaction);
	}

	void on_entitlements_synced(NSArray<NSString *> *p_product_ids) {
		Array ids;
		for (NSString *product_id in p_product_ids) {
			ids.push_back(String::utf8([product_id UTF8String]));
		}
		emit_signal("entitlements_synced", ids);
	}

	void on_store_error(NSString *p_message) {
		emit_signal("store_error", String::utf8([p_message UTF8String]));
	}

	ZombieFireStoreKit() {
		instance = this;
		forwarder = [[ZFStoreKitForwarder alloc] init];
		forwarder.owner = this;
		if (@available(iOS 15.0, *)) {
			[ZFStoreKit shared].delegate = forwarder;
		}
	}

	~ZombieFireStoreKit() {
		if (@available(iOS 15.0, *)) {
			if ([ZFStoreKit shared].delegate == forwarder) {
				[ZFStoreKit shared].delegate = nil;
			}
		}
		forwarder = nil;
		if (instance == this) {
			instance = nullptr;
		}
	}
};

ZombieFireStoreKit *ZombieFireStoreKit::instance = nullptr;

@implementation ZFStoreKitForwarder

- (void)productsLoaded:(NSArray<NSDictionary<NSString *, NSString *> *> *)products {
	if (self.owner) {
		self.owner->on_products_loaded(products);
	}
}

- (void)transactionUpdated:(NSDictionary<NSString *, NSString *> *)transaction {
	if (self.owner) {
		self.owner->on_transaction_updated(transaction);
	}
}

- (void)entitlementsSynced:(NSArray<NSString *> *)productIds {
	if (self.owner) {
		self.owner->on_entitlements_synced(productIds);
	}
}

- (void)storeError:(NSString *)message {
	if (self.owner) {
		self.owner->on_store_error(message);
	}
}

@end

// Entry points named in zombiefire_storekit.gdip. Godot generates a dummy.cpp that
// declares them as plain C++ functions, so they must keep C++ linkage here:
// adding extern "C" exports _name instead of the mangled symbol the generated code
// looks for, and the Xcode archive then fails with undefined symbols.
void zombiefire_storekit_init() {
	ClassDB::register_class<ZombieFireStoreKit>();
	ZombieFireStoreKit *singleton = memnew(ZombieFireStoreKit);
	Engine::get_singleton()->add_singleton(Engine::Singleton("ZombieFireStoreKit", singleton));
}

void zombiefire_storekit_deinit() {
	ZombieFireStoreKit *singleton = ZombieFireStoreKit::get_singleton();
	if (singleton) {
		memdelete(singleton);
	}
}
