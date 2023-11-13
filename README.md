To determine unique code executed by specific system calls we need to acquire
1. The total code accessible by the kernel
2. The total code that is unique to the specific system call. This is difficult
    just tracing a specific call will get what is reachable by a system call but
    also captures shared code blocks. This makes the numbers difficult to add up etc.
    We should also capture code that is unique to the specific call, to do this,
    we need to capture kernel coverage for everything EXCEPT that specific call.
    Since we have total code blocks executed by the workload we can subtract the 
    total_runtime excluding coverage during read, from the total_runtime to get what is unique
    to read.
