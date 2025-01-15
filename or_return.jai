/*

NOTES: 
- Support nested or_return, or maybe make it a nice compile error.

*/

default_of_type_as_string :: (ti: *Type_Info) -> string {
    result: string;
    if ti.type == {
        case .INTEGER; result = "0";
        case .BOOL; result = "false";
        case .FLOAT; result = "0.0";
        case .POINTER; #through; // Maybe it's better to return New(pointer_to) and leak a bit instead of returning a null pointer?
        case .VOID; result = "null";
        case .STRUCT; result = ".{}";
        case .ARRAY; result = ".[]";
        case .ENUM; {
            // Should we straight up return 0 in this case instead of the first value,
            // even if it could be an invalid variant?
            our_enum := cast(*Type_Info_Enum)ti;
            result = tprint(".%", our_enum.names[0]);
        }
        case .PROCEDURE; result = "null"; // TODO: Do something fancier here...
        case .TYPE; result = "Type";
        case .CODE; result = "Code.{}";
    }
    return result;
}

or_return :: ($code: Code, $outer_proc_header: Code = (#code dummy), $declared_named_returns: ..string) -> $T1, $T2, $T3, $T4, $T5, $T6, $T7, $T8, $T9, $T10 #expand 
#modify {
    root, expressions := Compiler.compiler_get_nodes(code);
    if root.kind != .PROCEDURE_CALL {
        return false, "or_return macro only supports procedure_calls";
    }

    call := cast(*Compiler.Code_Procedure_Call)root;
    proc_expr := call.resolved_procedure_expression;

    if proc_expr.kind != .PROCEDURE_HEADER {
        return false, "Unexpected resolved procedure expression";
    }

    header := cast(*Compiler.Code_Procedure_Header)proc_expr;

    return_values := header.returns.count;
    if return_values < 1 {
        return false, tprint("Procedure should have at least a single return value, but it has %", return_values);
    }

    last_return := header.returns[return_values-1].type_inst;
    last_return_type := Compiler.get_type(last_return.result);
    if last_return_type != bool {
        return false, tprint("Expected the last return type to be bool, but it was % ", last_return_type);
    }

    T1, T2, T3, T4, T5, T6, T7, T8, T9, T10 = bool;
    for 0..return_values - 1 {
        return_ := header.returns[it].type_inst;
        return_type := Compiler.get_type(return_.result);
        if it == 0 T1  = return_type;
        if it == 1 T2  = return_type;
        if it == 2 T3  = return_type;
        if it == 3 T4  = return_type;
        if it == 4 T5  = return_type;
        if it == 5 T6  = return_type;
        if it == 6 T7  = return_type;
        if it == 7 T8  = return_type;
        if it == 8 T9  = return_type;
        if it == 9 T10 = return_type;
    }
    return true;
}
{
    #insert -> string {
        root, expressions := Compiler.compiler_get_nodes(code);

        outer := Compiler.compiler_get_nodes(outer_proc_header);

        if outer.kind != .IDENT {
            return "";
        }

        ident := cast(*Compiler.Code_Ident)outer;

        if ident.name == "dummy" {
            return "";
        }

        outer_header := cast(*Compiler.Code_Procedure_Header)ident.*.resolved_declaration.expression;
        outer_returns := outer_header.returns;
        outer_builder: String_Builder;

        for outer_returns {

            if it.entry.name {
                if array_find(declared_named_returns, it.entry.name) {
                    print_to_builder(*outer_builder, "`%", it.entry.name);
                } else {
                    print_to_builder(*outer_builder, "%=%", it.entry.name, default_of_type_as_string(it.entry.base.type));
                }
            } else {
                to_print := default_of_type_as_string(it.entry.base.type);
                append(*outer_builder, to_print);
            }
            if it_index < outer_returns.count - 1 {
                append(*outer_builder, ", ");
            }
        }
        outer_returns_formatted := builder_to_string(*outer_builder);

        if root.kind != .PROCEDURE_CALL {
            Compiler.compiler_report(
                "or_return macro only supports procedure_calls",
            );
            return "";
        }

        call := cast(*Compiler.Code_Procedure_Call)root;
        proc_expr := call.resolved_procedure_expression;

        if proc_expr.kind != .PROCEDURE_HEADER {
            Compiler.compiler_report(
                "Unexpected resolved procedure expression",
            );
            return "";
        }

        code_proc_header := cast(*Compiler.Code_Procedure_Header)proc_expr;

        return_values := code_proc_header.returns;

        builder: String_Builder;
        count := 0;
        for return_values {
            print_to_builder(*builder, "ret%", it_index + 1);
            if it_index < return_values.count - 1 {
                append(*builder, ", ");
            } else {
                append(*builder, " := ");
            }
            count += 1;
        }

        print_expression(*builder, root);
        append(*builder, ";\n");

        print_to_builder(*builder, "if !ret% `return %;\n", return_values.count, outer_returns_formatted);
        print_to_builder(*builder, "return ");

        for return_values {
            print_to_builder(*builder, "ret%", it_index + 1);
            if it_index < return_values.count - 1 {
                append(*builder, ", ");
            }
        }
        for 0..10-count-1 {
            append(*builder, ", false");
        }
        append(*builder, ";");

        result_code := builder_to_string(*builder);

        return result_code;
    }
}

caller_1 :: () -> bool {
	return true;
}

caller_2 :: () -> (int, bool) {
	return 123, true;
}

caller_3 :: () -> (int, int, bool) {
	return -123, 345, false;
}

Test :: struct {
    a: string;
    b: s8;
    c: []u32;
}

foo_1 :: () -> Test, foo_result: bool {

    final_test := Test.{a="passed", b=7, c=.[1, 2, 3, 4, 5]};
    foo_result := false;
    // result := 1;
    // ok := false;
	result, ok := or_return(caller_2());

    // gets replaced with:
    /*
        result, ok := caller_2();
        if !ok {
            return false;
        }
    */

    print_vars(result);

    result2 := or_return(caller_1());
    print_vars(result2);

    {
        n2 := or_return(caller_3());
        print_vars(n2);
    }

	// // And if the expression is 1-valued, it can be used like this
	// caller_1() or_return
	// // which is functionally equivalent to
	// if err1 := caller_1(); err1 != nil {
	// 	return err1
	// }

	// // Multiple return values still work with `or_return` as it only
	// // pops off the end value in the multi-valued expression
	// n0, n1 = caller_3() or_return

	return final_test, foo_result;
}

main :: () {

    result1, result2 := foo_1();

    print("final\n");
    print_vars(result1, result2);
}


#import "Basic";
#import "Program_Print";
Compiler :: #import "Compiler";
using,only(print_vars) Print_Vars :: #import "Print_Vars";
