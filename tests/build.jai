#load "../or_return_build.jai";

build :: () {
    w := compiler_create_workspace("Target Program");
    if !w {
        print("Workspace creation failed.\n");
        return;
    }

    target_options := get_build_options(w);
    target_options.output_executable_name = "tests";
    set_build_options(target_options, w);

    compiler_begin_intercept(w);

    add_build_file("./tests.jai",  w);

    or_return_build(w);
    compiler_end_intercept(w);

    set_build_options_dc(.{do_output=false});
}

#run build();
