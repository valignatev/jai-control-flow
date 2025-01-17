or_return_build :: () {
    w := compiler_create_workspace("or_return workspace");
    if !w {
        print("Workspace creation failed.\n");
        return;
    }

    compiler_begin_intercept(w);

    message_loop();

    compiler_end_intercept(w);
}


message_loop :: () {
    while true {
        message := compiler_wait_for_message();
        if message.kind == {
        case .TYPECHECKED;

            typechecked := cast(*Message_Typechecked) message;
            handle_typechecked(typechecked);

            
        case .PHASE;
            phase := cast(*Message_Phase) message;
            if phase.phase == .TYPECHECKED_ALL_WE_CAN {}
            
        case .COMPLETE;
            break;
        }
    }
}

handle_typechecked :: (typechecked: *Message_Typechecked) {
    for to: typechecked.procedure_bodies {
        body := to.expression;
        if body.body_flags & .ALREADY_MODIFIED {
            continue;
        }

        assert(body.block != null);
        block := body.block;
        declared_named_returns: [..]string;
        header_returns := body.header.returns;
        for statement: block.statements {
            sub_expressions: [..]*Code_Node;
            get_recursive_nodes_breadth_first(statement, *sub_expressions);
            for sub_expressions {

                if it.kind == .DECLARATION {
                    decl := cast(*Code_Declaration)it;
                    name := decl.entry.name;
                    for header_returns {
                        if it.name && it.name == name && decl.expression {
                            array_add(*declared_named_returns, copy_string(name));
                        }
                    }
                }
                if it.kind != .PROCEDURE_CALL {
                    continue;
                }
                call := cast(*Code_Procedure_Call)it;

                ident := cast(*Code_Ident)call.procedure_expression;

                if ident.name != "or_return" {
                    continue;
                }

                shit := cast(*Code_Compound_Declaration)statement;
                or_return_call_args: [..]Code_Argument;
                array_add(*or_return_call_args, call.arguments_unsorted[0]);

                {

                    ident := New(Code_Ident);
                    ident.name = body.header.name;
                    decl := New(Code_Declaration);
                    decl.expression = body.header;
                    ident.resolved_declaration = decl;

                    arg := New(Code_Argument);
                    arg.expression = ident;
                    array_add(*or_return_call_args, arg);

                    for declared_named_returns {
                        literal := New(Code_Literal);
                        literal.value_type = .STRING;
                        literal._string = it;

                        arg := New(Code_Argument);
                        arg.expression = literal;
                        array_add(*or_return_call_args, arg);
                    }
                }

                call.arguments_unsorted = or_return_call_args;
                compiler_modify_procedure(typechecked.workspace, body);
            }
        }
    }
}

#scope_file

#import "Basic";
#import "Compiler";
#import "Code_Visit";
