from conan.tools._check_build_profile import check_using_build_profile
from conan.tools.env import Environment
from conan.tools.gnu.gnudeps_flags import GnuDepsFlags
from conans.model.new_build_info import NewCppInfo


class AutotoolsDeps:
    def __init__(self, conanfile):
        self._conanfile = conanfile
        self._environment = None
        self._ordered_deps = []
        check_using_build_profile(self._conanfile)

    @property
    def ordered_deps(self):
        if not self._ordered_deps:
            deps = self._conanfile.dependencies.host.topological_sort
            self._ordered_deps = [dep for dep in reversed(deps.values())]
        return self._ordered_deps

    def _get_cpp_info(self):
        ret = NewCppInfo()
        for dep in self.ordered_deps:
            dep_cppinfo = dep.cpp_info.aggregated_components()
            # In case we have components, aggregate them, we do not support isolated
            # "targets" with autotools
            ret.merge(dep_cppinfo)
        return ret

    def _rpaths_flags(self):
        flags = []
        for dep in self.ordered_deps:
            flags.extend(["-Wl,-rpath -Wl,{}".format(libdir) for libdir in dep.cpp_info.libdirs
                          if dep.options.get_safe("shared", False)])
        return flags

    @property
    def environment(self):
        # TODO: Seems we want to make this uniform, equal to other generators
        if self._environment is None:
            flags = GnuDepsFlags(self._conanfile, self._get_cpp_info())

            # cpp_flags
            cpp_flags = []
            cpp_flags.extend(flags.include_paths)
            cpp_flags.extend(flags.defines)

            # Ldflags
            ldflags = flags.sharedlinkflags
            ldflags.extend(flags.exelinkflags)
            ldflags.extend(flags.frameworks)
            ldflags.extend(flags.framework_paths)
            ldflags.extend(flags.lib_paths)

            ## set the rpath in Macos so that the library are found in the configure step
            if self._conanfile.settings.get_safe("os") == "Macos":
                ldflags.extend(self._rpaths_flags())

            # libs
            libs = flags.libs
            libs.extend(flags.system_libs)

            # cflags
            cflags = flags.cflags
            cxxflags = flags.cxxflags

            srf = flags.sysroot
            if srf:
                cflags.append(srf)
                cxxflags.append(srf)
                ldflags.append(srf)

            env = Environment()
            env.append("CPPFLAGS", cpp_flags)
            env.append("LIBS", libs)
            env.append("LDFLAGS", ldflags)
            env.append("CXXFLAGS", cxxflags)
            env.append("CFLAGS", cflags)
            self._environment = env
        return self._environment

    def vars(self, scope="build"):
        return self.environment.vars(self._conanfile, scope=scope)

    def generate(self,  scope="build"):
        self.vars(scope).save_script("conanautotoolsdeps")