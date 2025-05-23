; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=amdgcn -mcpu=gfx1010 -show-mc-encoding < %s | FileCheck -check-prefixes=GFX10 %s
; RUN: llc -mtriple=amdgcn -mcpu=gfx1100 -mattr=+real-true16 -amdgpu-enable-vopd=0 -show-mc-encoding < %s | FileCheck -check-prefixes=GFX11,GFX11-TRUE16 %s
; RUN: llc -mtriple=amdgcn -mcpu=gfx1100 -mattr=-real-true16 -amdgpu-enable-vopd=0 -show-mc-encoding < %s | FileCheck -check-prefixes=GFX11,GFX11-FAKE16 %s
; RUN: llc -mtriple=amdgcn -mcpu=gfx1200 -mattr=+real-true16 -amdgpu-enable-vopd=0 -show-mc-encoding < %s | FileCheck -check-prefixes=GFX12,GFX12-TRUE16 %s
; RUN: llc -mtriple=amdgcn -mcpu=gfx1200 -mattr=-real-true16 -amdgpu-enable-vopd=0 -show-mc-encoding < %s | FileCheck -check-prefixes=GFX12,GFX12-FAKE16 %s

define amdgpu_ps <4 x float> @sample_d_1d(<8 x i32> inreg %rsrc, <4 x i32> inreg %samp, half %dsdh, half %dsdv, float %s) {
; GFX10-LABEL: sample_d_1d:
; GFX10:       ; %bb.0: ; %main_body
; GFX10-NEXT:    image_sample_d_g16 v[0:3], v[0:2], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_1D ; encoding: [0x01,0x0f,0x88,0xf0,0x00,0x00,0x40,0x00]
; GFX10-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0x70,0x3f,0x8c,0xbf]
; GFX10-NEXT:    ; return to shader part epilog
;
; GFX11-LABEL: sample_d_1d:
; GFX11:       ; %bb.0: ; %main_body
; GFX11-NEXT:    image_sample_d_g16 v[0:3], v[0:2], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_1D ; encoding: [0x00,0x0f,0xe4,0xf0,0x00,0x00,0x00,0x08]
; GFX11-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0xf7,0x03,0x89,0xbf]
; GFX11-NEXT:    ; return to shader part epilog
;
; GFX12-LABEL: sample_d_1d:
; GFX12:       ; %bb.0: ; %main_body
; GFX12-NEXT:    image_sample_d_g16 v[0:3], [v0, v1, v2], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_1D ; encoding: [0x00,0x40,0xce,0xe7,0x00,0x00,0x00,0x04,0x00,0x01,0x02,0x00]
; GFX12-NEXT:    s_wait_samplecnt 0x0 ; encoding: [0x00,0x00,0xc2,0xbf]
; GFX12-NEXT:    ; return to shader part epilog
main_body:
  %v = call <4 x float> @llvm.amdgcn.image.sample.d.1d.v4f32.f16.f32(i32 15, half %dsdh, half %dsdv, float %s, <8 x i32> %rsrc, <4 x i32> %samp, i1 0, i32 0, i32 0)
  ret <4 x float> %v
}

define amdgpu_ps <4 x float> @sample_d_2d(<8 x i32> inreg %rsrc, <4 x i32> inreg %samp, half %dsdh, half %dtdh, half %dsdv, half %dtdv, float %s, float %t) {
; GFX10-LABEL: sample_d_2d:
; GFX10:       ; %bb.0: ; %main_body
; GFX10-NEXT:    v_perm_b32 v2, v3, v2, 0x5040100 ; encoding: [0x02,0x00,0x44,0xd7,0x03,0x05,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX10-NEXT:    v_perm_b32 v0, v1, v0, 0x5040100 ; encoding: [0x00,0x00,0x44,0xd7,0x01,0x01,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX10-NEXT:    image_sample_d_g16 v[0:3], [v0, v2, v4, v5], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_2D ; encoding: [0x0b,0x0f,0x88,0xf0,0x00,0x00,0x40,0x00,0x02,0x04,0x05,0x00]
; GFX10-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0x70,0x3f,0x8c,0xbf]
; GFX10-NEXT:    ; return to shader part epilog
;
; GFX11-TRUE16-LABEL: sample_d_2d:
; GFX11-TRUE16:       ; %bb.0: ; %main_body
; GFX11-TRUE16-NEXT:    v_mov_b16_e32 v2.h, v3.l ; encoding: [0x03,0x39,0x04,0x7f]
; GFX11-TRUE16-NEXT:    v_mov_b16_e32 v0.h, v1.l ; encoding: [0x01,0x39,0x00,0x7f]
; GFX11-TRUE16-NEXT:    image_sample_d_g16 v[0:3], [v0, v2, v4, v5], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_2D ; encoding: [0x05,0x0f,0xe4,0xf0,0x00,0x00,0x00,0x08,0x02,0x04,0x05,0x00]
; GFX11-TRUE16-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0xf7,0x03,0x89,0xbf]
; GFX11-TRUE16-NEXT:    ; return to shader part epilog
;
; GFX11-FAKE16-LABEL: sample_d_2d:
; GFX11-FAKE16:       ; %bb.0: ; %main_body
; GFX11-FAKE16-NEXT:    v_perm_b32 v2, v3, v2, 0x5040100 ; encoding: [0x02,0x00,0x44,0xd6,0x03,0x05,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX11-FAKE16-NEXT:    v_perm_b32 v0, v1, v0, 0x5040100 ; encoding: [0x00,0x00,0x44,0xd6,0x01,0x01,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX11-FAKE16-NEXT:    image_sample_d_g16 v[0:3], [v0, v2, v4, v5], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_2D ; encoding: [0x05,0x0f,0xe4,0xf0,0x00,0x00,0x00,0x08,0x02,0x04,0x05,0x00]
; GFX11-FAKE16-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0xf7,0x03,0x89,0xbf]
; GFX11-FAKE16-NEXT:    ; return to shader part epilog
;
; GFX12-TRUE16-LABEL: sample_d_2d:
; GFX12-TRUE16:       ; %bb.0: ; %main_body
; GFX12-TRUE16-NEXT:    v_mov_b16_e32 v2.h, v3.l ; encoding: [0x03,0x39,0x04,0x7f]
; GFX12-TRUE16-NEXT:    v_mov_b16_e32 v0.h, v1.l ; encoding: [0x01,0x39,0x00,0x7f]
; GFX12-TRUE16-NEXT:    image_sample_d_g16 v[0:3], [v0, v2, v4, v5], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_2D ; encoding: [0x01,0x40,0xce,0xe7,0x00,0x00,0x00,0x04,0x00,0x02,0x04,0x05]
; GFX12-TRUE16-NEXT:    s_wait_samplecnt 0x0 ; encoding: [0x00,0x00,0xc2,0xbf]
; GFX12-TRUE16-NEXT:    ; return to shader part epilog
;
; GFX12-FAKE16-LABEL: sample_d_2d:
; GFX12-FAKE16:       ; %bb.0: ; %main_body
; GFX12-FAKE16-NEXT:    v_perm_b32 v2, v3, v2, 0x5040100 ; encoding: [0x02,0x00,0x44,0xd6,0x03,0x05,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX12-FAKE16-NEXT:    v_perm_b32 v0, v1, v0, 0x5040100 ; encoding: [0x00,0x00,0x44,0xd6,0x01,0x01,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX12-FAKE16-NEXT:    image_sample_d_g16 v[0:3], [v0, v2, v4, v5], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_2D ; encoding: [0x01,0x40,0xce,0xe7,0x00,0x00,0x00,0x04,0x00,0x02,0x04,0x05]
; GFX12-FAKE16-NEXT:    s_wait_samplecnt 0x0 ; encoding: [0x00,0x00,0xc2,0xbf]
; GFX12-FAKE16-NEXT:    ; return to shader part epilog
main_body:
  %v = call <4 x float> @llvm.amdgcn.image.sample.d.2d.v4f32.f16.f32(i32 15, half %dsdh, half %dtdh, half %dsdv, half %dtdv, float %s, float %t, <8 x i32> %rsrc, <4 x i32> %samp, i1 0, i32 0, i32 0)
  ret <4 x float> %v
}

define amdgpu_ps <4 x float> @sample_d_3d(<8 x i32> inreg %rsrc, <4 x i32> inreg %samp, half %dsdh, half %dtdh, half %drdh, half %dsdv, half %dtdv, half %drdv, float %s, float %t, float %r) {
; GFX10-LABEL: sample_d_3d:
; GFX10:       ; %bb.0: ; %main_body
; GFX10-NEXT:    v_mov_b32_e32 v9, v3 ; encoding: [0x03,0x03,0x12,0x7e]
; GFX10-NEXT:    v_mov_b32_e32 v3, v2 ; encoding: [0x02,0x03,0x06,0x7e]
; GFX10-NEXT:    v_perm_b32 v2, v1, v0, 0x5040100 ; encoding: [0x02,0x00,0x44,0xd7,0x01,0x01,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX10-NEXT:    v_perm_b32 v4, v4, v9, 0x5040100 ; encoding: [0x04,0x00,0x44,0xd7,0x04,0x13,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX10-NEXT:    image_sample_d_g16 v[0:3], v[2:8], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_3D ; encoding: [0x11,0x0f,0x88,0xf0,0x02,0x00,0x40,0x00]
; GFX10-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0x70,0x3f,0x8c,0xbf]
; GFX10-NEXT:    ; return to shader part epilog
;
; GFX11-TRUE16-LABEL: sample_d_3d:
; GFX11-TRUE16:       ; %bb.0: ; %main_body
; GFX11-TRUE16-NEXT:    v_mov_b16_e32 v3.h, v4.l ; encoding: [0x04,0x39,0x06,0x7f]
; GFX11-TRUE16-NEXT:    v_mov_b16_e32 v0.h, v1.l ; encoding: [0x01,0x39,0x00,0x7f]
; GFX11-TRUE16-NEXT:    image_sample_d_g16 v[0:3], [v0, v2, v3, v5, v[6:8]], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_3D ; encoding: [0x09,0x0f,0xe4,0xf0,0x00,0x00,0x00,0x08,0x02,0x03,0x05,0x06]
; GFX11-TRUE16-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0xf7,0x03,0x89,0xbf]
; GFX11-TRUE16-NEXT:    ; return to shader part epilog
;
; GFX11-FAKE16-LABEL: sample_d_3d:
; GFX11-FAKE16:       ; %bb.0: ; %main_body
; GFX11-FAKE16-NEXT:    v_perm_b32 v3, v4, v3, 0x5040100 ; encoding: [0x03,0x00,0x44,0xd6,0x04,0x07,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX11-FAKE16-NEXT:    v_perm_b32 v0, v1, v0, 0x5040100 ; encoding: [0x00,0x00,0x44,0xd6,0x01,0x01,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX11-FAKE16-NEXT:    image_sample_d_g16 v[0:3], [v0, v2, v3, v5, v[6:8]], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_3D ; encoding: [0x09,0x0f,0xe4,0xf0,0x00,0x00,0x00,0x08,0x02,0x03,0x05,0x06]
; GFX11-FAKE16-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0xf7,0x03,0x89,0xbf]
; GFX11-FAKE16-NEXT:    ; return to shader part epilog
;
; GFX12-TRUE16-LABEL: sample_d_3d:
; GFX12-TRUE16:       ; %bb.0: ; %main_body
; GFX12-TRUE16-NEXT:    v_mov_b16_e32 v3.h, v4.l ; encoding: [0x04,0x39,0x06,0x7f]
; GFX12-TRUE16-NEXT:    v_mov_b16_e32 v0.h, v1.l ; encoding: [0x01,0x39,0x00,0x7f]
; GFX12-TRUE16-NEXT:    image_sample_d_g16 v[0:3], [v0, v2, v3, v[5:8]], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_3D ; encoding: [0x02,0x40,0xce,0xe7,0x00,0x00,0x00,0x04,0x00,0x02,0x03,0x05]
; GFX12-TRUE16-NEXT:    s_wait_samplecnt 0x0 ; encoding: [0x00,0x00,0xc2,0xbf]
; GFX12-TRUE16-NEXT:    ; return to shader part epilog
;
; GFX12-FAKE16-LABEL: sample_d_3d:
; GFX12-FAKE16:       ; %bb.0: ; %main_body
; GFX12-FAKE16-NEXT:    v_perm_b32 v3, v4, v3, 0x5040100 ; encoding: [0x03,0x00,0x44,0xd6,0x04,0x07,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX12-FAKE16-NEXT:    v_perm_b32 v0, v1, v0, 0x5040100 ; encoding: [0x00,0x00,0x44,0xd6,0x01,0x01,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX12-FAKE16-NEXT:    image_sample_d_g16 v[0:3], [v0, v2, v3, v[5:8]], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_3D ; encoding: [0x02,0x40,0xce,0xe7,0x00,0x00,0x00,0x04,0x00,0x02,0x03,0x05]
; GFX12-FAKE16-NEXT:    s_wait_samplecnt 0x0 ; encoding: [0x00,0x00,0xc2,0xbf]
; GFX12-FAKE16-NEXT:    ; return to shader part epilog
main_body:
  %v = call <4 x float> @llvm.amdgcn.image.sample.d.3d.v4f32.f16.f32(i32 15, half %dsdh, half %dtdh, half %drdh, half %dsdv, half %dtdv, half %drdv, float %s, float %t, float %r, <8 x i32> %rsrc, <4 x i32> %samp, i1 0, i32 0, i32 0)
  ret <4 x float> %v
}

define amdgpu_ps <4 x float> @sample_c_d_1d(<8 x i32> inreg %rsrc, <4 x i32> inreg %samp, float %zcompare, half %dsdh, half %dsdv, float %s) {
; GFX10-LABEL: sample_c_d_1d:
; GFX10:       ; %bb.0: ; %main_body
; GFX10-NEXT:    image_sample_c_d_g16 v[0:3], v[0:3], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_1D ; encoding: [0x01,0x0f,0xa8,0xf0,0x00,0x00,0x40,0x00]
; GFX10-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0x70,0x3f,0x8c,0xbf]
; GFX10-NEXT:    ; return to shader part epilog
;
; GFX11-LABEL: sample_c_d_1d:
; GFX11:       ; %bb.0: ; %main_body
; GFX11-NEXT:    image_sample_c_d_g16 v[0:3], v[0:3], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_1D ; encoding: [0x00,0x0f,0xe8,0xf0,0x00,0x00,0x00,0x08]
; GFX11-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0xf7,0x03,0x89,0xbf]
; GFX11-NEXT:    ; return to shader part epilog
;
; GFX12-LABEL: sample_c_d_1d:
; GFX12:       ; %bb.0: ; %main_body
; GFX12-NEXT:    image_sample_c_d_g16 v[0:3], [v0, v1, v2, v3], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_1D ; encoding: [0x00,0x80,0xce,0xe7,0x00,0x00,0x00,0x04,0x00,0x01,0x02,0x03]
; GFX12-NEXT:    s_wait_samplecnt 0x0 ; encoding: [0x00,0x00,0xc2,0xbf]
; GFX12-NEXT:    ; return to shader part epilog
main_body:
  %v = call <4 x float> @llvm.amdgcn.image.sample.c.d.1d.v4f32.f16.f32(i32 15, float %zcompare, half %dsdh, half %dsdv, float %s, <8 x i32> %rsrc, <4 x i32> %samp, i1 0, i32 0, i32 0)
  ret <4 x float> %v
}

define amdgpu_ps <4 x float> @sample_c_d_2d(<8 x i32> inreg %rsrc, <4 x i32> inreg %samp, float %zcompare, half %dsdh, half %dtdh, half %dsdv, half %dtdv, float %s, float %t) {
; GFX10-LABEL: sample_c_d_2d:
; GFX10:       ; %bb.0: ; %main_body
; GFX10-NEXT:    v_perm_b32 v3, v4, v3, 0x5040100 ; encoding: [0x03,0x00,0x44,0xd7,0x04,0x07,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX10-NEXT:    v_perm_b32 v1, v2, v1, 0x5040100 ; encoding: [0x01,0x00,0x44,0xd7,0x02,0x03,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX10-NEXT:    image_sample_c_d_g16 v[0:3], [v0, v1, v3, v5, v6], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_2D ; encoding: [0x0b,0x0f,0xa8,0xf0,0x00,0x00,0x40,0x00,0x01,0x03,0x05,0x06]
; GFX10-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0x70,0x3f,0x8c,0xbf]
; GFX10-NEXT:    ; return to shader part epilog
;
; GFX11-TRUE16-LABEL: sample_c_d_2d:
; GFX11-TRUE16:       ; %bb.0: ; %main_body
; GFX11-TRUE16-NEXT:    v_mov_b16_e32 v3.h, v4.l ; encoding: [0x04,0x39,0x06,0x7f]
; GFX11-TRUE16-NEXT:    v_mov_b16_e32 v1.h, v2.l ; encoding: [0x02,0x39,0x02,0x7f]
; GFX11-TRUE16-NEXT:    image_sample_c_d_g16 v[0:3], [v0, v1, v3, v5, v6], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_2D ; encoding: [0x05,0x0f,0xe8,0xf0,0x00,0x00,0x00,0x08,0x01,0x03,0x05,0x06]
; GFX11-TRUE16-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0xf7,0x03,0x89,0xbf]
; GFX11-TRUE16-NEXT:    ; return to shader part epilog
;
; GFX11-FAKE16-LABEL: sample_c_d_2d:
; GFX11-FAKE16:       ; %bb.0: ; %main_body
; GFX11-FAKE16-NEXT:    v_perm_b32 v3, v4, v3, 0x5040100 ; encoding: [0x03,0x00,0x44,0xd6,0x04,0x07,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX11-FAKE16-NEXT:    v_perm_b32 v1, v2, v1, 0x5040100 ; encoding: [0x01,0x00,0x44,0xd6,0x02,0x03,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX11-FAKE16-NEXT:    image_sample_c_d_g16 v[0:3], [v0, v1, v3, v5, v6], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_2D ; encoding: [0x05,0x0f,0xe8,0xf0,0x00,0x00,0x00,0x08,0x01,0x03,0x05,0x06]
; GFX11-FAKE16-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0xf7,0x03,0x89,0xbf]
; GFX11-FAKE16-NEXT:    ; return to shader part epilog
;
; GFX12-TRUE16-LABEL: sample_c_d_2d:
; GFX12-TRUE16:       ; %bb.0: ; %main_body
; GFX12-TRUE16-NEXT:    v_mov_b16_e32 v3.h, v4.l ; encoding: [0x04,0x39,0x06,0x7f]
; GFX12-TRUE16-NEXT:    v_mov_b16_e32 v1.h, v2.l ; encoding: [0x02,0x39,0x02,0x7f]
; GFX12-TRUE16-NEXT:    image_sample_c_d_g16 v[0:3], [v0, v1, v3, v[5:6]], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_2D ; encoding: [0x01,0x80,0xce,0xe7,0x00,0x00,0x00,0x04,0x00,0x01,0x03,0x05]
; GFX12-TRUE16-NEXT:    s_wait_samplecnt 0x0 ; encoding: [0x00,0x00,0xc2,0xbf]
; GFX12-TRUE16-NEXT:    ; return to shader part epilog
;
; GFX12-FAKE16-LABEL: sample_c_d_2d:
; GFX12-FAKE16:       ; %bb.0: ; %main_body
; GFX12-FAKE16-NEXT:    v_perm_b32 v3, v4, v3, 0x5040100 ; encoding: [0x03,0x00,0x44,0xd6,0x04,0x07,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX12-FAKE16-NEXT:    v_perm_b32 v1, v2, v1, 0x5040100 ; encoding: [0x01,0x00,0x44,0xd6,0x02,0x03,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX12-FAKE16-NEXT:    image_sample_c_d_g16 v[0:3], [v0, v1, v3, v[5:6]], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_2D ; encoding: [0x01,0x80,0xce,0xe7,0x00,0x00,0x00,0x04,0x00,0x01,0x03,0x05]
; GFX12-FAKE16-NEXT:    s_wait_samplecnt 0x0 ; encoding: [0x00,0x00,0xc2,0xbf]
; GFX12-FAKE16-NEXT:    ; return to shader part epilog
main_body:
  %v = call <4 x float> @llvm.amdgcn.image.sample.c.d.2d.v4f32.f16.f32(i32 15, float %zcompare, half %dsdh, half %dtdh, half %dsdv, half %dtdv, float %s, float %t, <8 x i32> %rsrc, <4 x i32> %samp, i1 0, i32 0, i32 0)
  ret <4 x float> %v
}

define amdgpu_ps <4 x float> @sample_d_cl_1d(<8 x i32> inreg %rsrc, <4 x i32> inreg %samp, half %dsdh, half %dsdv, float %s, float %clamp) {
; GFX10-LABEL: sample_d_cl_1d:
; GFX10:       ; %bb.0: ; %main_body
; GFX10-NEXT:    image_sample_d_cl_g16 v[0:3], v[0:3], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_1D ; encoding: [0x01,0x0f,0x8c,0xf0,0x00,0x00,0x40,0x00]
; GFX10-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0x70,0x3f,0x8c,0xbf]
; GFX10-NEXT:    ; return to shader part epilog
;
; GFX11-LABEL: sample_d_cl_1d:
; GFX11:       ; %bb.0: ; %main_body
; GFX11-NEXT:    image_sample_d_cl_g16 v[0:3], v[0:3], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_1D ; encoding: [0x00,0x0f,0x7c,0xf1,0x00,0x00,0x00,0x08]
; GFX11-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0xf7,0x03,0x89,0xbf]
; GFX11-NEXT:    ; return to shader part epilog
;
; GFX12-LABEL: sample_d_cl_1d:
; GFX12:       ; %bb.0: ; %main_body
; GFX12-NEXT:    image_sample_d_cl_g16 v[0:3], [v0, v1, v2, v3], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_1D ; encoding: [0x00,0xc0,0xd7,0xe7,0x00,0x00,0x00,0x04,0x00,0x01,0x02,0x03]
; GFX12-NEXT:    s_wait_samplecnt 0x0 ; encoding: [0x00,0x00,0xc2,0xbf]
; GFX12-NEXT:    ; return to shader part epilog
main_body:
  %v = call <4 x float> @llvm.amdgcn.image.sample.d.cl.1d.v4f32.f16.f32(i32 15, half %dsdh, half %dsdv, float %s, float %clamp, <8 x i32> %rsrc, <4 x i32> %samp, i1 0, i32 0, i32 0)
  ret <4 x float> %v
}

define amdgpu_ps <4 x float> @sample_d_cl_2d(<8 x i32> inreg %rsrc, <4 x i32> inreg %samp, half %dsdh, half %dtdh, half %dsdv, half %dtdv, float %s, float %t, float %clamp) {
; GFX10-LABEL: sample_d_cl_2d:
; GFX10:       ; %bb.0: ; %main_body
; GFX10-NEXT:    v_perm_b32 v2, v3, v2, 0x5040100 ; encoding: [0x02,0x00,0x44,0xd7,0x03,0x05,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX10-NEXT:    v_perm_b32 v0, v1, v0, 0x5040100 ; encoding: [0x00,0x00,0x44,0xd7,0x01,0x01,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX10-NEXT:    image_sample_d_cl_g16 v[0:3], [v0, v2, v4, v5, v6], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_2D ; encoding: [0x0b,0x0f,0x8c,0xf0,0x00,0x00,0x40,0x00,0x02,0x04,0x05,0x06]
; GFX10-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0x70,0x3f,0x8c,0xbf]
; GFX10-NEXT:    ; return to shader part epilog
;
; GFX11-TRUE16-LABEL: sample_d_cl_2d:
; GFX11-TRUE16:       ; %bb.0: ; %main_body
; GFX11-TRUE16-NEXT:    v_mov_b16_e32 v2.h, v3.l ; encoding: [0x03,0x39,0x04,0x7f]
; GFX11-TRUE16-NEXT:    v_mov_b16_e32 v0.h, v1.l ; encoding: [0x01,0x39,0x00,0x7f]
; GFX11-TRUE16-NEXT:    image_sample_d_cl_g16 v[0:3], [v0, v2, v4, v5, v6], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_2D ; encoding: [0x05,0x0f,0x7c,0xf1,0x00,0x00,0x00,0x08,0x02,0x04,0x05,0x06]
; GFX11-TRUE16-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0xf7,0x03,0x89,0xbf]
; GFX11-TRUE16-NEXT:    ; return to shader part epilog
;
; GFX11-FAKE16-LABEL: sample_d_cl_2d:
; GFX11-FAKE16:       ; %bb.0: ; %main_body
; GFX11-FAKE16-NEXT:    v_perm_b32 v2, v3, v2, 0x5040100 ; encoding: [0x02,0x00,0x44,0xd6,0x03,0x05,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX11-FAKE16-NEXT:    v_perm_b32 v0, v1, v0, 0x5040100 ; encoding: [0x00,0x00,0x44,0xd6,0x01,0x01,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX11-FAKE16-NEXT:    image_sample_d_cl_g16 v[0:3], [v0, v2, v4, v5, v6], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_2D ; encoding: [0x05,0x0f,0x7c,0xf1,0x00,0x00,0x00,0x08,0x02,0x04,0x05,0x06]
; GFX11-FAKE16-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0xf7,0x03,0x89,0xbf]
; GFX11-FAKE16-NEXT:    ; return to shader part epilog
;
; GFX12-TRUE16-LABEL: sample_d_cl_2d:
; GFX12-TRUE16:       ; %bb.0: ; %main_body
; GFX12-TRUE16-NEXT:    v_mov_b16_e32 v2.h, v3.l ; encoding: [0x03,0x39,0x04,0x7f]
; GFX12-TRUE16-NEXT:    v_mov_b16_e32 v0.h, v1.l ; encoding: [0x01,0x39,0x00,0x7f]
; GFX12-TRUE16-NEXT:    image_sample_d_cl_g16 v[0:3], [v0, v2, v4, v[5:6]], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_2D ; encoding: [0x01,0xc0,0xd7,0xe7,0x00,0x00,0x00,0x04,0x00,0x02,0x04,0x05]
; GFX12-TRUE16-NEXT:    s_wait_samplecnt 0x0 ; encoding: [0x00,0x00,0xc2,0xbf]
; GFX12-TRUE16-NEXT:    ; return to shader part epilog
;
; GFX12-FAKE16-LABEL: sample_d_cl_2d:
; GFX12-FAKE16:       ; %bb.0: ; %main_body
; GFX12-FAKE16-NEXT:    v_perm_b32 v2, v3, v2, 0x5040100 ; encoding: [0x02,0x00,0x44,0xd6,0x03,0x05,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX12-FAKE16-NEXT:    v_perm_b32 v0, v1, v0, 0x5040100 ; encoding: [0x00,0x00,0x44,0xd6,0x01,0x01,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX12-FAKE16-NEXT:    image_sample_d_cl_g16 v[0:3], [v0, v2, v4, v[5:6]], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_2D ; encoding: [0x01,0xc0,0xd7,0xe7,0x00,0x00,0x00,0x04,0x00,0x02,0x04,0x05]
; GFX12-FAKE16-NEXT:    s_wait_samplecnt 0x0 ; encoding: [0x00,0x00,0xc2,0xbf]
; GFX12-FAKE16-NEXT:    ; return to shader part epilog
main_body:
  %v = call <4 x float> @llvm.amdgcn.image.sample.d.cl.2d.v4f32.f16.f32(i32 15, half %dsdh, half %dtdh, half %dsdv, half %dtdv, float %s, float %t, float %clamp, <8 x i32> %rsrc, <4 x i32> %samp, i1 0, i32 0, i32 0)
  ret <4 x float> %v
}

define amdgpu_ps <4 x float> @sample_c_d_cl_1d(<8 x i32> inreg %rsrc, <4 x i32> inreg %samp, float %zcompare, half %dsdh, half %dsdv, float %s, float %clamp) {
; GFX10-LABEL: sample_c_d_cl_1d:
; GFX10:       ; %bb.0: ; %main_body
; GFX10-NEXT:    image_sample_c_d_cl_g16 v[0:3], v[0:4], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_1D ; encoding: [0x01,0x0f,0xac,0xf0,0x00,0x00,0x40,0x00]
; GFX10-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0x70,0x3f,0x8c,0xbf]
; GFX10-NEXT:    ; return to shader part epilog
;
; GFX11-LABEL: sample_c_d_cl_1d:
; GFX11:       ; %bb.0: ; %main_body
; GFX11-NEXT:    image_sample_c_d_cl_g16 v[0:3], v[0:4], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_1D ; encoding: [0x00,0x0f,0x50,0xf1,0x00,0x00,0x00,0x08]
; GFX11-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0xf7,0x03,0x89,0xbf]
; GFX11-NEXT:    ; return to shader part epilog
;
; GFX12-LABEL: sample_c_d_cl_1d:
; GFX12:       ; %bb.0: ; %main_body
; GFX12-NEXT:    image_sample_c_d_cl_g16 v[0:3], [v0, v1, v2, v[3:4]], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_1D ; encoding: [0x00,0x00,0xd5,0xe7,0x00,0x00,0x00,0x04,0x00,0x01,0x02,0x03]
; GFX12-NEXT:    s_wait_samplecnt 0x0 ; encoding: [0x00,0x00,0xc2,0xbf]
; GFX12-NEXT:    ; return to shader part epilog
main_body:
  %v = call <4 x float> @llvm.amdgcn.image.sample.c.d.cl.1d.v4f32.f16.f32(i32 15, float %zcompare, half %dsdh, half %dsdv, float %s, float %clamp, <8 x i32> %rsrc, <4 x i32> %samp, i1 0, i32 0, i32 0)
  ret <4 x float> %v
}

define amdgpu_ps <4 x float> @sample_c_d_cl_2d(<8 x i32> inreg %rsrc, <4 x i32> inreg %samp, float %zcompare, half %dsdh, half %dtdh, half %dsdv, half %dtdv, float %s, float %t, float %clamp) {
; GFX10-LABEL: sample_c_d_cl_2d:
; GFX10:       ; %bb.0: ; %main_body
; GFX10-NEXT:    v_mov_b32_e32 v8, v2 ; encoding: [0x02,0x03,0x10,0x7e]
; GFX10-NEXT:    v_mov_b32_e32 v2, v0 ; encoding: [0x00,0x03,0x04,0x7e]
; GFX10-NEXT:    v_perm_b32 v4, v4, v3, 0x5040100 ; encoding: [0x04,0x00,0x44,0xd7,0x04,0x07,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX10-NEXT:    v_perm_b32 v3, v8, v1, 0x5040100 ; encoding: [0x03,0x00,0x44,0xd7,0x08,0x03,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX10-NEXT:    image_sample_c_d_cl_g16 v[0:3], v[2:7], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_2D ; encoding: [0x09,0x0f,0xac,0xf0,0x02,0x00,0x40,0x00]
; GFX10-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0x70,0x3f,0x8c,0xbf]
; GFX10-NEXT:    ; return to shader part epilog
;
; GFX11-TRUE16-LABEL: sample_c_d_cl_2d:
; GFX11-TRUE16:       ; %bb.0: ; %main_body
; GFX11-TRUE16-NEXT:    v_mov_b16_e32 v3.h, v4.l ; encoding: [0x04,0x39,0x06,0x7f]
; GFX11-TRUE16-NEXT:    v_mov_b16_e32 v1.h, v2.l ; encoding: [0x02,0x39,0x02,0x7f]
; GFX11-TRUE16-NEXT:    image_sample_c_d_cl_g16 v[0:3], [v0, v1, v3, v5, v[6:7]], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_2D ; encoding: [0x05,0x0f,0x50,0xf1,0x00,0x00,0x00,0x08,0x01,0x03,0x05,0x06]
; GFX11-TRUE16-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0xf7,0x03,0x89,0xbf]
; GFX11-TRUE16-NEXT:    ; return to shader part epilog
;
; GFX11-FAKE16-LABEL: sample_c_d_cl_2d:
; GFX11-FAKE16:       ; %bb.0: ; %main_body
; GFX11-FAKE16-NEXT:    v_perm_b32 v3, v4, v3, 0x5040100 ; encoding: [0x03,0x00,0x44,0xd6,0x04,0x07,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX11-FAKE16-NEXT:    v_perm_b32 v1, v2, v1, 0x5040100 ; encoding: [0x01,0x00,0x44,0xd6,0x02,0x03,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX11-FAKE16-NEXT:    image_sample_c_d_cl_g16 v[0:3], [v0, v1, v3, v5, v[6:7]], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_2D ; encoding: [0x05,0x0f,0x50,0xf1,0x00,0x00,0x00,0x08,0x01,0x03,0x05,0x06]
; GFX11-FAKE16-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0xf7,0x03,0x89,0xbf]
; GFX11-FAKE16-NEXT:    ; return to shader part epilog
;
; GFX12-TRUE16-LABEL: sample_c_d_cl_2d:
; GFX12-TRUE16:       ; %bb.0: ; %main_body
; GFX12-TRUE16-NEXT:    v_mov_b16_e32 v3.h, v4.l ; encoding: [0x04,0x39,0x06,0x7f]
; GFX12-TRUE16-NEXT:    v_mov_b16_e32 v1.h, v2.l ; encoding: [0x02,0x39,0x02,0x7f]
; GFX12-TRUE16-NEXT:    image_sample_c_d_cl_g16 v[0:3], [v0, v1, v3, v[5:7]], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_2D ; encoding: [0x01,0x00,0xd5,0xe7,0x00,0x00,0x00,0x04,0x00,0x01,0x03,0x05]
; GFX12-TRUE16-NEXT:    s_wait_samplecnt 0x0 ; encoding: [0x00,0x00,0xc2,0xbf]
; GFX12-TRUE16-NEXT:    ; return to shader part epilog
;
; GFX12-FAKE16-LABEL: sample_c_d_cl_2d:
; GFX12-FAKE16:       ; %bb.0: ; %main_body
; GFX12-FAKE16-NEXT:    v_perm_b32 v3, v4, v3, 0x5040100 ; encoding: [0x03,0x00,0x44,0xd6,0x04,0x07,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX12-FAKE16-NEXT:    v_perm_b32 v1, v2, v1, 0x5040100 ; encoding: [0x01,0x00,0x44,0xd6,0x02,0x03,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX12-FAKE16-NEXT:    image_sample_c_d_cl_g16 v[0:3], [v0, v1, v3, v[5:7]], s[0:7], s[8:11] dmask:0xf dim:SQ_RSRC_IMG_2D ; encoding: [0x01,0x00,0xd5,0xe7,0x00,0x00,0x00,0x04,0x00,0x01,0x03,0x05]
; GFX12-FAKE16-NEXT:    s_wait_samplecnt 0x0 ; encoding: [0x00,0x00,0xc2,0xbf]
; GFX12-FAKE16-NEXT:    ; return to shader part epilog
main_body:
  %v = call <4 x float> @llvm.amdgcn.image.sample.c.d.cl.2d.v4f32.f16.f32(i32 15, float %zcompare, half %dsdh, half %dtdh, half %dsdv, half %dtdv, float %s, float %t, float %clamp, <8 x i32> %rsrc, <4 x i32> %samp, i1 0, i32 0, i32 0)
  ret <4 x float> %v
}

define amdgpu_ps float @sample_c_d_o_2darray_V1(<8 x i32> inreg %rsrc, <4 x i32> inreg %samp, i32 %offset, float %zcompare, half %dsdh, half %dtdh, half %dsdv, half %dtdv, float %s, float %t, float %slice) {
; GFX10-LABEL: sample_c_d_o_2darray_V1:
; GFX10:       ; %bb.0: ; %main_body
; GFX10-NEXT:    v_mov_b32_e32 v9, v3 ; encoding: [0x03,0x03,0x12,0x7e]
; GFX10-NEXT:    v_mov_b32_e32 v10, v2 ; encoding: [0x02,0x03,0x14,0x7e]
; GFX10-NEXT:    v_mov_b32_e32 v3, v1 ; encoding: [0x01,0x03,0x06,0x7e]
; GFX10-NEXT:    v_mov_b32_e32 v2, v0 ; encoding: [0x00,0x03,0x04,0x7e]
; GFX10-NEXT:    v_perm_b32 v5, v5, v4, 0x5040100 ; encoding: [0x05,0x00,0x44,0xd7,0x05,0x09,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX10-NEXT:    v_perm_b32 v4, v9, v10, 0x5040100 ; encoding: [0x04,0x00,0x44,0xd7,0x09,0x15,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX10-NEXT:    image_sample_c_d_o_g16 v0, v[2:8], s[0:7], s[8:11] dmask:0x4 dim:SQ_RSRC_IMG_2D_ARRAY ; encoding: [0x29,0x04,0xe8,0xf0,0x02,0x00,0x40,0x00]
; GFX10-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0x70,0x3f,0x8c,0xbf]
; GFX10-NEXT:    ; return to shader part epilog
;
; GFX11-TRUE16-LABEL: sample_c_d_o_2darray_V1:
; GFX11-TRUE16:       ; %bb.0: ; %main_body
; GFX11-TRUE16-NEXT:    v_mov_b16_e32 v4.h, v5.l ; encoding: [0x05,0x39,0x08,0x7f]
; GFX11-TRUE16-NEXT:    v_mov_b16_e32 v2.h, v3.l ; encoding: [0x03,0x39,0x04,0x7f]
; GFX11-TRUE16-NEXT:    image_sample_c_d_o_g16 v0, [v0, v1, v2, v4, v[6:8]], s[0:7], s[8:11] dmask:0x4 dim:SQ_RSRC_IMG_2D_ARRAY ; encoding: [0x15,0x04,0xf0,0xf0,0x00,0x00,0x00,0x08,0x01,0x02,0x04,0x06]
; GFX11-TRUE16-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0xf7,0x03,0x89,0xbf]
; GFX11-TRUE16-NEXT:    ; return to shader part epilog
;
; GFX11-FAKE16-LABEL: sample_c_d_o_2darray_V1:
; GFX11-FAKE16:       ; %bb.0: ; %main_body
; GFX11-FAKE16-NEXT:    v_perm_b32 v4, v5, v4, 0x5040100 ; encoding: [0x04,0x00,0x44,0xd6,0x05,0x09,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX11-FAKE16-NEXT:    v_perm_b32 v2, v3, v2, 0x5040100 ; encoding: [0x02,0x00,0x44,0xd6,0x03,0x05,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX11-FAKE16-NEXT:    image_sample_c_d_o_g16 v0, [v0, v1, v2, v4, v[6:8]], s[0:7], s[8:11] dmask:0x4 dim:SQ_RSRC_IMG_2D_ARRAY ; encoding: [0x15,0x04,0xf0,0xf0,0x00,0x00,0x00,0x08,0x01,0x02,0x04,0x06]
; GFX11-FAKE16-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0xf7,0x03,0x89,0xbf]
; GFX11-FAKE16-NEXT:    ; return to shader part epilog
;
; GFX12-TRUE16-LABEL: sample_c_d_o_2darray_V1:
; GFX12-TRUE16:       ; %bb.0: ; %main_body
; GFX12-TRUE16-NEXT:    v_mov_b32_e32 v9, v5 ; encoding: [0x05,0x03,0x12,0x7e]
; GFX12-TRUE16-NEXT:    v_mov_b16_e32 v5.l, v4.l ; encoding: [0x04,0x39,0x0a,0x7e]
; GFX12-TRUE16-NEXT:    v_mov_b16_e32 v2.h, v3.l ; encoding: [0x03,0x39,0x04,0x7f]
; GFX12-TRUE16-NEXT:    s_delay_alu instid0(VALU_DEP_3) ; encoding: [0x03,0x00,0x87,0xbf]
; GFX12-TRUE16-NEXT:    v_mov_b16_e32 v5.h, v9.l ; encoding: [0x09,0x39,0x0a,0x7f]
; GFX12-TRUE16-NEXT:    image_sample_c_d_o_g16 v0, [v0, v1, v2, v[5:8]], s[0:7], s[8:11] dmask:0x4 dim:SQ_RSRC_IMG_2D_ARRAY ; encoding: [0x05,0x00,0x0f,0xe5,0x00,0x00,0x00,0x04,0x00,0x01,0x02,0x05]
; GFX12-TRUE16-NEXT:    s_wait_samplecnt 0x0 ; encoding: [0x00,0x00,0xc2,0xbf]
; GFX12-TRUE16-NEXT:    ; return to shader part epilog
;
; GFX12-FAKE16-LABEL: sample_c_d_o_2darray_V1:
; GFX12-FAKE16:       ; %bb.0: ; %main_body
; GFX12-FAKE16-NEXT:    v_perm_b32 v5, v5, v4, 0x5040100 ; encoding: [0x05,0x00,0x44,0xd6,0x05,0x09,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX12-FAKE16-NEXT:    v_perm_b32 v2, v3, v2, 0x5040100 ; encoding: [0x02,0x00,0x44,0xd6,0x03,0x05,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX12-FAKE16-NEXT:    image_sample_c_d_o_g16 v0, [v0, v1, v2, v[5:8]], s[0:7], s[8:11] dmask:0x4 dim:SQ_RSRC_IMG_2D_ARRAY ; encoding: [0x05,0x00,0x0f,0xe5,0x00,0x00,0x00,0x04,0x00,0x01,0x02,0x05]
; GFX12-FAKE16-NEXT:    s_wait_samplecnt 0x0 ; encoding: [0x00,0x00,0xc2,0xbf]
; GFX12-FAKE16-NEXT:    ; return to shader part epilog
main_body:
  %v = call float @llvm.amdgcn.image.sample.c.d.o.2darray.f16.f32.f32(i32 4, i32 %offset, float %zcompare, half %dsdh, half %dtdh, half %dsdv, half %dtdv, float %s, float %t, float %slice, <8 x i32> %rsrc, <4 x i32> %samp, i1 0, i32 0, i32 0)
  ret float %v
}

define amdgpu_ps <2 x float> @sample_c_d_o_2darray_V2(<8 x i32> inreg %rsrc, <4 x i32> inreg %samp, i32 %offset, float %zcompare, half %dsdh, half %dtdh, half %dsdv, half %dtdv, float %s, float %t, float %slice) {
; GFX10-LABEL: sample_c_d_o_2darray_V2:
; GFX10:       ; %bb.0: ; %main_body
; GFX10-NEXT:    v_mov_b32_e32 v9, v3 ; encoding: [0x03,0x03,0x12,0x7e]
; GFX10-NEXT:    v_mov_b32_e32 v10, v2 ; encoding: [0x02,0x03,0x14,0x7e]
; GFX10-NEXT:    v_mov_b32_e32 v3, v1 ; encoding: [0x01,0x03,0x06,0x7e]
; GFX10-NEXT:    v_mov_b32_e32 v2, v0 ; encoding: [0x00,0x03,0x04,0x7e]
; GFX10-NEXT:    v_perm_b32 v5, v5, v4, 0x5040100 ; encoding: [0x05,0x00,0x44,0xd7,0x05,0x09,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX10-NEXT:    v_perm_b32 v4, v9, v10, 0x5040100 ; encoding: [0x04,0x00,0x44,0xd7,0x09,0x15,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX10-NEXT:    image_sample_c_d_o_g16 v[0:1], v[2:8], s[0:7], s[8:11] dmask:0x6 dim:SQ_RSRC_IMG_2D_ARRAY ; encoding: [0x29,0x06,0xe8,0xf0,0x02,0x00,0x40,0x00]
; GFX10-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0x70,0x3f,0x8c,0xbf]
; GFX10-NEXT:    ; return to shader part epilog
;
; GFX11-TRUE16-LABEL: sample_c_d_o_2darray_V2:
; GFX11-TRUE16:       ; %bb.0: ; %main_body
; GFX11-TRUE16-NEXT:    v_mov_b16_e32 v4.h, v5.l ; encoding: [0x05,0x39,0x08,0x7f]
; GFX11-TRUE16-NEXT:    v_mov_b16_e32 v2.h, v3.l ; encoding: [0x03,0x39,0x04,0x7f]
; GFX11-TRUE16-NEXT:    image_sample_c_d_o_g16 v[0:1], [v0, v1, v2, v4, v[6:8]], s[0:7], s[8:11] dmask:0x6 dim:SQ_RSRC_IMG_2D_ARRAY ; encoding: [0x15,0x06,0xf0,0xf0,0x00,0x00,0x00,0x08,0x01,0x02,0x04,0x06]
; GFX11-TRUE16-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0xf7,0x03,0x89,0xbf]
; GFX11-TRUE16-NEXT:    ; return to shader part epilog
;
; GFX11-FAKE16-LABEL: sample_c_d_o_2darray_V2:
; GFX11-FAKE16:       ; %bb.0: ; %main_body
; GFX11-FAKE16-NEXT:    v_perm_b32 v4, v5, v4, 0x5040100 ; encoding: [0x04,0x00,0x44,0xd6,0x05,0x09,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX11-FAKE16-NEXT:    v_perm_b32 v2, v3, v2, 0x5040100 ; encoding: [0x02,0x00,0x44,0xd6,0x03,0x05,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX11-FAKE16-NEXT:    image_sample_c_d_o_g16 v[0:1], [v0, v1, v2, v4, v[6:8]], s[0:7], s[8:11] dmask:0x6 dim:SQ_RSRC_IMG_2D_ARRAY ; encoding: [0x15,0x06,0xf0,0xf0,0x00,0x00,0x00,0x08,0x01,0x02,0x04,0x06]
; GFX11-FAKE16-NEXT:    s_waitcnt vmcnt(0) ; encoding: [0xf7,0x03,0x89,0xbf]
; GFX11-FAKE16-NEXT:    ; return to shader part epilog
;
; GFX12-TRUE16-LABEL: sample_c_d_o_2darray_V2:
; GFX12-TRUE16:       ; %bb.0: ; %main_body
; GFX12-TRUE16-NEXT:    v_mov_b32_e32 v9, v5 ; encoding: [0x05,0x03,0x12,0x7e]
; GFX12-TRUE16-NEXT:    v_mov_b16_e32 v5.l, v4.l ; encoding: [0x04,0x39,0x0a,0x7e]
; GFX12-TRUE16-NEXT:    v_mov_b16_e32 v2.h, v3.l ; encoding: [0x03,0x39,0x04,0x7f]
; GFX12-TRUE16-NEXT:    s_delay_alu instid0(VALU_DEP_3) ; encoding: [0x03,0x00,0x87,0xbf]
; GFX12-TRUE16-NEXT:    v_mov_b16_e32 v5.h, v9.l ; encoding: [0x09,0x39,0x0a,0x7f]
; GFX12-TRUE16-NEXT:    image_sample_c_d_o_g16 v[0:1], [v0, v1, v2, v[5:8]], s[0:7], s[8:11] dmask:0x6 dim:SQ_RSRC_IMG_2D_ARRAY ; encoding: [0x05,0x00,0x8f,0xe5,0x00,0x00,0x00,0x04,0x00,0x01,0x02,0x05]
; GFX12-TRUE16-NEXT:    s_wait_samplecnt 0x0 ; encoding: [0x00,0x00,0xc2,0xbf]
; GFX12-TRUE16-NEXT:    ; return to shader part epilog
;
; GFX12-FAKE16-LABEL: sample_c_d_o_2darray_V2:
; GFX12-FAKE16:       ; %bb.0: ; %main_body
; GFX12-FAKE16-NEXT:    v_perm_b32 v5, v5, v4, 0x5040100 ; encoding: [0x05,0x00,0x44,0xd6,0x05,0x09,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX12-FAKE16-NEXT:    v_perm_b32 v2, v3, v2, 0x5040100 ; encoding: [0x02,0x00,0x44,0xd6,0x03,0x05,0xfe,0x03,0x00,0x01,0x04,0x05]
; GFX12-FAKE16-NEXT:    image_sample_c_d_o_g16 v[0:1], [v0, v1, v2, v[5:8]], s[0:7], s[8:11] dmask:0x6 dim:SQ_RSRC_IMG_2D_ARRAY ; encoding: [0x05,0x00,0x8f,0xe5,0x00,0x00,0x00,0x04,0x00,0x01,0x02,0x05]
; GFX12-FAKE16-NEXT:    s_wait_samplecnt 0x0 ; encoding: [0x00,0x00,0xc2,0xbf]
; GFX12-FAKE16-NEXT:    ; return to shader part epilog
main_body:
  %v = call <2 x float> @llvm.amdgcn.image.sample.c.d.o.2darray.v2f32.f16.f32(i32 6, i32 %offset, float %zcompare, half %dsdh, half %dtdh, half %dsdv, half %dtdv, float %s, float %t, float %slice, <8 x i32> %rsrc, <4 x i32> %samp, i1 0, i32 0, i32 0)
  ret <2 x float> %v
}

declare <4 x float> @llvm.amdgcn.image.sample.d.1d.v4f32.f16.f32(i32, half, half, float, <8 x i32>, <4 x i32>, i1, i32, i32) #1
declare <4 x float> @llvm.amdgcn.image.sample.d.2d.v4f32.f16.f32(i32, half, half, half, half, float, float, <8 x i32>, <4 x i32>, i1, i32, i32) #1
declare <4 x float> @llvm.amdgcn.image.sample.d.3d.v4f32.f16.f32(i32, half, half, half, half, half, half, float, float, float, <8 x i32>, <4 x i32>, i1, i32, i32) #1
declare <4 x float> @llvm.amdgcn.image.sample.c.d.1d.v4f32.f16.f32(i32, float, half, half, float, <8 x i32>, <4 x i32>, i1, i32, i32) #1
declare <4 x float> @llvm.amdgcn.image.sample.c.d.2d.v4f32.f16.f32(i32, float, half, half, half, half, float, float, <8 x i32>, <4 x i32>, i1, i32, i32) #1
declare <4 x float> @llvm.amdgcn.image.sample.d.cl.1d.v4f32.f16.f32(i32, half, half, float, float, <8 x i32>, <4 x i32>, i1, i32, i32) #1
declare <4 x float> @llvm.amdgcn.image.sample.d.cl.2d.v4f32.f16.f32(i32, half, half, half, half, float, float, float, <8 x i32>, <4 x i32>, i1, i32, i32) #1
declare <4 x float> @llvm.amdgcn.image.sample.c.d.cl.1d.v4f32.f16.f32(i32, float, half, half, float, float, <8 x i32>, <4 x i32>, i1, i32, i32) #1
declare <4 x float> @llvm.amdgcn.image.sample.c.d.cl.2d.v4f32.f16.f32(i32, float, half, half, half, half, float, float, float, <8 x i32>, <4 x i32>, i1, i32, i32) #1

declare float @llvm.amdgcn.image.sample.c.d.o.2darray.f16.f32.f32(i32, i32, float, half, half, half, half, float, float, float, <8 x i32>, <4 x i32>, i1, i32, i32) #1
declare <2 x float> @llvm.amdgcn.image.sample.c.d.o.2darray.v2f32.f16.f32(i32, i32, float, half, half, half, half, float, float, float, <8 x i32>, <4 x i32>, i1, i32, i32) #1

attributes #0 = { nounwind }
attributes #1 = { nounwind readonly }
attributes #2 = { nounwind readnone }
