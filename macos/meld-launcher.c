#include <Python.h>
#include <limits.h>
#include <mach-o/dyld.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int
bundle_paths (char *resources, size_t resources_size)
{
    char executable[PATH_MAX];
    uint32_t executable_size = sizeof (executable);
    char *separator;

    if (_NSGetExecutablePath (executable, &executable_size) != 0)
        return -1;

    separator = strrchr (executable, '/');
    if (separator == NULL)
        return -1;
    *separator = '\0';

    if (snprintf (resources, resources_size, "%s/../Resources", executable) >=
        (int)resources_size)
        return -1;

    return 0;
}

int
main (int argc, char **argv)
{
    char resources[PATH_MAX];
    char python_path[PATH_MAX];
    char schema_path[PATH_MAX];
    char xdg_data_dirs[PATH_MAX * 2];
    char script[PATH_MAX];
    char **python_argv;
    int i;
    int result;

    if (bundle_paths (resources, sizeof (resources)) != 0) {
        fputs ("Unable to locate Meld.app resources\n", stderr);
        return 1;
    }

    snprintf (python_path, sizeof (python_path),
              "%s/lib/python3.13/site-packages", resources);
    snprintf (schema_path, sizeof (schema_path),
              "%s/share/glib-2.0/schemas", resources);
    snprintf (xdg_data_dirs, sizeof (xdg_data_dirs),
              "%s/share:/opt/homebrew/share:/usr/local/share:/usr/share",
              resources);
    snprintf (script, sizeof (script), "%s/bin/meld", resources);

    setenv ("PYTHONPATH", python_path, 1);
    setenv ("PYTHONDONTWRITEBYTECODE", "1", 1);
    setenv ("GSETTINGS_SCHEMA_DIR", schema_path, 1);
    setenv ("XDG_DATA_DIRS", xdg_data_dirs, 1);

    /* multiprocessing re-executes sys.executable with Python flags such as
     * "-B -c … --multiprocessing-fork". Let Python handle those invocations
     * directly; treating them as Meld arguments produces "no such option:
     * -B" and breaks the helper process. */
    for (i = 1; i < argc; i++) {
        if (strcmp (argv[i], "--multiprocessing-fork") == 0)
            return Py_BytesMain (argc, argv);
    }

    python_argv = calloc ((size_t)argc + 2, sizeof (*python_argv));
    if (python_argv == NULL) {
        perror ("calloc");
        return 1;
    }

    python_argv[0] = argv[0];
    python_argv[1] = script;
    for (i = 1; i < argc; i++)
        python_argv[i + 1] = argv[i];

    result = Py_BytesMain (argc + 1, python_argv);
    free (python_argv);
    return result;
}
