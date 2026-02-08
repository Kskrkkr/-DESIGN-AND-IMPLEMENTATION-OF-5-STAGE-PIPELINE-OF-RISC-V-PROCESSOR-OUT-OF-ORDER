module dispatch_controller (
    // From Decoder
    input  logic instr_valid,
    input  logic is_load,
    input  logic is_store,
    
    // Resource Status (From ROB, RS, Freelist, and LSQ)
    input  logic rob_full,
    input  logic rs_full,
    input  logic freelist_empty,
    input  logic lsq_full, // For memory instructions

    // Output: Global Stall and Enable
    output logic dispatch_ready,
    output logic stall_frontend
);

    always_comb begin
        // An instruction can proceed ONLY if all required resources are available
        dispatch_ready = instr_valid && !rob_full && !rs_full && !freelist_empty;
        
        // If it's a memory instruction, also check the Load/Store Queue
        if (is_load || is_store) begin
            dispatch_ready = dispatch_ready && !lsq_full;
        end

        // If we can't dispatch, we must stall the Fetch Queue and Fetch Unit
        stall_frontend = !dispatch_ready && instr_valid;
    end
endmodule