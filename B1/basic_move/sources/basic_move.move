/// B1 Module Goals (what we tackle here)
/// - Packages/Modules: a single module with minimal public entry points
/// - Compiler flow: simple functions that compile cleanly
/// - Move Tests: sui::test_scenario, assert! (and/or assert_eq)
/// - Objects & drop: contrast an object that must be explicitly deleted
///   with a plain value type that can be ignored/overwritten if it has drop

module basic_move::basic_move_suggested_change_solution;
use std::string::String;
use sui::test_scenario;
use sui::test_utils::destroy;

public struct Hero has key, store {
    id: object::UID,
    name: String, // Add a name field to name your Hero
}

// Value type WITH drop → can be ignored/overwritten.
public struct Pebble has drop, store {
    size: u8,
}

// Value type WITHOUT drop → cannot be ignored/overwritten.
public struct Rock has store {
    size: u8,
}

public fun mint_hero(name: String, ctx: &mut TxContext): Hero {
    Hero { id: object::new(ctx), name }
}

public fun make_pebble(size: u8): Pebble {
    Pebble { size } // You can also create and return the created struct in one line
}

public fun make_rock(size: u8): Rock {
    Rock { size }
}

#[test]
fun test_mint() {
    let mut test = test_scenario::begin(@0xCAFE);
    let hero = mint_hero(b"superman".to_string(), test.ctx());
    assert!(hero.name == b"superman".to_string(), 612);
    destroy_for_testing(hero);
    test.end();
}

// Demonstrate drop vs non-drop semantics
#[test]
fun test_drop_semantics() {
    // 1) Ignoring a value requires `drop`
    let _pebble = make_pebble(
        1,
    ); // OK: Pebble has `drop` → Show linter error when drop ability is removed

    // 2) Overwriting a variable drops the old value → requires `drop`
    let mut _pebble2 = make_pebble(2);
    _pebble2 = make_pebble(3); // OK: Pebble has `drop`

    // 3) A type WITHOUT drop cannot be ignored/overwritten implicitly.
    // Correct way: explicitly CONSUME it (e.g., in this test via destroy)
    let rock = make_rock(4);
    destroy(rock); // Consumes Rock → Comment this line out to see the linter error message
}

#[test_only]
fun destroy_for_testing(hero: Hero) {
    let Hero {
        id,
        name: _,
    } = hero;
    object::delete(id);
}
