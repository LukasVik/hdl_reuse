from os.path import dirname, join
import pytest
import unittest

from hdl_reuse.module import get_modules
from hdl_reuse.test import create_file, create_directory, delete
from hdl_reuse.vivado_project import VivadoProject


THIS_DIR = dirname(__file__)

# pylint: disable=protected-access


class TestBasicProject(unittest.TestCase):

    part = "xczu3eg-sfva625-1-i"
    project_folder = join(THIS_DIR, "vivado")
    modules_folder = join(THIS_DIR, "modules")

    def setUp(self):
        # A library with some synth files and some test files
        self.file_a = create_file(join(self.modules_folder, "apa", "a.vhd"))
        self.file_b = create_file(join(self.modules_folder, "apa", "b.vhd"))
        self.file_c = create_file(join(self.modules_folder, "apa", "test", "c.vhd"))

        # A library with only test files
        self.file_d = create_file(join(self.modules_folder, "zebra", "test", "d.vhd"))

        self.modules = get_modules([self.modules_folder])
        self.proj = VivadoProject(name="name", modules=self.modules, part=self.part)

    def tearDown(self):
        delete(self.modules_folder)
        delete(self.project_folder)

    def test_only_synthesis_files_added_to_create_project_tcl(self):
        tcl = self.proj._create_tcl(self.project_folder)
        assert self.file_a in tcl and self.file_b in tcl
        assert self.file_c not in tcl and "c.vhd" not in tcl

    def test_empty_library_not_in_create_project_tcl(self):
        tcl = self.proj._create_tcl(self.project_folder)
        assert "zebra" not in tcl

    def test_create_should_raise_exeception_if_project_path_already_exists(self):
        create_directory(self.project_folder)
        with pytest.raises(ValueError):
            self.proj.create(self.project_folder)

    def test_build_should_raise_exeception_if_project_does_not_exists(self):
        with pytest.raises(ValueError):
            self.proj.build(self.project_folder)

    def test_build_with_impl_run_should_raise_exeception_if_no_output_path_is_given(self):
        with pytest.raises(ValueError):
            self.proj.build(self.project_folder)
