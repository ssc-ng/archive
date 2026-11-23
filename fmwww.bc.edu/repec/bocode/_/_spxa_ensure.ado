*! _spxa_ensure 1.0.0  21nov2026
*! internal: check the Stata/Python environment and load the spxa adapter
*! author: Nityahapani
*!
*! Returns
*!   r(ok) 1 if the adapter is loaded and usable, 0 otherwise
*!   r(rc) the Stata return code to use when r(ok) is 0
*!
*! This program never issues -error- itself: the caller inspects r(ok) and
*! r(rc) and exits with that code.  Keeping the decision in the caller means
*! the exit status is right no matter how the caller was invoked.
*!
*! Nothing here can produce a Python traceback in the results window: the one
*! block that runs Python code which is not already protected by
*! spxa_stata._run() catches its own exceptions and reports them through a
*! global macro for this program to display.

program define _spxa_ensure, rclass
    version 16.0

    return scalar ok = 0
    return scalar rc = 499

    * ---- 0. Stata must be new enough to have the Python integration ----
    if (c(stata_version) < 16) {
        di as err "{p}spxa requires Stata 16 or newer; this is Stata " ///
            c(stata_version) ".{p_end}"
        di as err "{p}See {help python} for the Python integration.{p_end}"
        return scalar rc = 499
        exit
    }

    * ---- 1. is the Stata/Python integration usable? ----
    capture python: import sys
    if (_rc) {
        di as err "{p}spxa requires the Stata/Python integration, and no " ///
            "Python interpreter is currently linked to Stata.{p_end}"
        di as err "{p}Use {stata python query} to see the current " ///
            "configuration and {stata python set exec} to select an " ///
            "interpreter.{p_end}"
        di as err "{p}See {help python} and {help python set} for details.{p_end}"
        return scalar rc = 499
        exit
    }

    * ---- 2. is the adapter already loaded in this session? ----
    * Keeping the module in sys.modules is what makes the handle registry
    * survive from one spxa command to the next, so it is loaded at most once.
    capture python: import spxa_stata
    if (!_rc) {
        return scalar ok = 1
        return scalar rc = 0
        exit
    }

    * ---- 3. locate spxa_py.py ----
    capture findfile spxa_py.py
    if (!_rc) {
        local pyfile `"`r(fn)'"'
    }
    else {
        capture findfile spxa.ado
        if (_rc) {
            di as err "{p}spxa_py.py could not be found on the adopath.{p_end}"
            di as err "{p}Reinstall the package with " ///
                "{stata ssc install spxa, replace}.{p_end}"
            return scalar rc = 601
            exit
        }
        local adofile `"`r(fn)'"'
        local dir : subinstr local adofile "spxa.ado" "", all
        local pyfile `"`dir'spxa_py.py"'
        capture confirm file `"`pyfile'"'
        if (_rc) {
            di as err "{p}spxa_py.py was not found next to `adofile'.{p_end}"
            di as err "{p}Reinstall the package with " ///
                "{stata ssc install spxa, replace}.{p_end}"
            return scalar rc = 601
            exit
        }
    }

    * ---- 4. load it as the module spxa_stata ----
    capture global __SPXA_LOADERR
    python:
import sys as _spxa_sys

_spxa_sys.modules.pop("spxa_stata", None)
try:
    import importlib.util as _spxa_util
    _spxa_spec = _spxa_util.spec_from_file_location("spxa_stata", r"`pyfile'")
    if _spxa_spec is None or _spxa_spec.loader is None:
        raise ImportError("not a loadable Python file")
    _spxa_mod = _spxa_util.module_from_spec(_spxa_spec)
    _spxa_sys.modules["spxa_stata"] = _spxa_mod
    try:
        _spxa_spec.loader.exec_module(_spxa_mod)
    except Exception:
        _spxa_sys.modules.pop("spxa_stata", None)
        raise
except Exception as _spxa_exc:
    try:
        from sfi import Macro as _spxa_Macro
        _spxa_Macro.setGlobal("__SPXA_LOADERR",
                              "%s: %s" % (type(_spxa_exc).__name__, _spxa_exc))
    except Exception:
        pass
end

    capture python: import spxa_stata
    if (_rc) {
        di as err "{p}spxa_py.py was found at {bf:`pyfile'} but could not be " ///
            "loaded into Stata's Python interpreter.{p_end}"
        di as err `"{p}Python reported: `__SPXA_LOADERR'{p_end}"'
        di as err "{p}If the error mentions a missing module, install the " ///
            "library with {stata python: import subprocess, sys; " ///
            "subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'spxa'])}{p_end}"
        capture global __SPXA_LOADERR
        return scalar rc = 601
        exit
    }
    capture global __SPXA_LOADERR

    * ---- 5. is the spxa library itself importable? ----
    python: import spxa_stata; spxa_stata.spxa_probe()

    local pyrc = 0
    capture local pyrc = scalar(__spxa_rc)
    capture scalar drop __spxa_rc
    if (`pyrc' != 0) {
        return scalar rc = `pyrc'
        exit
    }

    return scalar ok = 1
    return scalar rc = 0
end
