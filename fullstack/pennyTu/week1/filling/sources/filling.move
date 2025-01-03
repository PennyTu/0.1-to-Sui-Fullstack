/*
/// Module: filling
module filling::filling;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions


module filling::filling {
    // ===================================================================
    // Dependencies
    // ===================================================================
    use std::string::{String};
    use sui::event;
    use sui::table::{Self, Table};
    
    // ===================================================================
    // Constants
    // ===================================================================
    
    // ===================================================================
    // Error codes
    // ===================================================================
    const EProfileExisted:u64 = 0;
    
    // ===================================================================
    // Structs 类似store,储存信息
    // ===================================================================
    // 能力: key drop store copy
    public struct State has key { // 用来储存作为品牌方的一个宏观的记录
        id: UID,
        users: Table<address, address> // owener address, profile object address
    }

    public struct Profile has key {
        id: UID, // 定义object的一个独特的id
        name: String,
        description: String,
    }
    
    // ===================================================================
    // Event Structs
    // ===================================================================
    // 让前端知道收到信息、读取信息(已create好profile)
    public struct ProfileCreated has copy, drop {
        // 定义前端需要得到什么信息
        id: ID, // create_profile的id
        owner: address, // create这些object的address
    }
    
    // ===================================================================
    // Init
    // ===================================================================
    fun init(ctx: &mut TxContext) {
        transfer::share_object(State { // 不会转给某个用户,会作为share object,大家都可以浏览的公共resource
            id: object::new(ctx),
            users: table::new(ctx)
        })
    }
    
    // ===================================================================
    // Entry Functions
    // ===================================================================
    public entry fun create_profile ( // 每个用户只能create一个profile
        name: String,
        description: String,
        state: &mut State,
        ctx: &mut TxContext, // 辅助性的module,得到一些transition时用到的信息
    ) {
        let owner = tx_context::sender(ctx); // 调用该func的人
        assert!(!table::contains(&state.users, owner), EProfileExisted); // 检查这个 table 里是否已有该 profile
        let uid = object::new(ctx); // create object 需要
        let id = object::uid_to_inner(&uid);
        let new_profile = Profile { // create object
            id: uid,
            name,
            description,
        };
        // 将object转给对应用户, Profile属于用户
        transfer::transfer(new_profile, owner);
        table::add(&mut state.users, owner, object::id_to_address(&id)); // 
        event::emit(ProfileCreated{
            id,
            owner,
            // id: ID,
            // owner: address,
        })
    }
    
    // ===================================================================
    // Getter Functions
    // ===================================================================
    public fun check_if_has_profile(
        user_address: address,
        state: &State,
    ): Option<address>{
        // key是user的wallet address, table/key的item是对应的profile object address
        // 这里的user_address查的是key,
        if(table::contains(&state.users, user_address)) {
            option::some(*table::borrow(&state.users, user_address))
        } else {
            option::none()
        }
    }
    
    // ===================================================================
    // Helper Functions
    // ===================================================================
    #[test_only]
    public fun init_far_testig(ctx: &mut TxContext) { // 合约初始化
        init(ctx);
    }
}