module issue_logic (
    input  logic rs_issue_valid,
    output logic alu_grant
);
    assign alu_grant = rs_issue_valid; // single-issue core
endmodule