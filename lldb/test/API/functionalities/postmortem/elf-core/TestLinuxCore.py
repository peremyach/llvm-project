"""
Test basics of linux core file debugging.
"""

import shutil
import struct
import os

import lldb
from lldbsuite.test.decorators import *
from lldbsuite.test.lldbtest import *
from lldbsuite.test import lldbutil


class LinuxCoreTestCase(TestBase):
    NO_DEBUG_INFO_TESTCASE = True

    _aarch64_pid = 37688
    _aarch64_pac_pid = 387
    _i386_pid = 32306
    _x86_64_pid = 32259
    _s390x_pid = 1045
    _ppc64le_pid = 28147
    _riscv64_gpr_fpr_pid = 1089
    _riscv64_gpr_only_pid = 97
    _loongarch64_pid = 456735

    _aarch64_regions = 4
    _i386_regions = 4
    _x86_64_regions = 5
    _s390x_regions = 2
    _ppc64le_regions = 2
    _riscv64_regions = 4
    _loongarch64_regions = 4

    @skipIfLLVMTargetMissing("AArch64")
    def test_aarch64(self):
        """Test that lldb can read the process information from an aarch64 linux core file."""
        self.do_test("linux-aarch64", self._aarch64_pid, self._aarch64_regions, "a.out")

    @skipIfLLVMTargetMissing("X86")
    def test_i386(self):
        """Test that lldb can read the process information from an i386 linux core file."""
        self.do_test("linux-i386", self._i386_pid, self._i386_regions, "a.out")

    @skipIfLLVMTargetMissing("PowerPC")
    def test_ppc64le(self):
        """Test that lldb can read the process information from an ppc64le linux core file."""
        self.do_test(
            "linux-ppc64le",
            self._ppc64le_pid,
            self._ppc64le_regions,
            "linux-ppc64le.ou",
        )

    @skipIfLLVMTargetMissing("X86")
    def test_x86_64(self):
        """Test that lldb can read the process information from an x86_64 linux core file."""
        self.do_test("linux-x86_64", self._x86_64_pid, self._x86_64_regions, "a.out")

    @skipIfLLVMTargetMissing("SystemZ")
    def test_s390x(self):
        """Test that lldb can read the process information from an s390x linux core file."""
        self.do_test("linux-s390x", self._s390x_pid, self._s390x_regions, "a.out")

    @skipIfLLVMTargetMissing("RISCV")
    def test_riscv64_gpr_fpr(self):
        """Test that lldb can read the process information from an riscv64 linux core file."""
        self.do_test(
            "linux-riscv64.gpr_fpr",
            self._riscv64_gpr_fpr_pid,
            self._riscv64_regions,
            "a.out",
        )

    @skipIfLLVMTargetMissing("RISCV")
    def test_riscv64_gpr_only(self):
        """Test that lldb can read the process information from an riscv64 linux core file
        made for a RV64IMAC target, having no FP-registers."""
        self.do_test(
            "linux-riscv64.gpr_only",
            self._riscv64_gpr_only_pid,
            self._riscv64_regions,
            "a.out",
        )

    @skipIfLLVMTargetMissing("LoongArch")
    def test_loongarch64(self):
        """Test that lldb can read the process information from an loongarch64 linux core file."""
        self.do_test(
            "linux-loongarch64",
            self._loongarch64_pid,
            self._loongarch64_regions,
            "a.out",
        )

    @skipIfLLVMTargetMissing("X86")
    def test_same_pid_running(self):
        """Test that we read the information from the core correctly even if we have a running
        process with the same PID around"""
        exe_file = self.getBuildArtifact("linux-x86_64-pid.out")
        core_file = self.getBuildArtifact("linux-x86_64-pid.core")
        shutil.copyfile("linux-x86_64.out", exe_file)
        shutil.copyfile("linux-x86_64.core", core_file)
        with open(core_file, "r+b") as f:
            # These are offsets into the NT_PRSTATUS and NT_PRPSINFO structures in the note
            # segment of the core file. If you update the file, these offsets may need updating
            # as well. (Notes can be viewed with readelf --notes.)
            for pid_offset in [0x1C4, 0x320]:
                f.seek(pid_offset)
                self.assertEqual(struct.unpack("<I", f.read(4))[0], self._x86_64_pid)

                # We insert our own pid, and make sure the test still
                # works.
                f.seek(pid_offset)
                f.write(struct.pack("<I", os.getpid()))
        self.do_test(
            self.getBuildArtifact("linux-x86_64-pid"),
            os.getpid(),
            self._x86_64_regions,
            "a.out",
        )

    @skipIfLLVMTargetMissing("X86")
    def test_two_cores_same_pid(self):
        """Test that we handle the situation if we have two core files with the same PID
        around"""
        alttarget = self.dbg.CreateTarget("altmain.out")
        altprocess = alttarget.LoadCore("altmain.core")
        self.assertTrue(altprocess, PROCESS_IS_VALID)
        self.assertEqual(altprocess.GetNumThreads(), 1)
        self.assertEqual(altprocess.GetProcessID(), self._x86_64_pid)

        altframe = altprocess.GetSelectedThread().GetFrameAtIndex(0)
        self.assertEqual(altframe.GetFunctionName(), "_start")
        self.assertEqual(
            altframe.GetLineEntry().GetLine(), line_number("altmain.c", "Frame _start")
        )

        error = lldb.SBError()
        F = altprocess.ReadCStringFromMemory(
            altframe.FindVariable("F").GetValueAsUnsigned(), 256, error
        )
        self.assertSuccess(error)
        self.assertEqual(F, "_start")

        # without destroying this process, run the test which opens another core file with the
        # same pid
        self.do_test("linux-x86_64", self._x86_64_pid, self._x86_64_regions, "a.out")

    @skipIfLLVMTargetMissing("X86")
    @skipIfWindows
    def test_read_memory(self):
        """Test that we are able to read as many bytes as available"""
        target = self.dbg.CreateTarget("linux-x86_64.out")
        process = target.LoadCore("linux-x86_64.core")
        self.assertTrue(process, PROCESS_IS_VALID)

        error = lldb.SBError()
        bytesread = process.ReadMemory(0x400FF0, 20, error)

        # read only 16 bytes without zero bytes filling
        self.assertEqual(len(bytesread), 16)
        self.dbg.DeleteTarget(target)

    @skipIfLLVMTargetMissing("X86")
    def test_write_register(self):
        """Test that writing to register results in an error and that error
        message is set."""
        target = self.dbg.CreateTarget("linux-x86_64.out")
        process = target.LoadCore("linux-x86_64.core")
        self.assertTrue(process, PROCESS_IS_VALID)

        thread = process.GetSelectedThread()
        self.assertTrue(thread)

        frame = thread.GetSelectedFrame()
        self.assertTrue(frame)

        reg_value = frame.FindRegister("eax")
        self.assertTrue(reg_value)

        error = lldb.SBError()
        success = reg_value.SetValueFromCString("10", error)
        self.assertFalse(success)
        self.assertTrue(error.Fail())
        self.assertIsNotNone(error.GetCString())

    @skipIfLLVMTargetMissing("X86")
    def test_FPR_SSE(self):
        # check x86_64 core file
        target = self.dbg.CreateTarget(None)
        self.assertTrue(target, VALID_TARGET)
        process = target.LoadCore("linux-fpr_sse_x86_64.core")

        values = {}
        values["fctrl"] = "0x037f"
        values["fstat"] = "0x0000"
        values["ftag"] = "0x00ff"
        values["fop"] = "0x0000"
        values["fiseg"] = "0x00000000"
        values["fioff"] = "0x0040011e"
        values["foseg"] = "0x00000000"
        values["fooff"] = "0x00000000"
        values["mxcsr"] = "0x00001f80"
        values["mxcsrmask"] = "0x0000ffff"
        values["st0"] = "{0x99 0xf7 0xcf 0xfb 0x84 0x9a 0x20 0x9a 0xfd 0x3f}"
        values["st1"] = "{0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x80 0xff 0x3f}"
        values["st2"] = "{0xfe 0x8a 0x1b 0xcd 0x4b 0x78 0x9a 0xd4 0x00 0x40}"
        values["st3"] = "{0xac 0x79 0xcf 0xd1 0xf7 0x17 0x72 0xb1 0xfe 0x3f}"
        values["st4"] = "{0xbc 0xf0 0x17 0x5c 0x29 0x3b 0xaa 0xb8 0xff 0x3f}"
        values["st5"] = "{0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x80 0xff 0x3f}"
        values["st6"] = "{0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values["st7"] = "{0x35 0xc2 0x68 0x21 0xa2 0xda 0x0f 0xc9 0x00 0x40}"
        values[
            "xmm0"
        ] = "{0x29 0x31 0x64 0x46 0x29 0x31 0x64 0x46 0x29 0x31 0x64 0x46 0x29 0x31 0x64 0x46}"
        values[
            "xmm1"
        ] = "{0x9c 0xed 0x86 0x64 0x9c 0xed 0x86 0x64 0x9c 0xed 0x86 0x64 0x9c 0xed 0x86 0x64}"
        values[
            "xmm2"
        ] = "{0x07 0xc2 0x1f 0xd7 0x07 0xc2 0x1f 0xd7 0x07 0xc2 0x1f 0xd7 0x07 0xc2 0x1f 0xd7}"
        values[
            "xmm3"
        ] = "{0xa2 0x20 0x48 0x25 0xa2 0x20 0x48 0x25 0xa2 0x20 0x48 0x25 0xa2 0x20 0x48 0x25}"
        values[
            "xmm4"
        ] = "{0xeb 0x5a 0xa8 0xc4 0xeb 0x5a 0xa8 0xc4 0xeb 0x5a 0xa8 0xc4 0xeb 0x5a 0xa8 0xc4}"
        values[
            "xmm5"
        ] = "{0x49 0x41 0x20 0x0b 0x49 0x41 0x20 0x0b 0x49 0x41 0x20 0x0b 0x49 0x41 0x20 0x0b}"
        values[
            "xmm6"
        ] = "{0xf8 0xf1 0x8b 0x4f 0xf8 0xf1 0x8b 0x4f 0xf8 0xf1 0x8b 0x4f 0xf8 0xf1 0x8b 0x4f}"
        values[
            "xmm7"
        ] = "{0x13 0xf1 0x30 0xcd 0x13 0xf1 0x30 0xcd 0x13 0xf1 0x30 0xcd 0x13 0xf1 0x30 0xcd}"

        for regname, value in values.items():
            self.expect(
                "register read {}".format(regname),
                substrs=["{} = {}".format(regname, value)],
            )

        # now check i386 core file
        target = self.dbg.CreateTarget(None)
        self.assertTrue(target, VALID_TARGET)
        process = target.LoadCore("linux-fpr_sse_i386.core")

        values["fioff"] = "0x080480cc"

        for regname, value in values.items():
            self.expect(
                "register read {}".format(regname),
                substrs=["{} = {}".format(regname, value)],
            )

    @skipIfLLVMTargetMissing("X86")
    def test_i386_sysroot(self):
        """Test that lldb can find the exe for an i386 linux core file using the sysroot."""

        # Copy linux-i386.out to tmp_sysroot/home/labath/test/a.out (since it was compiled as
        # /home/labath/test/a.out)
        tmp_sysroot = os.path.join(self.getBuildDir(), "lldb_i386_mock_sysroot")
        executable = os.path.join(tmp_sysroot, "home", "labath", "test", "a.out")
        lldbutil.mkdir_p(os.path.dirname(executable))
        shutil.copyfile("linux-i386.out", executable)

        # Set sysroot and load core
        self.runCmd("platform select remote-linux --sysroot '%s'" % tmp_sysroot)
        target = self.dbg.CreateTarget(None)
        self.assertTrue(target, VALID_TARGET)
        process = target.LoadCore("linux-i386.core")

        # Check that we found a.out from the sysroot
        self.check_all(process, self._i386_pid, self._i386_regions, "a.out")

        self.dbg.DeleteTarget(target)

    def test_object_map(self):
        """Test that lldb can find the exe for an i386 linux core file using the object map."""

        # Copy linux-i386.out to lldb_i386_object_map/a.out
        tmp_object_map_root = os.path.join(self.getBuildDir(), "lldb_i386_object_map")
        executable = os.path.join(tmp_object_map_root, "a.out")
        lldbutil.mkdir_p(os.path.dirname(executable))
        shutil.copyfile("linux-i386.out", executable)

        # Replace the original module path at /home/labath/test and load the core
        self.runCmd(
            "settings set target.object-map /home/labath/test {}".format(
                tmp_object_map_root
            )
        )

        target = self.dbg.CreateTarget(None)
        process = target.LoadCore("linux-i386.core")

        # Check that we did load the mapped executable
        exe_module_spec = process.GetTarget().GetModuleAtIndex(0).GetFileSpec()
        self.assertTrue(exe_module_spec.fullpath.startswith(tmp_object_map_root))

        self.check_all(process, self._i386_pid, self._i386_regions, "a.out")
        self.dbg.DeleteTarget(target)

    @skipIfLLVMTargetMissing("X86")
    @skipIfWindows
    def test_x86_64_sysroot(self):
        """Test that sysroot has more priority then local filesystem."""

        # Copy wrong executable to the location outside of sysroot
        exe_outside = os.path.join(self.getBuildDir(), "bin", "a.out")
        lldbutil.mkdir_p(os.path.dirname(exe_outside))
        shutil.copyfile("altmain.out", exe_outside)

        # Copy correct executable to the location inside sysroot
        tmp_sysroot = os.path.join(self.getBuildDir(), "mock_sysroot")
        exe_inside = os.path.join(tmp_sysroot, os.path.relpath(exe_outside, "/"))
        lldbutil.mkdir_p(os.path.dirname(exe_inside))
        shutil.copyfile("linux-x86_64.out", exe_inside)

        # Prepare patched core file
        core_file = os.path.join(self.getBuildDir(), "patched.core")
        with open("linux-x86_64.core", "rb") as f:
            core = f.read()
        core = replace_path(core, "/test" * 817 + "/a.out", exe_outside)
        with open(core_file, "wb") as f:
            f.write(core)

        # Set sysroot and load core
        self.runCmd("platform select remote-linux --sysroot '%s'" % tmp_sysroot)
        target = self.dbg.CreateTarget(None)
        self.assertTrue(target, VALID_TARGET)
        process = target.LoadCore(core_file)

        # Check that we found executable from the sysroot
        mod_path = str(target.GetModuleAtIndex(0).GetFileSpec())
        self.assertEqual(mod_path, exe_inside)
        self.check_all(process, self._x86_64_pid, self._x86_64_regions, "a.out")

        self.dbg.DeleteTarget(target)

    @skipIfLLVMTargetMissing("AArch64")
    def test_aarch64_pac(self):
        """Test that lldb can unwind stack for AArch64 elf core file with PAC enabled."""

        target = self.dbg.CreateTarget("linux-aarch64-pac.out")
        self.assertTrue(target, VALID_TARGET)
        process = target.LoadCore("linux-aarch64-pac.core")

        self.check_all(process, self._aarch64_pac_pid, self._aarch64_regions, "a.out")

        self.dbg.DeleteTarget(target)

    @skipIfLLVMTargetMissing("AArch64")
    # This test fails on FreeBSD 12 and earlier, see llvm.org/pr49415 for details.
    def test_aarch64_regs(self):
        # check 64 bit ARM core files
        target = self.dbg.CreateTarget(None)
        self.assertTrue(target, VALID_TARGET)
        process = target.LoadCore("linux-aarch64-neon.core")

        values = {}
        values["x1"] = "0x000000000000002f"
        values["w1"] = "0x0000002f"
        values["fp"] = "0x0000ffffdab7c770"
        values["lr"] = "0x000000000040019c"
        values["sp"] = "0x0000ffffdab7c750"
        values["pc"] = "0x0000000000400168"
        values[
            "v0"
        ] = "{0x00 0x00 0x00 0x00 0x00 0x00 0xe0 0x3f 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "v1"
        ] = "{0x00 0x00 0x00 0x00 0x00 0x00 0xf8 0x3f 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "v2"
        ] = "{0x00 0x00 0x00 0x00 0x00 0x00 0x04 0x40 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "v3"
        ] = "{0x00 0x00 0x00 0x00 0x00 0x00 0x0c 0x40 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "v4"
        ] = "{0x00 0x00 0x90 0x40 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "v5"
        ] = "{0x00 0x00 0xb0 0x40 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "v6"
        ] = "{0x00 0x00 0xd0 0x40 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "v7"
        ] = "{0x00 0x00 0xf0 0x40 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "v8"
        ] = "{0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11}"
        values[
            "v27"
        ] = "{0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "v28"
        ] = "{0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "v31"
        ] = "{0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30}"
        values["s2"] = "0"
        values["s3"] = "0"
        values["s4"] = "4.5"
        values["s5"] = "5.5"
        values["s6"] = "6.5"
        values["s7"] = "7.5"
        values["s8"] = "1.14437421E-28"
        values["s30"] = "0"
        values["s31"] = "6.40969056E-10"
        values["d0"] = "0.5"
        values["d1"] = "1.5"
        values["d2"] = "2.5"
        values["d3"] = "3.5"
        values["d4"] = "5.3516153614920076E-315"
        values["d5"] = "5.3619766690650802E-315"
        values["d6"] = "5.3723379766381528E-315"
        values["d7"] = "5.3826992842112254E-315"
        values["d8"] = "1.8010757365944223E-226"
        values["d30"] = "0"
        values["d31"] = "1.3980432860952889E-76"
        values["fpsr"] = "0x00000000"
        values["fpcr"] = "0x00000000"
        values["tpidr"] = "0x1122334455667788"

        for regname, value in values.items():
            self.expect(
                "register read {}".format(regname),
                substrs=["{} = {}".format(regname, value)],
            )

        self.expect("register read --all")

    @skipIfLLVMTargetMissing("AArch64")
    # This test fails on FreeBSD 12 and earlier, see llvm.org/pr49415 for details.
    def test_aarch64_sve_regs_fpsimd(self):
        # check 64 bit ARM core files
        target = self.dbg.CreateTarget(None)
        self.assertTrue(target, VALID_TARGET)
        process = target.LoadCore("linux-aarch64-sve-fpsimd.core")

        values = {}
        values["x1"] = "0x000000000000002f"
        values["w1"] = "0x0000002f"
        values["fp"] = "0x0000ffffcbad8d50"
        values["lr"] = "0x0000000000400180"
        values["sp"] = "0x0000ffffcbad8d30"
        values["pc"] = "0x000000000040014c"
        values["cpsr"] = "0x00001000"
        values[
            "v0"
        ] = "{0x00 0x00 0x00 0x00 0x00 0x00 0xe0 0x3f 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "v1"
        ] = "{0x00 0x00 0x00 0x00 0x00 0x00 0xf8 0x3f 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "v2"
        ] = "{0x00 0x00 0x00 0x00 0x00 0x00 0x04 0x40 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "v3"
        ] = "{0x00 0x00 0x00 0x00 0x00 0x00 0x0c 0x40 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "v4"
        ] = "{0x00 0x00 0x90 0x40 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "v5"
        ] = "{0x00 0x00 0xb0 0x40 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "v6"
        ] = "{0x00 0x00 0xd0 0x40 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "v7"
        ] = "{0x00 0x00 0xf0 0x40 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "v8"
        ] = "{0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11}"
        values[
            "v27"
        ] = "{0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "v28"
        ] = "{0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "v31"
        ] = "{0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30}"
        values["s2"] = "0"
        values["s3"] = "0"
        values["s4"] = "4.5"
        values["s5"] = "5.5"
        values["s6"] = "6.5"
        values["s7"] = "7.5"
        values["s8"] = "1.14437421E-28"
        values["s30"] = "0"
        values["s31"] = "6.40969056E-10"
        values["d0"] = "0.5"
        values["d1"] = "1.5"
        values["d2"] = "2.5"
        values["d3"] = "3.5"
        values["d4"] = "5.3516153614920076E-315"
        values["d5"] = "5.3619766690650802E-315"
        values["d6"] = "5.3723379766381528E-315"
        values["d7"] = "5.3826992842112254E-315"
        values["d8"] = "1.8010757365944223E-226"
        values["d30"] = "0"
        values["d31"] = "1.3980432860952889E-76"
        values["fpsr"] = "0x00000000"
        values["fpcr"] = "0x00000000"
        values["vg"] = "0x0000000000000004"
        values[
            "z0"
        ] = "{0x00 0x00 0x00 0x00 0x00 0x00 0xe0 0x3f 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "z1"
        ] = "{0x00 0x00 0x00 0x00 0x00 0x00 0xf8 0x3f 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "z2"
        ] = "{0x00 0x00 0x00 0x00 0x00 0x00 0x04 0x40 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "z3"
        ] = "{0x00 0x00 0x00 0x00 0x00 0x00 0x0c 0x40 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "z4"
        ] = "{0x00 0x00 0x90 0x40 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "z5"
        ] = "{0x00 0x00 0xb0 0x40 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "z6"
        ] = "{0x00 0x00 0xd0 0x40 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "z7"
        ] = "{0x00 0x00 0xf0 0x40 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "z8"
        ] = "{0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x11 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "z27"
        ] = "{0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "z28"
        ] = "{0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "z31"
        ] = "{0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x30 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values["p0"] = "{0x00 0x00 0x00 0x00}"
        values["p1"] = "{0x00 0x00 0x00 0x00}"
        values["p2"] = "{0x00 0x00 0x00 0x00}"
        values["p4"] = "{0x00 0x00 0x00 0x00}"
        values["p3"] = "{0x00 0x00 0x00 0x00}"
        values["p6"] = "{0x00 0x00 0x00 0x00}"
        values["p5"] = "{0x00 0x00 0x00 0x00}"
        values["p7"] = "{0x00 0x00 0x00 0x00}"
        values["p8"] = "{0x00 0x00 0x00 0x00}"
        values["p9"] = "{0x00 0x00 0x00 0x00}"
        values["p11"] = "{0x00 0x00 0x00 0x00}"
        values["p10"] = "{0x00 0x00 0x00 0x00}"
        values["p12"] = "{0x00 0x00 0x00 0x00}"
        values["p13"] = "{0x00 0x00 0x00 0x00}"
        values["p14"] = "{0x00 0x00 0x00 0x00}"
        values["p15"] = "{0x00 0x00 0x00 0x00}"
        values["ffr"] = "{0x00 0x00 0x00 0x00}"

        for regname, value in values.items():
            self.expect(
                "register read {}".format(regname),
                substrs=["{} = {}".format(regname, value)],
            )

        self.expect("register read --all")

    @skipIfLLVMTargetMissing("AArch64")
    def test_aarch64_sve_regs_full(self):
        # check 64 bit ARM core files
        target = self.dbg.CreateTarget(None)
        self.assertTrue(target, VALID_TARGET)
        process = target.LoadCore("linux-aarch64-sve-full.core")

        values = {}
        values["fp"] = "0x0000fffffc1ff4f0"
        values["lr"] = "0x0000000000400170"
        values["sp"] = "0x0000fffffc1ff4d0"
        values["pc"] = "0x000000000040013c"
        values[
            "v0"
        ] = "{0x00 0x00 0xf0 0x40 0x00 0x00 0xf0 0x40 0x00 0x00 0xf0 0x40 0x00 0x00 0xf0 0x40}"
        values[
            "v1"
        ] = "{0x00 0x00 0x38 0x41 0x00 0x00 0x38 0x41 0x00 0x00 0x38 0x41 0x00 0x00 0x38 0x41}"
        values[
            "v2"
        ] = "{0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "v3"
        ] = "{0x00 0x00 0x78 0x41 0x00 0x00 0x78 0x41 0x00 0x00 0x78 0x41 0x00 0x00 0x78 0x41}"
        values["s0"] = "7.5"
        values["s1"] = "11.5"
        values["s2"] = "0"
        values["s3"] = "15.5"
        values["d0"] = "65536.0158538818"
        values["d1"] = "1572864.25476074"
        values["d2"] = "0"
        values["d3"] = "25165828.091796875"
        values["vg"] = "0x0000000000000004"
        values[
            "z0"
        ] = "{0x00 0x00 0xf0 0x40 0x00 0x00 0xf0 0x40 0x00 0x00 0xf0 0x40 0x00 0x00 0xf0 0x40 0x00 0x00 0xf0 0x40 0x00 0x00 0xf0 0x40 0x00 0x00 0xf0 0x40 0x00 0x00 0xf0 0x40}"
        values[
            "z1"
        ] = "{0x00 0x00 0x38 0x41 0x00 0x00 0x38 0x41 0x00 0x00 0x38 0x41 0x00 0x00 0x38 0x41 0x00 0x00 0x38 0x41 0x00 0x00 0x38 0x41 0x00 0x00 0x38 0x41 0x00 0x00 0x38 0x41}"
        values[
            "z2"
        ] = "{0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00}"
        values[
            "z3"
        ] = "{0x00 0x00 0x78 0x41 0x00 0x00 0x78 0x41 0x00 0x00 0x78 0x41 0x00 0x00 0x78 0x41 0x00 0x00 0x78 0x41 0x00 0x00 0x78 0x41 0x00 0x00 0x78 0x41 0x00 0x00 0x78 0x41}"
        values["p0"] = "{0x11 0x11 0x11 0x11}"
        values["p1"] = "{0x11 0x11 0x11 0x11}"
        values["p2"] = "{0x00 0x00 0x00 0x00}"
        values["p3"] = "{0x11 0x11 0x11 0x11}"
        values["p4"] = "{0x00 0x00 0x00 0x00}"

        for regname, value in values.items():
            self.expect(
                "register read {}".format(regname),
                substrs=["{} = {}".format(regname, value)],
            )

        self.expect("register read --all")

        # Register field information should work with core files as it does a live process.
        # The N/Z/C/V bits are always present so just check for those.
        self.expect("register read cpsr", substrs=["= (N = 0, Z = 0, C = 0, V = 0"])
        self.expect("register read fpsr", substrs=["= (QC = 0, IDC = 0, IXC = 0"])
        # AHP/DN/FZ/RMode always present, others may vary.
        self.expect(
            "register read fpcr", substrs=["= (AHP = 0, DN = 0, FZ = 0, RMode = RN"]
        )
        # RMode should have enumerator descriptions.
        self.expect(
            "register info fpcr",
            substrs=["RMode: 0 = RN, 1 = RP, 2 = RM, 3 = RZ"],
        )

    @skipIfLLVMTargetMissing("AArch64")
    def test_aarch64_pac_regs(self):
        # Test AArch64/Linux Pointer Authentication register read
        target = self.dbg.CreateTarget(None)
        self.assertTrue(target, VALID_TARGET)
        process = target.LoadCore("linux-aarch64-pac.core")

        values = {"data_mask": "0x007f00000000000", "code_mask": "0x007f00000000000"}

        for regname, value in values.items():
            self.expect(
                "register read {}".format(regname),
                substrs=["{} = {}".format(regname, value)],
            )

        self.expect("register read --all")

    @skipIfLLVMTargetMissing("ARM")
    def test_arm_core(self):
        # check 32 bit ARM core file
        target = self.dbg.CreateTarget(None)
        self.assertTrue(target, VALID_TARGET)
        process = target.LoadCore("linux-arm.core")

        values = {}
        values["r0"] = "0x00000000"
        values["r1"] = "0x00000001"
        values["r2"] = "0x00000002"
        values["r3"] = "0x00000003"
        values["r4"] = "0x00000004"
        values["r5"] = "0x00000005"
        values["r6"] = "0x00000006"
        values["r7"] = "0x00000007"
        values["r8"] = "0x00000008"
        values["r9"] = "0x00000009"
        values["r10"] = "0x0000000a"
        values["r11"] = "0x0000000b"
        values["r12"] = "0x0000000c"
        values["sp"] = "0x0000000d"
        values["lr"] = "0x0000000e"
        values["pc"] = "0x0000000f"
        values["cpsr"] = "0x00000010"
        for regname, value in values.items():
            self.expect(
                "register read {}".format(regname),
                substrs=["{} = {}".format(regname, value)],
            )

        self.expect("register read --all")

    @skipIfLLVMTargetMissing("RISCV")
    def test_riscv64_regs_gpr_fpr(self):
        # check basic registers using 64 bit RISC-V core file
        target = self.dbg.CreateTarget(None)
        self.assertTrue(target, VALID_TARGET)
        process = target.LoadCore("linux-riscv64.gpr_fpr.core")

        values = {
            "pc": ("0x000000000001016e", None),
            "zero": ("0x0", "x0"),
            "ra": ("0x00000000000101a4", "x1"),
            "sp": ("0x0000003fffc1d2d0", "x2"),
            "gp": ("0x0000002ae6eccf50", "x3"),
            "tp": ("0x0000003ff3cb5400", "x4"),
            "t0": ("0x7f7f7f7fffffffff", "x5"),
            "t1": ("0x0000002ae6eb9b1c", "x6"),
            "t2": ("0xffffffffffffffff", "x7"),
            "fp": ("0x0000003fffc1d300", "x8"),
            "s1": ("0x0000002ae6eced98", "x9"),
            "a0": ("0x0000000000000000", "x10"),
            "a1": ("0x0000000000010144", "x11"),
            "a2": ("0x0000002ae6ecedb0", "x12"),
            "a3": ("0xafdbdbff81cf7f81", "x13"),
            "a4": ("0x00000000000101e4", "x14"),
            "a5": ("0x0000000000000000", "x15"),
            "a6": ("0x2f5b5a40014e0001", "x16"),
            "a7": ("0x00000000000000dd", "x17"),
            "s2": ("0x0000002ae6ec8860", "x18"),
            "s3": ("0x0000002ae6ecedb0", "x19"),
            "s4": ("0x0000003fff886c18", "x20"),
            "s5": ("0x0000002ae6eceb78", "x21"),
            "s6": ("0x0000002ae6ec8860", "x22"),
            "s7": ("0x0000002ae6ec8860", "x23"),
            "s8": ("0x0000000000000000", "x24"),
            "s9": ("0x000000000000000f", "x25"),
            "s10": ("0x0000002ae6ecc8d0", "x26"),
            "s11": ("0x0000000000000008", "x27"),
            "t3": ("0x0000003ff3be3728", "x28"),
            "t4": ("0x0000000000000000", "x29"),
            "t5": ("0x0000000000000002", "x30"),
            "t6": ("0x0000002ae6ed08b9", "x31"),
            "fa5": ("0xffffffff423c0000", None),
            "fcsr": ("0x00000000", None),
        }

        fpr_names = {
            "ft0",
            "ft1",
            "ft2",
            "ft3",
            "ft4",
            "ft5",
            "ft6",
            "ft7",
            "ft8",
            "ft9",
            "ft10",
            "ft11",
            "fa0",
            "fa1",
            "fa2",
            "fa3",
            "fa4",
            # fa5 is non-zero and checked in the list above.
            "fa6",
            "fa7",
            "fs0",
            "fs1",
            "fs2",
            "fs3",
            "fs4",
            "fs5",
            "fs6",
            "fs7",
            "fs8",
            "fs9",
            "fs10",
            "fs11",
        }
        fpr_value = "0x0000000000000000"

        for regname in values:
            value, alias = values[regname]
            self.expect(
                "register read {}".format(regname),
                substrs=["{} = {}".format(regname, value)],
            )
            if alias:
                self.expect(
                    "register read {}".format(alias),
                    substrs=["{} = {}".format(regname, value)],
                )

        for regname in fpr_names:
            self.expect(
                "register read {}".format(regname),
                substrs=["{} = {}".format(regname, fpr_value)],
            )

        self.expect("register read --all")

    @skipIfLLVMTargetMissing("RISCV")
    def test_riscv64_regs_gpr_only(self):
        # check registers using 64 bit RISC-V core file containing GP-registers only
        target = self.dbg.CreateTarget(None)
        self.assertTrue(target, VALID_TARGET)
        process = target.LoadCore("linux-riscv64.gpr_only.core")

        values = {
            "pc": ("0x0000000000010164", None),
            "zero": ("0x0", "x0"),
            "ra": ("0x0000000000010194", "x1"),
            "sp": ("0x00fffffff4d5fcc0", "x2"),
            "gp": ("0x0000000000157678", "x3"),
            "tp": ("0x00ffffff99c43400", "x4"),
            "t0": ("0x00ffffff99c6b260", "x5"),
            "t1": ("0x00ffffff99b7bd54", "x6"),
            "t2": ("0x0000000003f0b27f", "x7"),
            "fp": ("0x00fffffff4d5fcf0", "x8"),
            "s1": ("0x0000000000000003", "x9"),
            "a0": ("0x0", "x10"),
            "a1": ("0x0000000000010144", "x11"),
            "a2": ("0x0000000000176460", "x12"),
            "a3": ("0x000000000015ee38", "x13"),
            "a4": ("0x00000000423c0000", "x14"),
            "a5": ("0x0", "x15"),
            "a6": ("0x0", "x16"),
            "a7": ("0x00000000000000dd", "x17"),
            "s2": ("0x0", "x18"),
            "s3": ("0x000000000014ddf8", "x19"),
            "s4": ("0x000000000003651c", "x20"),
            "s5": ("0x00fffffffccd8d28", "x21"),
            "s6": ("0x000000000014ddf8", "x22"),
            "s7": ("0x00ffffff99c69d48", "x23"),
            "s8": ("0x00ffffff99c6a008", "x24"),
            "s9": ("0x0", "x25"),
            "s10": ("0x0", "x26"),
            "s11": ("0x0", "x27"),
            "t3": ("0x00ffffff99c42000", "x28"),
            "t4": ("0x00ffffff99af8e20", "x29"),
            "t5": ("0x0000000000000005", "x30"),
            "t6": ("0x44760bdd8d5f6381", "x31"),
        }

        for regname in values:
            value, alias = values[regname]
            self.expect(
                "register read {}".format(regname),
                substrs=["{} = {}".format(regname, value)],
            )
            if alias:
                self.expect(
                    "register read {}".format(alias),
                    substrs=["{} = {}".format(regname, value)],
                )

        # Check that LLDB does not try to read other registers from core file
        self.expect(
            "register read --all",
            matching=False,
            substrs=["registers were unavailable"],
        )

    @skipIfLLVMTargetMissing("LoongArch")
    def test_loongarch64_regs(self):
        # check registers using 64 bit LoongArch core file containing GP and FP registers
        target = self.dbg.CreateTarget(None)
        self.assertTrue(target, VALID_TARGET)
        process = target.LoadCore("linux-loongarch64.core")

        values = {
            "r0": ("0x0000000000000000", "zero"),
            "r1": ("0x000000012000016c", "ra"),
            "r2": ("0x0000000000000000", "tp"),
            "r3": ("0x00007ffffb8249e0", "sp"),
            "r4": ("0x0000000000000000", "a0"),
            "r5": ("0x000000012000010c", "a1"),
            "r6": ("0x0000000000000000", "a2"),
            "r7": ("0x0000000000000000", "a3"),
            "r8": ("0x0000000000000000", "a4"),
            "r9": ("0x0000000000000000", "a5"),
            "r10": ("0x0000000000000000", "a6"),
            "r11": ("0x00000000000000dd", "a7"),
            "r12": ("0x0000000000000000", "t0"),
            "r13": ("0x000000000000002f", "t1"),
            "r14": ("0x0000000000000000", "t2"),
            "r15": ("0x0000000000000000", "t3"),
            "r16": ("0x0000000000000000", "t4"),
            "r17": ("0x0000000000000000", "t5"),
            "r18": ("0x0000000000000000", "t6"),
            "r19": ("0x0000000000000000", "t7"),
            "r20": ("0x0000000000000000", "t8"),
            "r21": ("0x0000000000000000", None),
            "r22": ("0x00007ffffb824a10", "fp"),
            "r23": ("0x0000000000000000", "s0"),
            "r24": ("0x0000000000000000", "s1"),
            "r25": ("0x0000000000000000", "s2"),
            "r26": ("0x0000000000000000", "s3"),
            "r27": ("0x0000000000000000", "s4"),
            "r28": ("0x0000000000000000", "s5"),
            "r29": ("0x0000000000000000", "s6"),
            "r30": ("0x0000000000000000", "s7"),
            "r31": ("0x0000000000000000", "s8"),
            "orig_a0": ("0x0000555556b62d50", None),
            "pc": ("0x000000012000012c", None),
        }

        fpr_values = {}
        fpr_values["f0"] = "0x00000000ffffff05"
        fpr_values["f1"] = "0x2525252525252525"
        fpr_values["f2"] = "0x2525252525560005"
        fpr_values["f3"] = "0x000000000000ffff"
        fpr_values["f4"] = "0x0000000000000000"
        fpr_values["f5"] = "0x0000000000000008"
        fpr_values["f6"] = "0x0f0e0d0c0b0a0908"
        fpr_values["f7"] = "0xffffffffffffffff"
        fpr_values["f8"] = "0x6261747563657845"
        fpr_values["f9"] = "0x766173206562206c"
        fpr_values["f10"] = "0xffffffffffffffff"
        fpr_values["f11"] = "0xffffffffffffffff"
        fpr_values["f12"] = "0xffffffffffffffff"
        fpr_values["f13"] = "0xffffffffffffffff"
        fpr_values["f14"] = "0xffffffffffffffff"
        fpr_values["f15"] = "0xffffffffffffffff"
        fpr_values["f16"] = "0xffffffffffffffff"
        fpr_values["f17"] = "0xffffffffffffffff"
        fpr_values["f18"] = "0xffffffffffffffff"
        fpr_values["f19"] = "0xffffffffffffffff"
        fpr_values["f20"] = "0xffffffffffffffff"
        fpr_values["f21"] = "0xffffffffffffffff"
        fpr_values["f22"] = "0xffffffffffffffff"
        fpr_values["f23"] = "0xffffffffffffffff"
        fpr_values["f24"] = "0xffffffffffffffff"
        fpr_values["f25"] = "0xffffffffffffffff"
        fpr_values["f26"] = "0xffffffffffffffff"
        fpr_values["f27"] = "0xffffffffffffffff"
        fpr_values["f28"] = "0xffffffffffffffff"
        fpr_values["f29"] = "0xffffffffffffffff"
        fpr_values["f30"] = "0xffffffffffffffff"
        fpr_values["f31"] = "0xffffffffffffffff"
        fpr_values["fcc0"] = "0x01"
        fpr_values["fcc1"] = "0x00"
        fpr_values["fcc2"] = "0x01"
        fpr_values["fcc3"] = "0x01"
        fpr_values["fcc4"] = "0x01"
        fpr_values["fcc5"] = "0x01"
        fpr_values["fcc6"] = "0x00"
        fpr_values["fcc7"] = "0x01"
        fpr_values["fcsr"] = "0x00000000"

        for regname in values:
            value, alias = values[regname]
            self.expect(
                "register read {}".format(regname),
                substrs=["{} = {}".format(regname, value)],
            )
            if alias:
                self.expect(
                    "register read {}".format(alias),
                    substrs=["{} = {}".format(regname, value)],
                )

        for regname, value in fpr_values.items():
            self.expect(
                "register read {}".format(regname),
                substrs=["{} = {}".format(regname, value)],
            )

        self.expect("register read --all")

    def test_get_core_file_api(self):
        """
        Test SBProcess::GetCoreFile() API can successfully get the core file.
        """
        core_file_name = "linux-x86_64.core"
        target = self.dbg.CreateTarget("linux-x86_64.out")
        process = target.LoadCore(core_file_name)
        self.assertTrue(process, PROCESS_IS_VALID)
        self.assertEqual(process.GetCoreFile().GetFilename(), core_file_name)
        self.dbg.DeleteTarget(target)

    @skipIfLLVMTargetMissing("X86")
    def test_read_only_cstring(self):
        """
        Test that we can show the summary for a cstring variable that points
        to a read-only memory page which is not dumped to a core file.
        """
        target = self.dbg.CreateTarget("altmain2.out")
        process = target.LoadCore("altmain2.core")
        self.assertTrue(process, PROCESS_IS_VALID)

        frame = process.GetSelectedThread().GetFrameAtIndex(0)
        self.assertEqual(frame.GetFunctionName(), "_start")

        var = frame.FindVariable("F")

        # The variable points to a read-only segment that is not dumped to
        # the core file and thus 'process.ReadCStringFromMemory()' cannot get
        # the value.
        error = lldb.SBError()
        cstr = process.ReadCStringFromMemory(var.GetValueAsUnsigned(), 256, error)
        self.assertFailure(error, error_str="core file does not contain 0x804a000")
        self.assertEqual(cstr, "")

        # Nevertheless, when getting the summary, the value can be read from the
        # application binary.
        cstr = var.GetSummary()
        self.assertEqual(cstr, '"_start"')

    def check_memory_regions(self, process, region_count):
        region_list = process.GetMemoryRegions()
        self.assertEqual(region_list.GetSize(), region_count)

        region = lldb.SBMemoryRegionInfo()

        # Check we have the right number of regions.
        self.assertEqual(region_list.GetSize(), region_count)

        # Check that getting a region beyond the last in the list fails.
        self.assertFalse(region_list.GetMemoryRegionAtIndex(region_count, region))

        # Check each region is valid.
        for i in range(region_list.GetSize()):
            # Check we can actually get this region.
            self.assertTrue(region_list.GetMemoryRegionAtIndex(i, region))

            # Every region in the list should be mapped.
            self.assertTrue(region.IsMapped())

            # Test the address at the start of a region returns it's enclosing
            # region.
            begin_address = region.GetRegionBase()
            region_at_begin = lldb.SBMemoryRegionInfo()
            error = process.GetMemoryRegionInfo(begin_address, region_at_begin)
            self.assertEqual(region, region_at_begin)

            # Test an address in the middle of a region returns it's enclosing
            # region.
            middle_address = (region.GetRegionBase() + region.GetRegionEnd()) // 2
            region_at_middle = lldb.SBMemoryRegionInfo()
            error = process.GetMemoryRegionInfo(middle_address, region_at_middle)
            self.assertEqual(region, region_at_middle)

            # Test the address at the end of a region returns it's enclosing
            # region.
            end_address = region.GetRegionEnd() - 1
            region_at_end = lldb.SBMemoryRegionInfo()
            error = process.GetMemoryRegionInfo(end_address, region_at_end)
            self.assertEqual(region, region_at_end)

            # Check that quering the end address does not return this region but
            # the next one.
            next_region = lldb.SBMemoryRegionInfo()
            error = process.GetMemoryRegionInfo(region.GetRegionEnd(), next_region)
            self.assertNotEqual(region, next_region)
            self.assertEqual(region.GetRegionEnd(), next_region.GetRegionBase())

        # Check that query beyond the last region returns an unmapped region
        # that ends at LLDB_INVALID_ADDRESS
        last_region = lldb.SBMemoryRegionInfo()
        region_list.GetMemoryRegionAtIndex(region_count - 1, last_region)
        end_region = lldb.SBMemoryRegionInfo()
        error = process.GetMemoryRegionInfo(last_region.GetRegionEnd(), end_region)
        self.assertFalse(end_region.IsMapped())
        self.assertEqual(last_region.GetRegionEnd(), end_region.GetRegionBase())
        self.assertEqual(end_region.GetRegionEnd(), lldb.LLDB_INVALID_ADDRESS)

    def check_state(self, process):
        with open(os.devnull) as devnul:
            # sanitize test output
            self.dbg.SetOutputFileHandle(devnul, False)
            self.dbg.SetErrorFileHandle(devnul, False)

            self.assertTrue(process.is_stopped)

            # Process.Continue
            error = process.Continue()
            self.assertFalse(error.Success())
            self.assertTrue(process.is_stopped)

            # Thread.StepOut
            thread = process.GetSelectedThread()
            thread.StepOut()
            self.assertTrue(process.is_stopped)

            # command line
            self.dbg.HandleCommand("s")
            self.assertTrue(process.is_stopped)
            self.dbg.HandleCommand("c")
            self.assertTrue(process.is_stopped)

            # restore file handles
            self.dbg.SetOutputFileHandle(None, False)
            self.dbg.SetErrorFileHandle(None, False)

    def check_stack(self, process, pid, thread_name):
        thread = process.GetSelectedThread()
        self.assertTrue(thread)
        self.assertEqual(thread.GetThreadID(), pid)
        self.assertEqual(thread.GetName(), thread_name)
        backtrace = ["bar", "foo", "_start"]
        self.assertEqual(thread.GetNumFrames(), len(backtrace))
        for i in range(len(backtrace)):
            frame = thread.GetFrameAtIndex(i)
            self.assertTrue(frame)
            self.assertEqual(frame.GetFunctionName(), backtrace[i])
            self.assertEqual(
                frame.GetLineEntry().GetLine(),
                line_number("main.c", "Frame " + backtrace[i]),
            )
            self.assertEqual(
                frame.FindVariable("F").GetValueAsUnsigned(), ord(backtrace[i][0])
            )

    def check_all(self, process, pid, region_count, thread_name):
        self.assertTrue(process, PROCESS_IS_VALID)
        self.assertEqual(process.GetNumThreads(), 1)
        self.assertEqual(process.GetProcessID(), pid)

        self.check_state(process)

        self.check_stack(process, pid, thread_name)

        self.check_memory_regions(process, region_count)

    def do_test(self, filename, pid, region_count, thread_name):
        target = self.dbg.CreateTarget(filename + ".out")
        process = target.LoadCore(filename + ".core")

        self.check_all(process, pid, region_count, thread_name)

        self.dbg.DeleteTarget(target)


def replace_path(binary, replace_from, replace_to):
    src = replace_from.encode()
    dst = replace_to.encode()
    dst += b"\0" * (len(src) - len(dst))
    return binary.replace(src, dst)
