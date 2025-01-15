/*

The Questions:
- Can we allow polymorphic procedures to designate a type for struct literals with #modify directive?
  In this macro, #modify sets T to the return type of the first value that the proc_call returns, but we still
  can't pass a struct literal on the call site, getting "Error: Attempt to match a literal, without a type designation..."
  (See the first example commented out in main)
- It would be cool to be able to compose #code blocks with some sort of lisp-like quoting/unquoting.
  Poking the dummy code nodes works but is less ergonomic. Also, see comments in the code.
- Can't call the macro like usual with something that returns #must, because it fails the typechecking phase.
  (See the commented out example in main)

*/
or_else :: ($proc_call: Code, default_value: $T) -> T #expand
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

        // See or_else2.jai for simpler version of the same thing that doesn't need dummy2 at all.
        // But this is a slightly convoluted way to do this to "provoke the discussion".
        result_code := #code {
            // Note1: Turns out you can't just splice any code node - their kinds have to match.
            // So this HAS to be dummy() - dummy procedure call; You can't just set it to dummy identifier and
            // then replace it with a procedure call. Otherwise, compiler_get_code will crash later on;
            // You also have to modify nodes in-place because there is no way replace something in the array and then somehow resubmit it back (?)
            result, success := dummy();
            // You also can't replace dummy2 identifier with anything you want. Default value could be
            // a string literal, a number, a struct... So you need to replace a whole return node.
            if !success return dummy2;
            return result;
        }

        dummy, dummy_exprs := Compiler.compiler_get_nodes(result_code);

        value_code := code_of(default_value);
        value_node, value_exprs := Compiler.compiler_get_nodes(value_code);
        found_return := false;

        for dummy_exprs {
            if it.kind == .PROCEDURE_CALL {
                call2 := cast(*Compiler.Code_Procedure_Call)it;
                call2.* = call.*;
            } else if it.kind == .RETURN && !found_return {
                our_return := make_return_statement(value_node);
                found_return = true;
                ret := cast(*Compiler.Code_Return)it;
                ret.* = our_return.*;
            }
        }

        modified := Compiler.compiler_get_code(dummy);

        return modified;
    };
}

// Copypasted verbatim from examples
make_return_statement :: (expression: *Compiler.Code_Node) -> *Compiler.Code_Return {
    ret := New(Compiler.Code_Return);
    ret.kind = .RETURN;

    arguments_unsorted: [..] Compiler.Code_Argument;

    arg: Compiler.Code_Argument;
    arg.expression = expression;
    arg.name = null;

    array_add(*arguments_unsorted, arg);
    ret.arguments_unsorted = arguments_unsorted;

    arguments_sorted: [..] *Compiler.Code_Node;
    array_add(*arguments_sorted, expression);
    ret.arguments_sorted = arguments_sorted;

    return ret;
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

    // result1 will be "Default" if file couldn't be read, or file's contents
    // "read_entire_file" isn't getting called here. Its code gets passed to the macro,
    // gets inspected and then this gets inserted into the code in place of this macro.
    /*
         result, success := read_entire_file("./sdklfjsdkl.jai");
         if success { return result; }
         else { return "Default"; }
    */
    // "Default" also isn't getting evaluated unless "success" is false, it gets passed as
    // code as well in case it's a complicated calculation!
    result1 := or_else(read_entire_file("./sdklfjsdkl.jai"), "Default");

    // or_else is type safe, it knows return types of the procedure
    // and would refuse to compile if you violate it
    optional_int :: (a: int, b: int) -> int, bool {
        if a > 69 return b, true;
        return -1, false;
    }

    result2 := or_else(optional_int(10, 10), 420);

    // This won't compile: "Expected int, but got string"
    result2 := or_else(optional_int(10, 10), "fail");

    foo :: () {}

    // This won't compile: "procedure call should have 2 returns, but it has 0"
    result3 := or_else(foo(), 69);
}
    

    builder: String_Builder;
    print_to_builder(*builder, "foo\n");
    result3 := or_else(optional_struct(.{"", 16, .{}}), Test_Type.{"default", 666, builder});

    print("%\n", result3);

    // Error: Attempt to match a literal, even though we would designate it in #modify block.
    // result4 := or_else(optional_struct(.{"", 16, .{}}), .{"default", 666, builder});

    table: Table(string, int);
    result5 := or_else(table_find(*table, "foo"), 12);


}

#import "Basic";
Compiler :: #import "Compiler";
#import "File";
using,only(print_vars) Print_Vars :: #import "Print_Vars";
#import "Program_Print";
#import "Hash_Table";
