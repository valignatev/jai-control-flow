/*
 or_else2 is simpler than or_else - it doesn't need to replace the dummy2 return because of slightly different structure
 #modify is exactly the same tho, can skip reading it
*/
or_else2 :: ($proc_call: Code, default_value: $T) -> T #expand
#modify {
    root, expressions := Compiler.compiler_get_nodes(proc_call);
    if root.kind != .PROCEDURE_CALL {
        return false, "or_else macro only supports procedure_calls";
    }

    call := cast(*Compiler.Code_Procedure_Call)root;
    proc_expr := call.resolved_procedure_expression;

    if proc_expr.kind != .PROCEDURE_HEADER {
        return false, "Unexpected resolved procedure expression";
    }

    header := cast(*Compiler.Code_Procedure_Header)proc_expr;

    return_values := header.returns.count;
    if return_values != 2 {
        return false, tprint("Procedure should have only two return values, but it has ", return_values);
    }

    first_return := header.returns[0].type_inst;
    second_return := header.returns[1].type_inst;

    first_return_type := Compiler.get_type(first_return.result);
    second_return_type := Compiler.get_type(second_return.result);

    if second_return_type != bool {
        return false, tprint("Expected second return type to be bool, but it was % ", second_return_type);
    }

    T = first_return_type;
    return true;
} { 
    #insert,scope() -> Code {
        root, expressions := Compiler.compiler_get_nodes(proc_call);
        call := cast(*Compiler.Code_Procedure_Call)root;
        header := cast(*Compiler.Code_Procedure_Header)call.resolved_procedure_expression;

        // Simpler version here
        result_code := #code {
            result, success := dummy();
            if success return result;
        }

        dummy, dummy_exprs := Compiler.compiler_get_nodes(result_code);

        value_code := code_of(default_value);
        value_node, value_exprs := Compiler.compiler_get_nodes(value_code);
        found_return := false;

        for dummy_exprs {
            if it.kind == .PROCEDURE_CALL {
                call2 := cast(*Compiler.Code_Procedure_Call)it;
                call2.* = call.*;
                break;
            }
        }

        modified := Compiler.compiler_get_code(dummy);

        return modified;
    };

    // Jusr return default value instead of inserting it
    return default_value;
}

Test_Type :: struct {
    str: string;
    num: s64;
    builder: String_Builder;
}

optional_int :: (a: int, b: int) -> int, bool {
    if a > 69 return b, true;
    return -1, false;
}

foo :: () {
}

optional_struct :: (test_type: Test_Type) -> Test_Type, bool {
    if test_type.str.count > 0 {
        return test_type, true;
    }
    return .{}, false;
}

main :: () {

    table: Table(string, int);
    result1 := or_else2(read_entire_file("./sdklfjsdkl.jai"), "Default");
    print("%\n", result1);

    result2 := or_else2(optional_int(10, 10), 420);
    print("%\n", result2);

    builder: String_Builder;
    print_to_builder(*builder, "foo\n");
    result3 := or_else2(optional_struct(.{"", 16, .{}}), Test_Type.{"default", 666, builder});

    print("%\n", result3);

    // Error: Attempt to match a literal, even though we would designate it in #modify block.
    // result4 := or_else(optional_struct(.{"", 16, .{}}), .{"default", 666, builder});


    // Can't do this, because #must gets checked during the typechecking phase.
    // result5 := or_else(table_find(*table, "foo"), 12);


}

#import "Basic";
Compiler :: #import "Compiler";
#import "File";
using,only(print_vars) Print_Vars :: #import "Print_Vars";
#import "Program_Print";
#import "Hash_Table";
