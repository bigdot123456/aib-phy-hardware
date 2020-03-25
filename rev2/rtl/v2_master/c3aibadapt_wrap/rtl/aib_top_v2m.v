// SPDX-License-Identifier: Apache-2.0
// Copyright (C) 2019 Intel Corporation. 
//-----------------------------------------------------------------------------
// Copyright (C) 2018 Intel Corporation. .  
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//  $Header: TBD
//  $Date:   TBD
//-----------------------------------------------------------------------------
// Description: Top level AIB wrapper includes 24 channel AIB + AIB AUX
//
//
//---------------------------------------------------------------------------
//
//
//-----------------------------------------------------------------------------
// Change log
// 10/29/2019 
// 1) Pull out phasecom FIFO interface clock and data:
//    i_rx_elane_clk,i_rx_elane_data,i_tx_elane_clk,o_tx_elane_data
// 2) Pull out ns_adapt_rstn
// 3) instantiated optimized aibcr3aux_top_master
// 11/24/2019 changed microbump name to fit board layout
// 11/25/2019 Need to pull out m_rxfifo_align_done
//-----------------------------------------------------------------------------

module aib_top_v2m
  # (
     parameter TOTAL_CHNL_NUM = 24
     )
  (
     //================================================================================================
   // Reset Inteface
   input                                                          i_conf_done, // AIB adaptor hard reset

   // reset for XCVRIF
   output [TOTAL_CHNL_NUM-1:0]                                    fs_mac_rdy, // chiplet xcvr receiving path reset, the reset is controlled by remote chiplet which is FPGA in this case
   
   //===============================================================================================
   // Configuration Interface which includes two paths
 
   // Path directly from chip programming controller
   input                                                          i_cfg_avmm_clk, 
   input                                                          i_cfg_avmm_rst_n, 
   input [16:0]                                                   i_cfg_avmm_addr, // address to be programmed
   input [3:0]                                                    i_cfg_avmm_byte_en, // byte enable
   input                                                          i_cfg_avmm_read, // Asserted to indicate the Cfg read access
   input                                                          i_cfg_avmm_write, // Asserted to indicate the Cfg write access
   input [31:0]                                                   i_cfg_avmm_wdata, // data to be programmed
 
   output                                                         o_cfg_avmm_rdatavld,// Assert to indicate data available for Cfg read access 
   output [31:0]                                                  o_cfg_avmm_rdata, // data returned for Cfg read access
   output                                                         o_cfg_avmm_waitreq, // asserted to indicate not ready for Cfg access

 //===============================================================================================
 // Data Path
 // Rx Path clocks/data, from master (current chiplet) to slave (FPGA)
   input [TOTAL_CHNL_NUM-1:0]                                     m_ns_fwd_clk, // Rx path clk for data receiving, may generated from xcvr pll
   input [TOTAL_CHNL_NUM-1:0]                                     m_ns_fwd_div2_clk, // Divided by 2 clock on Rx pathinput                          
    
// input [TOTAL_CHNL_NUM*65-1:0]                                  i_chnl_ssr, // Slow shift chain path, tie to 0s if not used
   input [TOTAL_CHNL_NUM*40-1:0]                                  data_in_reg_mode, // data out for direct register mode
 
   input [TOTAL_CHNL_NUM-1:0]                                     m_wr_clk, //Clock for phase compensation fifo
   input [TOTAL_CHNL_NUM*78-1:0]                                  data_in, //data in for phase compensation fifo

 // Tx Path clocks/data, from slave (FPGA) to master (current chiplet)
   input [TOTAL_CHNL_NUM-1:0]                                     m_ns_rcv_clk, // this clock is sent over to the other chiplet to be used for the clock as the data transmission
// output [TOTAL_CHNL_NUM*61-1:0]                                 o_chnl_ssr, // Slow shift chain path, left unconnected if not used
   output [TOTAL_CHNL_NUM-1:0]                                    m_fs_fwd_clk, // clock used for tx data transmission
   output [TOTAL_CHNL_NUM-1:0]                                    m_fs_fwd_div2_clk, // half rate of tx data transmission clock
   output [TOTAL_CHNL_NUM*40-1:0]                                 data_out_reg_mode, //data out during direct register mode. 
   input  [TOTAL_CHNL_NUM-1:0]                                    m_rd_clk, //Clock for phase compensation fifo
   output [TOTAL_CHNL_NUM*78-1:0]                                 data_out, // data out for phase compensation fifo

 //=================================================================================================
 // AIB open source IP enhancement. The following ports are added to
 // be compliance with AIB specification 1.1
   input  [TOTAL_CHNL_NUM-1:0]                                    ns_mac_rdy,  //From Mac. To indicate MAC is ready to send and receive data. use aibio49
   input  [TOTAL_CHNL_NUM-1:0]                                    ns_adapter_rstn, //From Mac. To reset near adapt reset sm and far side reset sm. aibio56
   output [TOTAL_CHNL_NUM*81-1:0]                                 ms_sideband, //Status of serial shifting bit from this master chiplet to slave chiplet
   output [TOTAL_CHNL_NUM*73-1:0]                                 sl_sideband, //Status of serial shifting bit from slave chiplet to master chiplet.
   output [TOTAL_CHNL_NUM-1:0]                                    ms_rx_transfer_en, //master link rx transfer enable
   output [TOTAL_CHNL_NUM-1:0]                                    ms_tx_transfer_en, //master link tx transfer enable
   output [TOTAL_CHNL_NUM-1:0]                                    sl_rx_transfer_en, //slave link rx transfer enable
   output [TOTAL_CHNL_NUM-1:0]                                    sl_tx_transfer_en, //slave link tx transfer enable
   output [TOTAL_CHNL_NUM-1:0]                                    m_rxfifo_align_done,  //Newly added rx data fifo alignment done signal.
   //=================================================================================================
   // Inout signals for AIB ubump
   inout [95:0]                                                   m0_ch0_aib, 
   inout [95:0]                                                   m0_ch1_aib,
   inout [95:0]                                                   m0_ch2_aib,
   inout [95:0]                                                   m0_ch3_aib, 
   inout [95:0]                                                   m0_ch4_aib, 
   inout [95:0]                                                   m0_ch5_aib, 
   inout [95:0]                                                   m1_ch0_aib, 
   inout [95:0]                                                   m1_ch1_aib, 
   inout [95:0]                                                   m1_ch2_aib, 
   inout [95:0]                                                   m1_ch3_aib, 
   inout [95:0]                                                   m1_ch4_aib,
   inout [95:0]                                                   m1_ch5_aib,
   inout [95:0]                                                   m2_ch0_aib,
   inout [95:0]                                                   m2_ch1_aib,
   inout [95:0]                                                   m2_ch2_aib,
   inout [95:0]                                                   m2_ch3_aib,
   inout [95:0]                                                   m2_ch4_aib,
   inout [95:0]                                                   m2_ch5_aib,
   inout [95:0]                                                   m3_ch0_aib,
   inout [95:0]                                                   m3_ch1_aib, 
   inout [95:0]                                                   m3_ch2_aib,
   inout [95:0]                                                   m3_ch3_aib,
   inout [95:0]                                                   m3_ch4_aib,
   inout [95:0]                                                   m3_ch5_aib,
// inout [95:0]                                                   io_aib_aux,
   
   inout                                                          io_aib_aux74,
   inout                                                          io_aib_aux75,
   inout                                                          io_aib_aux85,
   inout                                                          io_aib_aux87,
// inout                                                          io_aux_bg_ext_2k, //connect to external 2k resistor, C4 bump

   //======================================================================================
   input                                                          m_por_ovrd, //test por override through c4 bump
   

   //
   input                                                          i_osc_clk,     // test clock from c4 bump, may tie low for User if not used
// output                                                         o_aibaux_osc_clk, // osc clk output to test C4 bump to characterize the oscillator, User may use this clock to connect with i_test_clk_1g
    //======================================================================================
   // DFT signals
   input                                                          i_scan_clk,     //ATPG Scan shifting clock from Test Pad.  
// input                                                          i_test_clk_1g,  //1GHz free running direct accessed ATPG at speed clock.
// input                                                          i_test_clk_125m,//Divided down from i_test_clk_1g. 
// input                                                          i_test_clk_250m,//Divided down from i_test_clk_1g.
// input                                                          i_test_clk_500m,//Divided down from i_test_clk_1g.
// input                                                          i_test_clk_62m, //Divided down from i_test_clk_1g.
                                                                                  //The divided down clock is for different clock domain at
                                                                                  //speed test.
   //Channel ATPG signals from/to CODEC
   input [TOTAL_CHNL_NUM-1:0] [`AIBADAPTWRAPTCB_SCAN_CHAINS_RNG]  i_test_c3adapt_scan_in, //scan in hook from Codec 
   input                                                          i_test_scan_en,     //Terminate i_test_c3adapt_tcb_static_common, only pull out Scan enable 
   input                                                          i_test_scan_mode,
   output [TOTAL_CHNL_NUM-1:0] [`AIBADAPTWRAPTCB_SCAN_CHAINS_RNG] o_test_c3adapt_scan_out, //scan out hook to Codec
  
   //Inputs from TCB (JTAG signals)
   input                                                          i_jtag_clkdr, // (from dbg_test_bscan block)Enable AIB IO boundary scan clock (clock gate control)
   input                                                          i_jtag_clksel, // (from dbg_test_bscan block)Select between i_jtag_clkdr_in and functional clk
   input                                                          i_jtag_intest, // (from dbg_test_bscan block)Enable in test operation
   input                                                          i_jtag_mode, // (from dbg_test_bscan block)Selects between AIB BSR register or functional path
   input                                                          i_jtag_rstb, // (from dbg_test_bscan block)JTAG controlleable reset the AIB IO circuitry
   input                                                          i_jtag_rstb_en, // (from dbg_test_bscan block)JTAG controlleable override to reset the AIB IO circuitry
   input                                                          i_jtag_tdi, // (from dbg_test_bscan block)TDI
   input                                                          i_jtag_tx_scanen,// (from dbg_test_bscan block)Drives AIB IO jtag_tx_scanen_in or BSR shift control  
   input                                                          i_jtag_weakpdn,  //(from dbg_test_bscan block)Enable AIB global pull down test. 
   input                                                          i_jtag_weakpu,  //(from dbg_test_bscan block)Enable AIB global pull up test. 

   
   //output TCB 
   output                                                         o_jtag_tdo, //last boundary scan chain output, TDO 

   output                                                         m_power_on_reset // S10 POR to User, can be left unconnected for User
  
   );

    /*AUTOWIRE*/
    // Beginning of automatic wires (for undeclared instantiated-module outputs)
    wire                aibaux_osc_clk;         // From u_aibcr3aux_top_wrp of aibcr3aux_top_wrp.v
    wire                aibaux_por_vcchssi;     // From u_aibcr3aux_top_wrp of aibcr3aux_top_wrp.v
    wire                aibaux_por_vccl;        // From u_aibcr3aux_top_wrp of aibcr3aux_top_wrp.v

    
    c3aibadapt_wrap_top u_c3aibadapt_wrap_top
      (/*AUTOINST*/
       // Outputs
       .o_rx_xcvrif_rst_n               (fs_mac_rdy[TOTAL_CHNL_NUM-1:0]),
       .o_cfg_avmm_rdatavld             (o_cfg_avmm_rdatavld),
       .o_cfg_avmm_rdata                (o_cfg_avmm_rdata[31:0]),
       .o_cfg_avmm_waitreq              (o_cfg_avmm_waitreq),
       .o_osc_clk                       (),                      // Templated
       .o_chnl_ssr                      (),
       .o_tx_transfer_clk               (m_fs_fwd_clk[TOTAL_CHNL_NUM-1:0]),
       .o_tx_transfer_div2_clk          (m_fs_fwd_div2_clk[TOTAL_CHNL_NUM-1:0]),
       .o_tx_pma_data                   (data_out_reg_mode),
       .ns_mac_rdy                      (ns_mac_rdy[TOTAL_CHNL_NUM-1:0]),
       .ns_adapt_rstn                   (ns_adapter_rstn[TOTAL_CHNL_NUM-1:0]),
       .m_rxfifo_align_done            (m_rxfifo_align_done[TOTAL_CHNL_NUM-1:0]), 
       .ms_sideband                     (ms_sideband[TOTAL_CHNL_NUM*81-1:0]),
       .sl_sideband                     (sl_sideband[TOTAL_CHNL_NUM*73-1:0]),
       .ms_tx_transfer_en               (ms_tx_transfer_en[TOTAL_CHNL_NUM-1:0]),
       .ms_rx_transfer_en               (ms_rx_transfer_en[TOTAL_CHNL_NUM-1:0]),
       .sl_tx_transfer_en               (sl_tx_transfer_en[TOTAL_CHNL_NUM-1:0]),
       .sl_rx_transfer_en               (sl_rx_transfer_en[TOTAL_CHNL_NUM-1:0]),
       .o_test_c3adapt_scan_out         (o_test_c3adapt_scan_out/*[TOTAL_CHNL_NUM-1:0][`AIBADAPTWRAPTCB_SCAN_CHAINS_RNG]*/),
       .o_test_c3adapttcb_jtag          (),                      // Templated
       .o_jtag_last_bs_chain_out        (o_jtag_tdo),     // Templated
       .o_red_idataselb_out_chain1      (red_idataselb_in_chain1), // Templated
       .o_red_idataselb_out_chain2      (red_idataselb_in_chain2), // Templated
       .o_red_shift_en_out_chain1       (red_shift_en_in_chain1), // Templated
       .o_red_shift_en_out_chain2       (red_shift_en_in_chain2), // Templated
       .o_txen_out_chain1               (o_txen_out_chain1),
       .o_txen_out_chain2               (o_txen_out_chain2),
       .o_directout_data_chain1_out     (o_directout_data_chain1_out),
       .o_directout_data_chain2_out     (o_directout_data_chain2_out),
       .o_aibdftdll2adjch               (),
       // Inouts
       .io_aib_ch0                      (m0_ch0_aib[95:0]),
       .io_aib_ch1                      (m0_ch1_aib[95:0]),
       .io_aib_ch2                      (m0_ch2_aib[95:0]),
       .io_aib_ch3                      (m0_ch3_aib[95:0]),
       .io_aib_ch4                      (m0_ch4_aib[95:0]),
       .io_aib_ch5                      (m0_ch5_aib[95:0]),
       .io_aib_ch6                      (m1_ch0_aib[95:0]),
       .io_aib_ch7                      (m1_ch1_aib[95:0]),
       .io_aib_ch8                      (m1_ch2_aib[95:0]),
       .io_aib_ch9                      (m1_ch3_aib[95:0]),
       .io_aib_ch10                     (m1_ch4_aib[95:0]),
       .io_aib_ch11                     (m1_ch5_aib[95:0]),
       .io_aib_ch12                     (m2_ch0_aib[95:0]),
       .io_aib_ch13                     (m2_ch1_aib[95:0]),
       .io_aib_ch14                     (m2_ch2_aib[95:0]),
       .io_aib_ch15                     (m2_ch3_aib[95:0]),
       .io_aib_ch16                     (m2_ch4_aib[95:0]),
       .io_aib_ch17                     (m2_ch5_aib[95:0]),
       .io_aib_ch18                     (m3_ch0_aib[95:0]),
       .io_aib_ch19                     (m3_ch1_aib[95:0]),
       .io_aib_ch20                     (m3_ch2_aib[95:0]),
       .io_aib_ch21                     (m3_ch3_aib[95:0]),
       .io_aib_ch22                     (m3_ch4_aib[95:0]),
       .io_aib_ch23                     (m3_ch5_aib[95:0]),
       // Inputs
       .i_adpt_hard_rst_n               (i_conf_done),
       .i_cfg_avmm_clk                  (i_cfg_avmm_clk),
       .i_cfg_avmm_rst_n                (i_cfg_avmm_rst_n),
       .i_cfg_avmm_addr                 (i_cfg_avmm_addr[16:0]),
       .i_cfg_avmm_byte_en              (i_cfg_avmm_byte_en[3:0]),
       .i_cfg_avmm_read                 (i_cfg_avmm_read),
       .i_cfg_avmm_write                (i_cfg_avmm_write),
       .i_cfg_avmm_wdata                (i_cfg_avmm_wdata[31:0]),
       .i_rx_pma_clk                    (m_ns_fwd_clk[TOTAL_CHNL_NUM-1:0]),
       .i_rx_pma_div2_clk               (m_ns_fwd_div2_clk[TOTAL_CHNL_NUM-1:0]),
       .i_rx_elane_clk                  (m_wr_clk[TOTAL_CHNL_NUM-1:0]),
       .i_rx_elane_data                 (data_in[TOTAL_CHNL_NUM*78-1:0]),
       .i_osc_clk                       (aibaux_osc_clk),        // Templated
       .i_chnl_ssr                      ({24{65'h0}}),
       .i_rx_pma_data                   (data_in_reg_mode),
       .i_tx_pma_clk                    (m_ns_rcv_clk[TOTAL_CHNL_NUM-1:0]),
       .i_tx_elane_clk                  (m_rd_clk[TOTAL_CHNL_NUM-1:0]),
       .o_tx_elane_data                 (data_out[TOTAL_CHNL_NUM*78-1:0]),
       .i_scan_clk                      (i_scan_clk),
       .i_test_clk_125m                 (1'b0),
       .i_test_clk_1g                   (1'b0),
       .i_test_clk_250m                 (1'b0),
       .i_test_clk_500m                 (1'b0),
       .i_test_clk_62m                  (1'b0),
       .i_test_c3adapt_scan_in          (i_test_c3adapt_scan_in/*[TOTAL_CHNL_NUM-1:0][`AIBADAPTWRAPTCB_SCAN_CHAINS_RNG]*/),
       .i_test_c3adapt_tcb_static_common({58'h0, i_test_scan_en, i_test_scan_mode}),
       .i_jtag_rstb_in                  (i_jtag_rstb),  // Templated
       .i_jtag_rstb_en_in               (i_jtag_rstb_en), // Templated
       .i_jtag_clkdr_in                 (i_jtag_clkdr), // Templated
       .i_jtag_clksel_in                (i_jtag_clksel), // Templated
       .i_jtag_intest_in                (i_jtag_intest), // Templated
       .i_jtag_mode_in                  (i_jtag_mode),  // Templated
       .i_jtag_weakpdn_in               (i_jtag_weakpdn), // Templated
       .i_jtag_weakpu_in                (i_jtag_weakpu), // Templated
       .i_jtag_bs_scanen_in             (i_jtag_tx_scanen), // Templated
       .i_jtag_bs_chain_in              (i_jtag_tdi), // Templated
       .i_por_aib_vcchssi               (aibaux_por_vcchssi),    // Templated
       .i_por_aib_vccl                  (aibaux_por_vccl));       // Templated

assign m_power_on_reset = aibaux_por_vcchssi;
aibcr3aux_top_master aibcr3aux_top_master (
       .o_por_vcchssi                   (aibaux_por_vcchssi),
       .o_por_vccl                      (aibaux_por_vccl),
     
//     .oosc_clkout_dup                 (o_aibaux_osc_clk), 
       .oosc_clkout_dup                 (), 
       .oosc_clkout                     (aibaux_osc_clk),
     
       .aib_aux74                       (io_aib_aux74),
       .aib_aux75                       (io_aib_aux75),
       .aib_aux85                       (io_aib_aux85),
       .aib_aux87                       (io_aib_aux87),
     
       .c4por_vccl_ovrd                 (m_por_ovrd),
       .iosc_bypclk                     (i_osc_clk)
     ); 
    
endmodule // aib_top

