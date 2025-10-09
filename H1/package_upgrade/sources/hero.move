module package_upgrade::hero;

use std::string::String;

use sui::dynamic_field as df;
use sui::dynamic_object_field as dof;
use sui::package;

use sui::coin::{Coin};
use sui::sui::SUI;

use package_upgrade::blacksmith::{Shield, Sword};
use package_upgrade::version::Version;

const HERO_PRICE: u64 = 100;
const PAYMENT_RECEIVER: address = @0x1;

const EAlreadyEquipedShield: u64 = 0;
const EAlreadyEquipedSword: u64 = 1;
const EInvalidPrice: u64 = 2;

public struct HERO() has drop;

// sword, shield, power
public struct SwordKey has copy, drop, store {}
public struct ShieldKey has copy, drop, store {}
public struct PowerKey has copy, drop, store {}

/// Hero NFT
public struct Hero has key, store {
    id: UID,
    health: u64,
    stamina: u64
}

fun init(otw: HERO, ctx: &mut TxContext) {
    package::claim_and_keep(otw, ctx);
}

/// @deprecated: `mint_hero` is deprecated. Use `mint_hero_v2` instead.
public fun mint_hero(version: &Version, ctx: &mut TxContext): Hero {
    version.check_is_valid();
    Hero {
        id: object::new(ctx),
        health: 100,
        stamina: 10
    }
}

/// Anyone can mint a hero, as long as they pay `HERO_PRICE` SUI.
/// New hero will have 100 health and 10 stamina.
public fun mint_hero_v2(version: &Version, payment: Coin<SUI>, ctx: &mut TxContext): Hero {
    let mut hero = Hero {
        id: object::new(ctx),
        health: 100,
        stamina: 10
    };

    assert!(payment.value() == HERO_PRICE, EInvalidPrice);
    transfer::public_transfer(payment, PAYMENT_RECEIVER);

    // Power IS a DYNAMIC FIELD (DF), not DYNAMIC OBJECT FIELD(DOF), because its value is a u64, not an Object.
    df::add(&mut hero.id, PowerKey{}, 0);

    hero
}

/// Hero can equip a single sword.
/// Equiping a sword increases the `Hero`'s power by its attack.
public fun equip_sword(self: &mut Hero, version: &Version, sword: Sword) {
    version.check_is_valid();
    
    if (dof::exists_(&self.id, SwordKey{})) {
        abort(EAlreadyEquipedSword)
    };
    // or assert!(dof::exists_(&self.id, SwordKey{}), EAlreadyEquipedSword)

    // The borrow and borrow_mut return &ref(REFERENCE &), to access the value, use the asterisk(*)
    let mut hero_power = *df::borrow_mut(&mut self.id, PowerKey{});
    hero_power = hero_power + sword.attack();

    dof::add(&mut self.id, SwordKey{}, sword);

}

/// Hero can equip a single shield.
/// Equiping a shield increases the `Hero`'s power by its defence.
public fun equip_shield(self: &mut Hero, version: &Version, shield: Shield) {
    version.check_is_valid();

    if(dof::exists_(&self.id, ShieldKey{})) {
        abort(EAlreadyEquipedShield)
    };
    // or assert!(dof::exists_(&self.id, ShieldKey{}), EAlreadyEquipedShield)

    let mut hero_power = *df::borrow_mut(&mut self.id, PowerKey{});
    hero_power = hero_power + shield.defence();

    dof::add(&mut self.id, ShieldKey{}, shield);
}

public fun health(self: &Hero): u64 {
    self.health
}

public fun stamina(self: &Hero): u64 {
    self.stamina
}

// Task: Add power getter
public fun power(self: &Hero): u64 {
    *df::borrow(&self.id, PowerKey{})
}

/// Returns the sword the hero has equipped.
/// Aborts if it does not exists
public fun sword(self: &Hero): &Sword {
    // Task: Use SwordKey instead of string
    dof::borrow(&self.id, SwordKey{})
}

/// Returns the shield the hero has equipped.
/// Aborts if it does not exists
public fun shield(self: &Hero): &Shield {
    // Task: Use ShieldKey instead of string
    dof::borrow(&self.id, ShieldKey{})
}

/// Generic add dynamic object field to the hero.
fun add_dof<T: key + store>(self: &mut Hero, name: String, value: T) {
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
