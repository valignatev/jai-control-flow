# Jai control flow macros

This is a collection of Jai macros that hopefully provide some quality of life around verbosity of control flow, such as early returns and assigning default values in a condition.

In this repo:

## or_return

Macro `or_return` automates early returns. Consider this example:


```jai

Profile :: struct {
    program: "string";
    key_binds: [..]Key_Bind;
}

get_profile :: () -> Profile {
    result: Profile;
    raw_profile, success := read_entire_file("./profile.cfg");

    if !success {
        return .{};
    }
    
    result:, success = parse_raw_profile(raw_profile);
    if !success {
        return .{}
    }
    
    return result;
}
```

This code can be shortened a bit with `or_return` macro like this

```jai
#import,file "./or_return.jai";

Profile :: struct {
    program: "string";
    key_binds: [..]Key_Bind;
}

get_profile :: () -> Profile {
    result: Profile;
    raw_profile := or_return(read_entire_file("./profile.cfg"));
    
    result := or_return(parse_raw_profile(raw_profile));
    return result;
}
```

`or_return` macro works similarly to `or_return` operator in [Odin programming language](https://odin-lang.org/docs/overview/#or_return-operator) (and, well, this macro is inspired by that operator). 

In particular, `or_return` inspects the last return value of wrapped procedure,
and if it evaluates to false, early return happens.

Main difference is that there's no restriction for named vs unnamed returns of the procedure where the macro got called. If a return value is unnamed (or named but undeclared), or_return will return a default value for the type. Default return value for pointers is `null`. Let me know if returning a zero-initialized heap-allocated type is better. This is up for a discussion.

In order to work, `or_return` requires you to execute its metaprogram in your build file. See `build.jai` in tests for example.

For now, in the first version, `or_return` only accepts procedure calls. But if it's useful, we can accept any expression where something evaluates to false. Let me know...

## or_else

TBD

## or_continue

Maybe???

## license

MIT
