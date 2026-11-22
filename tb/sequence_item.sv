  class sequence_item extends uvm_sequence_item;
    `uvm_object_utils(sequence_item)
    function new(string name="sequence_item"); super.new(name); endfunction

    rand logic       rst_n;
    rand logic [7:0] ui_in;
    logic      [7:0] uo_out;
    rand logic [7:0] uio_in;
    logic      [7:0] uio_out;
    logic      [7:0] uio_oe;
  endclass
