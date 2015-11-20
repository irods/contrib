test_msifree_microservice_out {
    msiExecCmd("hello", "null", "null", "null", "null", *exec_cmd_out);
    msiGetStdoutInExecCmdOut(*exec_cmd_out, *stdout);
    msifree_microservice_out(*exec_cmd_out); # DO NOT use *exec_cmd_out after this
    writeLine("stdout", *stdout); # Note that *stdout can still be used
    *i = errorcode(msifree_microservice_out(*stdout)); # Free'ing unsupported types is an error
    if *i != -323000 then fail(-1) else 0
}
INPUT null
OUTPUT ruleExecOut
