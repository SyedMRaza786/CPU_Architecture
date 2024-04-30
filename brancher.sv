always (@pos_edge clock) begin
    branch_state <= next_branch_state
    case (branch_state)
        2'b00:
            //Strongly not taken
            if (branch_taken)
                next_branch_state = 2'b01
            if (branch_not_taken)
                next_branch_state = 2'b00
        2'b01:
            if (branch_taken)
                next_branch_state = 2'b10
            if (branch_not_taken)
                next_branch_state = 2'b00
        2'b10:
            if (branch_taken)
                next_branch_state = 2'b11
            if (branch_not_taken)
                next_branch_state = 2'b01
        2'b11:
            if (branch_taken)
                next_branch_state = 2'b11
            if (branch_not_taken)
                next_branch_state = 2'b10

end