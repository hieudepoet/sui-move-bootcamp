module package_upgrade::hero;

use std::string::String;

use sui::coin::Coin;
use sui::dynamic_field as df;
use sui::dynamic_object_field as dof;
use sui::package;
use sui::sui::SUI;

use package_upgrade::blacksmith::{Shield, Sword};
use package_upgrade::version::Version;

const EAlreadyEquipedShield: u64 = 0;
const EAlreadyEquipedSword: u64 = 1;
const EDeprecated: u64 = 2;
const EInvalidPayment: u64 = 3;
const EMigrateHeroFirst: u64 = 4;

const OUR_ADDRESS: address = @0x111111;

// @0xaaaaa
public struct HERO() has drop;

/// Hero NFT
public struct Hero has key, store {
    id: UID,
    health: u64,
    stamina: u64,
    // Task: Add power field
}

public struct SwordKey() has copy, drop, store;
public struct ShieldKey() has copy, drop, store;

public struct PowerKey() has copy, drop, store;

fun init(otw: HERO, ctx: &mut TxContext) {
    // @0xaaaa::package::Publisher<HERO>()
    package::claim_and_keep(otw, ctx);
}

/// Anyone can mint a hero.
/// Hero starts with 100 heath and 10 stamina.
public fun mint_hero(_: &Version, _: &mut TxContext): Hero {
    abort(EDeprecated)
}

// Task: Implement mint_hero_v2 that accepts payment
public fun mint_hero_v2(version: &Version, payment: Coin<SUI>, ctx: &mut TxContext): Hero {
    version.check_is_valid();
    assert!(payment.value() == 5_000_000_000, EInvalidPayment);
    transfer::public_transfer(payment, OUR_ADDRESS);
    let mut hero = Hero {
        id: object::new(ctx),
        health: 100,
        stamina: 10
    };
    df::add(&mut hero.id, PowerKey(), 0);
    hero
}

/// Hero can equip a single sword.
/// Equiping a sword increases the `Hero`'s power by its attack.
public fun equip_sword(self: &mut Hero, version: &Version, sword: Sword) {
    version.check_is_valid();
    // Task: Use SwordKey instead of string
    assert!(!dof::exists_(&self.id, b"sword".to_string()), EMigrateHeroFirst);
    if (df::exists_(&self.id, SwordKey())) {
        abort(EAlreadyEquipedSword)
    };
    *self.power_mut() = self.power() + sword.attack();
    // Task: Update power
    self.add_dof(SwordKey(), sword)
}

/// Hero can equip a single shield.
/// Equiping a shield increases the `Hero`'s power by its defence.
public fun equip_shield(self: &mut Hero, version: &Version, shield: Shield) {
    version.check_is_valid();
    // Task: Use ShieldKey instead of string
    assert!(!dof::exists_(&self.id, b"shield".to_string()), EMigrateHeroFirst);
    if (df::exists_(&self.id, ShieldKey())) {
        abort(EAlreadyEquipedShield)
    };
    *self.power_mut() = self.power() + shield.defence();
    // Task: Update power
    self.add_dof(ShieldKey(), shield)
}

public fun health(self: &Hero): u64 {
    self.health
}

public fun stamina(self: &Hero): u64 {
    self.stamina
}

public fun migrate(self: &mut Hero) {
    if (dof::exists_(&self.id, b"sword")) {
        let sword: Sword = dof::remove(&mut self.id, b"sword");
        dof::add(&mut self.id, SwordKey(), sword);
    };
    if (dof::exists_(&self.id, b"shield")) {
        let shield: Shield = dof::remove(&mut self.id, b"shield");
        dof::add(&mut self.id, ShieldKey(), shield);
    };
}

// Task: Add power getter
// public fun power(self: &Hero): u64 {
//     0
// }

/// Returns the sword the hero has equipped.
/// Aborts if it does not exists
public fun sword(self: &Hero): &Sword {
    // Task: Use SwordKey instead of string
    dof::borrow(&self.id, SwordKey())
}

/// Returns the shield the hero has equipped.
/// Aborts if it does not exists
public fun shield(self: &Hero): &Shield {
    // Task: Use ShieldKey instead of string
    dof::borrow(&self.id, ShieldKey())
}

public fun power(self: &Hero): u64 {
    *df::borrow(&self.id, PowerKey())
}

fun power_mut(self: &mut Hero): &mut u64 {
    df::borrow_mut(&mut self.id, PowerKey())
}

/// Generic add dynamic object field to the hero.
fun add_dof<K: copy + store + drop, T: key + store>(self: &mut Hero, name: K, value: T) {
    dof::add(&mut self.id, name, value)
}

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(HERO(), ctx);
}

#[test_only]
public fun uid_mut_for_testing(self: &mut Hero): &mut UID {
    &mut self.id
}

