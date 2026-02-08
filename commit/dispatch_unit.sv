module dispatch_unit (
    input  logic instr_valid,
    input  logic rob_full,
    input  logic rs_full,
    input  logic fl_empty,
    input  logic lsq_full,
    input  logic is_mem_instr,

    output logic dispatch_en,    // Triggers ROB, RS, and RAT update
    output logic frontend_stall  // Stops the Fetch/Decode stages
);

    always_comb begin
        // An instruction can only be dispatched if:
        // 1. There is a slot in the Reorder Buffer (ROB)
        // 2. There is a slot in the Reservation Station (RS)
        // 3. The Freelist has a physical register available
        dispatch_en = instr_valid && !rob_full && !rs_full && !fl_empty;

        // If it's a memory instruction, it also needs space in the LSQ
        if (is_mem_instr) begin
            dispatch_en = dispatch_en && !lsq_full;
        end

        // Stall the frontend if the backend is full but we have a valid instruction waiting
        frontend_stall = instr_valid && !dispatch_en;
    end

endmodule