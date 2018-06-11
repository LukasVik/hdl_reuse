from os import makedirs
from os.path import join, exists

from hdl_reuse import HDL_REUSE_TCL
from hdl_reuse.constraints import Constraint
from hdl_reuse.vivado_tcl import VivadoTcl
from hdl_reuse.vivado_utils import run_vivado_tcl


class VivadoProject:  # pylint: disable=too-many-instance-attributes
    """
    Used for handling a Xilinx Vivado HDL project
    """

    def __init__(  # pylint: disable=too-many-arguments
            self,
            name,
            modules,
            part,
            top=None,  # Name of top level entity
            block_design=None,  # TCL file that creates the block design
            generics=None,  # A dict with generics values
            vivado_path=None,  # Default: Whatever version/location is in PATH will be used
            constraints=None,  # A list of TCL files
            defined_at=None,  # To get a useful --list message
    ):
        self.name = name
        self.modules = modules

        self.top = name + "_top" if top is None else top
        self.vivado_path = "vivado" if vivado_path is None else vivado_path

        constraints_list = self._setup_constraints_list(constraints)

        self.defined_at = defined_at

        self.tcl = VivadoTcl(
            name=self.name,
            modules=self.modules,
            part=part,
            top=self.top,
            block_design=block_design,
            generics=generics,
            constraints=constraints_list
        )

    def _setup_constraints_list(self, constraints_from_user):
        # Lists are imutable. Since we assign and modify this one we have to copy it.
        constraints = [] if constraints_from_user is None else constraints_from_user.copy()

        file = join(HDL_REUSE_TCL, "constrain_clock_crossings.tcl")
        constraints.append(Constraint(file))

        for module in self.modules:
            for constraint in module.get_entity_constraints():
                constraints.append(constraint)

        return constraints

    def create_tcl(self, project_path):
        """
        Make a TCL file that creates a Vivado project
        """
        if exists(project_path):
            raise ValueError("Folder already exists: " + project_path)
        makedirs(project_path)

        create_vivado_project_tcl = join(project_path, "create_vivado_project.tcl")
        with open(create_vivado_project_tcl, "w") as file_handle:
            file_handle.write(self.tcl.create(project_path))

        return create_vivado_project_tcl

    def create(self, project_path):
        """
        Create a Vivado project
        """
        create_vivado_project_tcl = self.create_tcl(project_path)
        run_vivado_tcl(self.vivado_path, create_vivado_project_tcl)

    def build_tcl(self, project_path, synth_only, num_threads, output_path):
        """
        Make a TCL file that builds a Vivado project
        """
        project_file = join(project_path, self.name + ".xpr")
        if not exists(project_file):
            raise ValueError("Project file does not exist in the specified location: " + project_file)

        build_vivado_project_tcl = join(project_path, "build_vivado_project.tcl")
        with open(build_vivado_project_tcl, "w") as file_handle:
            file_handle.write(self.tcl.build(project_file, synth_only, num_threads, output_path))

        return build_vivado_project_tcl

    def build(self, project_path, output_path=None, synth_only=False, num_threads=12):
        """
        Build a Vivado project
        """
        if output_path is None and not synth_only:
            raise ValueError("Must specify output_path when doing an implementation run")

        build_vivado_project_tcl = self.build_tcl(project_path, synth_only, num_threads, output_path)
        run_vivado_tcl(self.vivado_path, build_vivado_project_tcl)

    def __str__(self):
        result = str(self.__class__.__name__)
        if self.defined_at is not None:
            result += " defined at: %s" % self.defined_at
        result += "\nName: %s" % self.name
        result += "\nTop level: %s" % self.top

        return result
