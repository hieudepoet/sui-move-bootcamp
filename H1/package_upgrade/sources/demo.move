module package_upgrade::my_module {
    use sui::balance::{Self, Balance};
    use sui::coin::Coin;
    use sui::sui::SUI;

    const EInvalidVersion: u64 = 0;

    const VERSION: u16 = 1;
    
    public struct ContractVersion has key {
        id: UID,
        version: u16,
    }

    // @0xaaaaa::my_module::SharedBalancePool
    public struct SharedBalancePool has key {
        id: UID,
        balance: Balance<SUI>,
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(SharedBalancePool {
            id: object::new(ctx),
            balance: balance::zero(),
        });
        transfer::share_object(ContractVersion {
            id: object::new(ctx),
            version: VERSION,
        });

    }

    // @aaaaaa::my_module::important_function
    public fun important_function(pool: &mut SharedBalancePool, version: &ContractVersion): Coin<SUI> {
        assert!(version.version == VERSION, EInvalidVersion);
        // Buggy code means the pool is exploitable
        // Buggy code means the pool is exploitable
        // Buggy code means the pool is exploitable
        // Buggy code means the pool is exploitable
        let _pool = pool;
        abort(0)
    }
}

// Imagine my_module as module name. We just use a different one to appease the compiler.
module package_upgrade::same_my_module {
    use sui::balance::Balance;
    use sui::coin::Coin;
    use sui::sui::SUI;

    const EInvalidVersion: u64 = 0;

    const VERSION: u16 = 2;

    public struct ContractVersion has key {
        id: UID,
        version: u16,
    }

    // @0xaaaaa::my_module::SharedBalancePool
    public struct SharedBalancePool has key {
        id: UID,
        balance: Balance<SUI>,
    }

    public fun migrate(version: &mut ContractVersion, /*_: &AdminCap*/) {
        version.version = VERSION;
    }

    // @bbbbbb::my_module::important_function
    public fun important_function(pool: &mut SharedBalancePool, version: &ContractVersion): Coin<SUI> {
        assert!(version.version == VERSION, EInvalidVersion);
        // Code without the bug
        // Code without the bug
        // Code without the bug
        // Code without the bug
        let _pool = pool;
        abort(0)
    }
}
