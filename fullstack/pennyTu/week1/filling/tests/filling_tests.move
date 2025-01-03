#[test_only]
module filling::filling_tests {
    use filling::filling::{Self, State, Profile};
    use sui::test_scenario::{Self};
    use std::string::{Self};
    use sui::test_utils::assert_eq;

    #[test]
    fun test_create_profile() {
        let user = @0xa; // 假设性地址
        let mut scenario_val = test_scenario::begin(user);
        let scenario = &mut scenario_val;

        filling::init_far_testig(test_scenario::ctx(scenario)); // 把之前做的合约initialize,代表这个合约在这个test内已存在,就可开始用里面的func做测试
        test_scenario::next_tx(scenario, user);

        // create profile
        let name = string::utf8(b"Bob");
        let desc = string::utf8(b"FE programer");
        // init后已经create State, call state去利用
        {
            let mut state = test_scenario::take_shared<State>(scenario);
            filling::create_profile( // create后, 在里面就已经将object转给creater
                name,
                desc,
                &mut state,
                test_scenario::ctx(scenario),
            );
            // 用完share object, 在测试的scenario里面 take 后,要把它还回去, 不然object还会存在于state中,没有被drop, 会导致报错
            test_scenario::return_shared(state);
        };
        let tx = test_scenario::next_tx(scenario, user);
        // 刚刚如果create了一个profile, suppose会emit一个event, 以下测试是否有 emit event
        let expected_no_events = 1;
        assert_eq(
            test_scenario::num_user_events(&tx),
            expected_no_events,
        );
        // 测试是否有 profile object
        {
            let state = test_scenario::take_shared<State>(scenario);
            // 除了有share object可以take, 也可以take owner object(user create了profile, profile的object转给了它,所以是一个owner address owned object)
            let profile = test_scenario::take_from_sender<Profile>(scenario);
            // assert pass不了的话,就代表没有create成功
            assert!(
                // check_if_has_profile如果存在就会emit profile address
                filling::check_if_has_profile(user, &state) ==
                option::some(object::id_to_address(object::borrow_id(&profile))),
                0, // error code
            );
            test_scenario::return_shared(state);
            test_scenario::return_to_sender(scenario, profile);
        };
        // 最后结束test_scenario
        test_scenario::end(scenario_val);
    }
}