package test_utils;

    task display_result(string test_id, int expected, int actual);
        if (actual !== expected) begin
            $display("Test Failed for %s: Expected %h, Got %h", test_id, expected, actual);
        end else begin
            $display("Test Passed for %s.", test_id);
        end
    endtask

endpackage
