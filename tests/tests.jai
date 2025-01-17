#import,file "../or_return.jai";

test_returns_first_enum_value :: () -> Error {
	happy_string, happy_int, happy_result := or_return(happy("hello, I am happy"));
    assert(happy_result == true);

	n1 := or_return(sad());

    assert(false, "Should return before this happens");
    return .Something;
}

test_returns_declared_named_value_and_unnamed_bool :: () -> (res1: Res1, bool) {
    res1 := Res1.{"initialized"};

    or_return(sad());

    return .{}, true;
}

test_returns_pointer_with_null_as_default :: () -> (res: *Res1) {
    // TODO: we totally consume #must inside of or_return
    or_return(must_sad());

    res1, res2 := must_sad();
    if !res2 {
        return null;
    }

    return New(Res1);
}

test_returns_array :: () -> []string {
    res1, res2, res3 := or_return(happy("happy"));
    assert(res1 == "happy");
    assert(res2 == 5);
    assert(res3 == true);

    return .["7", "8", "9"];
}

GLOBAL := 69;

test_interacts_with_defer :: () -> int {
    defer GLOBAL = 420;
    or_return(sad());
    return 5;
}

FOO :: #type (string, int) -> string;

foo :: (s: string, i: int) -> string {
    return s;
}

test_returns_null_procedure_pointer :: () -> FOO {
    res1 := or_return(sad());

    return foo;
}

test_returns_filled_procedure_pointer :: () -> FOO {
    res1 := or_return(happy("happy"));

    return foo;
}

main :: () {

    res: Res1;

    {
        print("test_returns_first_enum_value");
        res := test_returns_first_enum_value();
        ti := cast(*Type_Info_Enum)Error;
        expected_enum_value := ti.values[0];
        assert(res == xx expected_enum_value, "Expected default enum value");
        print(" ...PASSED\n");
    }

    {
        print("test_returns_declared_named_value_and_unnamed_bool");
        res1, res2 := test_returns_declared_named_value_and_unnamed_bool();
        assert(res1.test == "initialized", "Expected res1 to be initialized\n");
        assert(res2 == false, "Expeted res2 to be false");
        print(" ...PASSED\n");
    }

    {
        print("test_returns_pointer_with_null_as_default");
        res1 := test_returns_pointer_with_null_as_default();
        assert(res1 == null, "Expected null pointer returned by default\n");
        print(" ...PASSED\n");
    }

    {
        print("test_returns_array");
        res := test_returns_array();
        expeted := string.["7", "8", "9"];
        for res {
            assert(it == expeted[it_index], tprint("Unexpected array returned: %", res));
        }
        print(" ...PASSED\n");
    }
    {
        print("test_interacts_with_defer");
        result := test_interacts_with_defer();
        assert(result == 0);
        assert(GLOBAL == 420);
        print(" ...PASSED\n");
    }
    {
        print("test_procedure_pointers");
        result := test_returns_null_procedure_pointer();
        assert(result == null);

        result = test_returns_filled_procedure_pointer();
        assert(result == foo);
        foo_result := foo("I am foo", 0);
        assert(foo_result == "I am foo");
        print(" ...PASSED\n");
    }
}


Res1 :: struct {
    test: string = "default";
}

Error :: enum {
    None :: 1;
    Something;
}

happy :: (input: string) -> (string, int, bool) {
    return "happy", 5, true;
}

sad :: () -> (int, []string) {
	return 123, .[];
}

must_sad :: () -> string, bool #must {
    return "must_sad", false;
}

returns_struct :: () -> Res1 {
    return .{};
}


#import "Basic";
#import "Compiler";
#import "Print_Vars";
