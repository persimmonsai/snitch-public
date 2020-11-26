// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

/// Stream demultiplexer: Connects the input stream (valid-ready) handshake to one of `N_OUP` output
/// stream handshakes. Selection is based on supplied address.
module stream_addr_demux #(
  parameter int unsigned NrOutput     = 0,
  parameter int unsigned AddressWidth = 0,
  parameter int unsigned DefaultSlave = 0,
  parameter int unsigned NrRules      = 1, // Routing rules
  /// Dependent parameters, DO NOT OVERRIDE!
  localparam integer LogNrOutput = $clog2(NrOutput)
) (
  input  logic                                 inp_valid_i,
  output logic                                 inp_ready_o,

  input  logic [AddressWidth-1:0]              inp_addr_i,

  output logic [NrOutput-1:0]                  oup_valid_o,
  input  logic [NrOutput-1:0]                  oup_ready_i,

  input  logic [NrRules-1:0][AddressWidth-1:0] addr_mask_i,
  input  logic [NrRules-1:0][AddressWidth-1:0] addr_base_i,
  input  logic [NrRules-1:0][LogNrOutput-1:0]  addr_slave_i
);

  logic [LogNrOutput-1:0] slave_select;
  logic [NrRules-1:0]     addr_match;

  // Address Decoder
  always_comb begin
    slave_select = 0;

    for (int i = 0; i < NrRules; i++) begin : gen_addr_decoder
      addr_match[i] = (addr_base_i[i] & addr_mask_i[i]) == (inp_addr_i & addr_mask_i[i]);
      // address regions should be mutual exclusive, hence we can simplify the address selection
      // to use an or-tree.
      slave_select |= addr_match[i] ? addr_slave_i[i] : '0;
    end

    // if no address matches, select default slave
    if (!(|addr_match)) slave_select = DefaultSlave;
  end

  stream_demux #(
    .N_OUP (NrOutput)
  ) i_stream_demux (
    .inp_valid_i,
    .inp_ready_o,
    .oup_sel_i    ( slave_select ),
    .oup_valid_o,
    .oup_ready_i
  );

endmodule