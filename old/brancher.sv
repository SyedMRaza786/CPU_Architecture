module brancher
//input reset
//input clock
//input take_branch
//input brancher_valid
//output branch_prediction
    
    always (@pos_edge clock) begin
        if(reset)branch_state=2'b00; 
        case (branch_state)
            2'b00:
                //Strongly not taken
                if (branch_taken && brancher_valid)
                    next_branch_state = 2'b01;
                if (!branch_taken && brancher_valid)
                    next_branch_state = 2'b00;
            2'b01:
                if (branch_taken && brancher_valid)
                    next_branch_state = 2'b10;
                if (!branch_taken && brancher_valid)
                    next_branch_state = 2'b00;
            2'b10:
                if (branch_taken && brancher_valid)
                    next_branch_state = 2'b11;
                if (!branch_taken && brancher_valid)
                    next_branch_state = 2'b01;
            2'b11:
                if (branch_taken && brancher_valid)
                    next_branch_state = 2'b11;
                if (!branch_taken && brancher_valid)
                    next_branch_state = 2'b10;
        end
        branch_state <= next_branch_state
            if(branch_state == 2'b11 || branch_state = 2'b10) branch_prediction = 1;
            else branch_prediction = 0;
    end
endmodule
                    
