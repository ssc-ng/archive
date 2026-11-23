"""
spxa_py.py -- Stata adapter for the spxa Python library (Lévy process algebra).

This module is loaded into Stata's embedded Python interpreter by the spxa
package (see spxa.ado).  It is imported as the module ``spxa_stata`` so that
the handle registry survives between Stata commands; the file itself lives on
Stata's adopath next to spxa.ado and is located with -findfile-.

It is a thin bridge.  All mathematics is done by spxa; this file only
  * parses do-file syntax into Python objects,
  * moves data between spxa and Stata with the Stata Function Interface (sfi),
  * formats tables with SMCL, and
  * reports errors back to Stata through the scalar __spxa_rc.

Errors are never raised into Stata (no Python traceback is ever shown to the
user).  Every entry point catches its exceptions, prints one clean message with
SFIToolkit.errprint(), and stores a Stata return code in __spxa_rc for the
calling ado-file to pick up.
"""

from __future__ import annotations

import ast
import math
import operator
import sys
from typing import Any, Dict, List, Optional

from sfi import Data, Macro, Matrix, Scalar, SFIToolkit

ADAPTER_VERSION = "1.0.0"

# Stata return codes used by this package
RC_OK = 0
RC_SYNTAX = 198        # invalid syntax / invalid argument
RC_NOTFOUND = 111      # object not found in the registry
RC_GENERAL = 499       # environment or user error
RC_FILE = 601          # file not found

# ---------------------------------------------------------------------------
# spxa library import (never fatal at import time -- reported per command)
# ---------------------------------------------------------------------------

_SPXA_IMPORT_ERROR = ""
try:  # pragma: no cover - exercised via tests with spxa installed
    import numpy as _np
    import spxa as _spxa
    SPXA_VERSION = str(getattr(_spxa, "__version__", "unknown"))
except Exception as _exc:  # pragma: no cover
    _np = None
    _spxa = None
    SPXA_VERSION = ""
    _SPXA_IMPORT_ERROR = "%s: %s" % (type(_exc).__name__, _exc)


# ---------------------------------------------------------------------------
# Errors and status reporting
# ---------------------------------------------------------------------------


class SpxaError(Exception):
    """An error with a Stata return code attached."""

    def __init__(self, msg: str, rc: int = RC_GENERAL) -> None:
        super().__init__(msg)
        self.rc = int(rc)


def _g(name: str) -> str:
    """Read a global macro set by the calling ado-file (verbatim, no quoting)."""
    try:
        val = Macro.getGlobal(name)
    except Exception:  # pragma: no cover
        return ""
    return "" if val is None else str(val)


def _set_rc(rc: int) -> None:
    try:
        Scalar.setValue("__spxa_rc", int(rc))
    except Exception:  # pragma: no cover - sfi unavailable outside Stata
        pass


_RSET_ERRORS: List[str] = []


def _rset(name: str, value) -> None:
    """Store an r() scalar, as missing when value is None.

    sfi's Scalar.setValue() takes a float, so a missing result must be passed
    as NaN; the string "." would raise a TypeError.
    """
    if value is None:
        value = float("nan")
    try:
        Scalar.setValue(name, float(value))
    except Exception as exc:  # pragma: no cover - sfi unavailable outside Stata
        # Never let a cosmetic problem abort a command that already succeeded,
        # but do not fail silently either: the test suite inspects this list.
        _RSET_ERRORS.append("%s: %s: %s" % (name, type(exc).__name__, exc))


def _emit(msg: str, rc: int) -> None:
    """Print msg as an error in the Stata results window and set __spxa_rc."""
    for line in str(msg).splitlines() or [""]:
        try:
            SFIToolkit.errprint(line)
        except Exception:  # pragma: no cover
            pass
    _set_rc(rc)


def _run(fn, *args) -> None:
    """Call fn, converting every failure into a Stata error message + code."""
    try:
        fn(*args)
    except SpxaError as exc:
        _emit(exc.args[0], exc.rc)
    except KeyboardInterrupt:  # pragma: no cover
        _emit("interrupted", 1)
    except Exception as exc:  # pragma: no cover - defensive catch-all
        _emit("unexpected error: %s: %s" % (type(exc).__name__, exc), RC_GENERAL)
    else:
        _set_rc(RC_OK)


def _require_spxa() -> None:
    if _spxa is None:
        raise SpxaError(
            "the Python library spxa is not installed in the interpreter Stata "
            "uses (%s).\nInstall it with:  python: import subprocess, sys; "
            "subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'spxa'])"
            % _SPXA_IMPORT_ERROR,
            RC_GENERAL,
        )


# ---------------------------------------------------------------------------
# Process registry and name resolution
# ---------------------------------------------------------------------------

_REGISTRY: Dict[str, Any] = {}

# Convenience aliases -> attribute names on the spxa module.  Anything not
# listed here is still reachable by its class name (case-insensitively), so
# new processes added to spxa need no change in this file or in the ado-file.
_ALIASES: Dict[str, str] = {
    "bm": "BrownianMotion",
    "brownian": "BrownianMotion",
    "brownianmotion": "BrownianMotion",
    "drift": "Drift",
    "gamma": "GammaProcess",
    "gammaprocess": "GammaProcess",
    "ig": "InverseGaussianProcess",
    "inversegaussian": "InverseGaussianProcess",
    "vg": "VarianceGamma",
    "variancegamma": "VarianceGamma",
    "nig": "NIG",
    "cgmy": "CGMY",
    "meixner": "MeixnerProcess",
    "meixnerprocess": "MeixnerProcess",
    "stable": "AlphaStable",
    "alphastable": "AlphaStable",
    "ts": "TemperedStable",
    "temperedstable": "TemperedStable",
    "nts": "NormalTemperedStableProcess",
    "poisson": "PoissonProcess",
    "poissonprocess": "PoissonProcess",
    "cp": "CompoundPoisson",
    "compoundpoisson": "CompoundPoisson",
    "mjd": "MertonJumpDiffusion",
    "merton": "MertonJumpDiffusion",
    "kou": "KouJumpDiffusion",
    "kjd": "KouJumpDiffusion",
    "negbin": "NegativeBinomialProcess",
    "gh": "GH",
    "heston": "HestonProcess",
    "cir": "CIRProcess",
    "ou": "OrnsteinUhlenbeck",
    "sabr": "SABRProcess",
}


def _process_class(token: str):
    """Resolve a token to an spxa Process subclass."""
    _require_spxa()
    name = (token or "").strip()
    if not name:
        raise SpxaError("no process name was given", RC_SYNTAX)

    if name in _ALIASES:
        return _lookup_attr(_ALIASES[name], token)

    # exact attribute, then case-insensitive attribute
    if hasattr(_spxa, name):
        return _lookup_attr(name, token)
    lowered = name.lower()
    for attr in dir(_spxa):
        if attr.lower() == lowered:
            return _lookup_attr(attr, token)
    raise SpxaError(
        "unknown process '%s'. Use a process class from the spxa library "
        "(for example vg, nig, cgmy, merton) or the full class name; "
        "see -spxa list- after defining a process." % token,
        RC_SYNTAX,
    )


def _lookup_attr(attr: str, token: str):
    obj = getattr(_spxa, attr, None)
    if obj is None or not isinstance(obj, type):
        raise SpxaError("unknown process '%s'" % token, RC_SYNTAX)
    try:
        is_process = issubclass(obj, _spxa.Process)
    except Exception:  # pragma: no cover
        is_process = False
    if not is_process:
        raise SpxaError(
            "'%s' is not an spxa process; it cannot be used with spxa define"
            % token,
            RC_SYNTAX,
        )
    return obj


def _kwargs_from_call(node: ast.Call, context: str) -> Dict[str, Any]:
    """Extract literal keyword arguments from an ast.Call node."""
    if node.args:
        raise SpxaError(
            "process arguments in %s must be given as name=value pairs "
            "(for example vg(sigma=0.2, nu=0.1))" % context,
            RC_SYNTAX,
        )
    kwargs: Dict[str, Any] = {}
    for kw in node.keywords:
        if kw.arg is None:
            raise SpxaError(
                "process arguments in %s must be given as name=value pairs"
                % context,
                RC_SYNTAX,
            )
        try:
            value = ast.literal_eval(kw.value)
        except Exception:
            raise SpxaError(
                "value of argument '%s' in %s must be a number"
                % (kw.arg, context),
                RC_SYNTAX,
            )
        kwargs[kw.arg] = value
    return kwargs


def _parse_params(text: str) -> Dict[str, Any]:
    """Parse 'sigma=0.2, nu=0.1' into a dict, with good error messages."""
    text = (text or "").strip()
    if not text:
        return {}
    try:
        node = ast.parse("f(%s)" % text, mode="eval").body
    except SyntaxError:
        raise SpxaError(
            "params(%s) is not a valid parameter list; use name=value pairs "
            "separated by commas, as in params(sigma=0.2, nu=0.1)" % text,
            RC_SYNTAX,
        )
    if not isinstance(node, ast.Call):  # pragma: no cover - defensive
        raise SpxaError("params() could not be parsed", RC_SYNTAX)
    return _kwargs_from_call(node, "params()")


def _construct(cls, kwargs: Dict[str, Any], token: str):
    try:
        return cls(**kwargs)
    except TypeError as exc:
        raise SpxaError(
            "%s does not accept these parameters (%s). "
            "Check the parameter names for '%s' in the spxa documentation."
            % (getattr(cls, "__name__", token), exc, token),
            RC_SYNTAX,
        )
    except Exception as exc:
        raise SpxaError(
            "%s(%s) could not be constructed: %s"
            % (
                getattr(cls, "__name__", token),
                ", ".join("%s=%r" % (k, v) for k, v in sorted(kwargs.items())),
                exc,
            ),
            RC_SYNTAX,
        )


_BINOPS = {
    ast.Add: operator.add,
    ast.Sub: operator.sub,
    ast.Mult: operator.mul,
    ast.MatMult: operator.matmul,
}
_OPNAME = {
    ast.Add: "+",
    ast.Sub: "-",
    ast.Mult: "*",
    ast.MatMult: "@",
}


def _is_num(x: Any) -> bool:
    return isinstance(x, (int, float)) and not isinstance(x, bool)


def _eval_node(node: ast.AST):
    """Evaluate a restricted expression: numbers, handles, + - * @, calls."""
    if isinstance(node, ast.Constant):
        if _is_num(node.value):
            return float(node.value)
        raise SpxaError(
            "only numbers may appear literally in expr(); found %r" % (node.value,),
            RC_SYNTAX,
        )
    if isinstance(node, ast.Name):
        if node.id not in _REGISTRY:
            raise SpxaError(
                "'%s' is not a defined process handle. Define it first with "
                "-spxa define %s, process(...)- or drop it from the expression."
                % (node.id, node.id),
                RC_SYNTAX,
            )
        return _REGISTRY[node.id]
    if isinstance(node, ast.UnaryOp) and isinstance(node.op, ast.USub):
        return -_eval_node(node.operand)
    if isinstance(node, ast.BinOp):
        op = type(node.op)
        if op not in _BINOPS:
            raise SpxaError(
                "operator not allowed in expr(); use +, -, *, or @ "
                "(no division, powers, or chained expressions)",
                RC_SYNTAX,
            )
        left = _eval_node(node.left)
        right = _eval_node(node.right)
        sym = _OPNAME[op]
        if op is ast.MatMult:
            if not (_is_process_obj(left) and _is_process_obj(right)):
                raise SpxaError(
                    "subordination X @ T requires a process on both sides "
                    "of '@' (T must be a subordinator)", RC_SYNTAX
                )
        elif op is ast.Mult:
            if not (
                (_is_num(left) and _is_process_obj(right))
                or (_is_process_obj(left) and _is_num(right))
            ):
                raise SpxaError(
                    "'*' in expr() requires a scalar and a process "
                    "(use a process handle or a number)", RC_SYNTAX
                )
        else:  # Add / Sub
            if not (_is_process_obj(left) and _is_process_obj(right)):
                raise SpxaError(
                    "'%s' in expr() requires a process on both sides; to add a "
                    "deterministic drift use the process drift(mu=...)"
                    % sym,
                    RC_SYNTAX,
                )
        try:
            return _BINOPS[op](left, right)
        except Exception as exc:
            raise SpxaError(
                "spxa could not evaluate '%s' (%s): %s" % (sym, sym, exc),
                RC_SYNTAX,
            )
    if isinstance(node, ast.Call):
        if not isinstance(node.func, ast.Name):
            raise SpxaError(
                "expr() may only call process constructors by name", RC_SYNTAX
            )
        cls = _process_class(node.func.id)
        return _construct(cls, _kwargs_from_call(node, "expr()"), node.func.id)
    raise SpxaError(
        "expr() may contain only numbers, process handles, the operators "
        "+ - * @, and process constructors such as gamma(a=1, b=2)",
        RC_SYNTAX,
    )


def _is_process_obj(x: Any) -> bool:
    if _spxa is None:
        return False
    try:
        return isinstance(x, _spxa.Process)
    except Exception:  # pragma: no cover
        return False


def _get(handle: str):
    """Fetch a defined process by handle."""
    _require_spxa()
    h = (handle or "").strip()
    if not h:
        raise SpxaError("no process handle was given", RC_SYNTAX)
    if h not in _REGISTRY:
        raise SpxaError(
            "process handle '%s' is not defined in this Stata session. "
            "Define it with -spxa define %s, process(...)- first. "
            "Note that -python clear- removes all spxa handles." % (h, h),
            RC_NOTFOUND,
        )
    return _REGISTRY[h]


# ---------------------------------------------------------------------------
# SMCL helpers
# ---------------------------------------------------------------------------


def _disp(text: str = "") -> None:
    try:
        SFIToolkit.display(text)
    except Exception:  # pragma: no cover
        print(text)


def _fmt(x: Optional[float], width: int = 13, prec: int = 6) -> str:
    if x is None or (isinstance(x, float) and (math.isnan(x) or math.isinf(x))):
        return "%*s" % (width, ".")
    return "%*.*f" % (width, prec, x)


def _wrap(label: str, value: str, indent: int = 2, width: int = 72) -> List[str]:
    """Return lines for 'label : value', wrapping value onto continuation lines."""
    head = " " * indent + "%-15s : " % label
    avail = max(width - len(head), 20)
    words = str(value).replace("\n", " ").split(" ")
    lines: List[str] = []
    cur = ""
    for w in words:
        candidate = w if not cur else cur + " " + w
        if len(candidate) > avail and cur:
            lines.append(cur)
            cur = w
        else:
            cur = candidate
    lines.append(cur)
    out = [head + lines[0]]
    out += [" " * len(head) + ln for ln in lines[1:]]
    return out


def _exactness_name(proc) -> str:
    name = getattr(proc, "exactness", None)
    if name is None:
        return "UNKNOWN"
    return str(name).split(".")[-1]


# ---------------------------------------------------------------------------
# Subcommand: define
# ---------------------------------------------------------------------------


def _define(handle: str, process: str = "", params: str = "", expr: str = "") -> None:
    _require_spxa()
    handle = (handle or "").strip()
    process = (process or "").strip()
    params = (params or "").strip()
    expr = (expr or "").strip()

    if bool(process) == bool(expr):
        raise SpxaError(
            "specify either process(), optionally with params(), or expr()",
            RC_SYNTAX,
        )
    if expr and params:
        raise SpxaError("params() cannot be used with expr()", RC_SYNTAX)

    SFIToolkit.rclear()

    if expr:
        try:
            ast.parse(expr, mode="eval")
        except SyntaxError as exc:
            raise SpxaError(
                "expr() is not a valid expression: %s" % expr, RC_SYNTAX
            )
        proc = _eval_node(ast.parse(expr, mode="eval").body)
        how = expr
    else:
        cls = _process_class(process)
        proc = _construct(cls, _parse_params(params), process)
        how = repr(proc)

    _REGISTRY[handle] = proc
    _disp("{txt}  process {res}%s{txt} defined: %s" % (handle, repr(proc)))
    _disp("{txt}  exactness level: {res}%s" % _exactness_name(proc))
    Macro.setGlobal("r(handle)", handle)
    Macro.setGlobal("r(structure)", repr(proc))
    Macro.setGlobal("r(exactness)", _exactness_name(proc))


# Names of the global macros through which the ado-files hand text to Python.
# Passing strings this way (rather than pasting them into the Python source)
# means user input can contain quotes, commas, and brackets without any risk of
# breaking the generated statement.
G_PROCESS = "__SPXA_PROCESS"
G_PARAMS = "__SPXA_PARAMS"
G_EXPR = "__SPXA_EXPR"
G_SEED = "__SPXA_SEED"
G_GENERATE = "__SPXA_GENERATE"


def _define_entry(handle: str) -> None:
    _define(handle, _g(G_PROCESS), _g(G_PARAMS), _g(G_EXPR))


def spxa_define(handle: str) -> None:
    """spxa define -- build a process and register it under a handle."""
    _run(_define_entry, handle)


# ---------------------------------------------------------------------------
# Subcommand: simulate
# ---------------------------------------------------------------------------


def _simulate(
    handle: str,
    paths: int = 1,
    steps: int = 252,
    horizon: float = 1.0,
    seed: str = "",
    generate: str = "x",
    initial: float = 0.0,
    uselog: int = 0,
    wide: int = 0,
    hasinitial: int = 0,
) -> None:
    _require_spxa()
    SFIToolkit.rclear()

    npaths = int(paths)
    nsteps = int(steps)
    T = float(horizon)
    gen = (generate or "x").strip()
    # initial() is optional: the default is 1 with -log- (a price level) and
    # 0 without it (a log level).  hasinitial distinguishes "not given" from
    # an explicit initial(0).
    if hasinitial:
        start = float(initial)
    else:
        start = 1.0 if uselog else 0.0

    if npaths < 1:
        raise SpxaError("paths() must be at least 1", RC_SYNTAX)
    if nsteps < 1:
        raise SpxaError("steps() must be at least 1", RC_SYNTAX)
    if not (T > 0.0):
        raise SpxaError("t() (terminal time) must be strictly positive", RC_SYNTAX)
    if not math.isfinite(start):
        raise SpxaError("initial() must be a finite number", RC_SYNTAX)
    if uselog and start <= 0:
        raise SpxaError(
            "with log, initial() is a price level and must be strictly positive",
            RC_SYNTAX,
        )
    if not gen or not str(gen).replace("_", "a").isalnum() or gen[0].isdigit():
        raise SpxaError(
            "generate(%s) is not a valid Stata variable name" % gen, RC_SYNTAX
        )

    nobs = npaths * (nsteps + 1)
    if nobs > 1000000000:
        raise SpxaError(
            "requested %d observations, which exceeds the supported maximum; "
            "reduce paths() or steps()" % nobs,
            RC_SYNTAX,
        )
    if wide:
        try:
            maxvar = int(Data.getMaxVars())
        except Exception:  # pragma: no cover
            maxvar = 2048
        if npaths + 1 > maxvar:
            raise SpxaError(
                "wide would create %d variables, more than this Stata allows "
                "(%d); reduce paths() or omit wide" % (npaths + 1, maxvar),
                RC_SYNTAX,
            )

    seedval = None
    seedtxt = (seed or "").strip()
    if seedtxt and seedtxt != ".":
        try:
            seedval = int(float(seedtxt))
        except ValueError:
            raise SpxaError(
                "seed(%s) must be an integer" % seedtxt, RC_SYNTAX
            )
        if seedval < 0 or seedval >= 2 ** 64:
            raise SpxaError(
                "seed() must lie between 0 and 2^64-1", RC_SYNTAX
            )
    # only now touch the registry: a syntax error is reported as a syntax error
    # whether or not the handle happens to exist
    proc = _get(handle)

    rng = _np.random.default_rng(seedval)

    try:
        raw = proc.simulate(nsteps, npaths, T, rng)
    except Exception as exc:
        raise SpxaError(
            "spxa could not simulate '%s': %s: %s"
            % (handle, type(exc).__name__, exc),
            RC_GENERAL,
        )

    arr = _np.asarray(raw, dtype=float)
    if arr.ndim != 2:
        raise SpxaError(
            "process '%s' is multivariate (paths have shape %s); "
            "-spxa simulate- supports univariate processes only"
            % (handle, "x".join(str(d) for d in arr.shape)),
            RC_SYNTAX,
        )
    if arr.shape != (npaths, nsteps + 1):
        raise SpxaError(
            "spxa returned paths of shape %s, expected (%d, %d)"
            % (arr.shape, npaths, nsteps + 1),
            RC_GENERAL,
        )
    if not bool(_np.all(_np.isfinite(arr))):
        raise SpxaError(
            "simulation of '%s' produced non-finite increments; check that the "
            "parameters lie in the process's admissible range" % handle,
            RC_GENERAL,
        )

    values = start * _np.exp(arr) if uselog else start + arr
    if not bool(_np.all(_np.isfinite(values))):
        raise SpxaError(
            "the simulated values overflowed; reduce t() or the scale of the "
            "process, or omit log", RC_GENERAL
        )
    times = _np.linspace(0.0, T, nsteps + 1)

    if wide:
        _write_wide(gen, times, values, handle, uselog, start)
    else:
        _write_long(gen, times, values, handle, uselog, start)

    _rset("r(paths)", npaths)
    _rset("r(steps)", nsteps)
    _rset("r(obs)", nobs)
    _rset("r(T)", T)
    _rset("r(initial)", start)
    _rset("r(seed)", seedval if seedval is not None else -1)
    Macro.setGlobal("r(generate)", gen)
    Macro.setGlobal("r(layout)", "wide" if wide else "long")
    Macro.setGlobal("r(handle)", (handle or "").strip())


def _label(var: str, text: str) -> None:
    try:
        Data.setVarLabel(var, text)
    except Exception:  # pragma: no cover - cosmetic only
        pass


def _format(var: str, fmt: str) -> None:
    try:
        Data.setVarFormat(var, fmt)
    except Exception:  # pragma: no cover - cosmetic only
        pass


def _drop_if_present(names: str) -> None:
    """Drop variables created by an earlier call, if they are still there.

    -spxa simulate- clears the data before it calls this module, so normally
    there is nothing to drop; doing it here as well means the same result when
    the adapter is used from Python directly.
    """
    try:
        Data.dropVar(names)
    except Exception:
        pass          # nothing to drop, or an sfi without dropVar


def _write_long(gen, times, values, handle, uselog, start) -> None:
    """Long layout: one observation per path-time.

    -step- is the integer time index 0, 1, ..., steps, and -t- is the continuous
    time t = step * T/steps.  xtset requires integers, so -xtset path step-
    works as it stands, while -t- keeps the actual time for analysis.  Writing
    the fractional time into the time variable would make xtset fail with
    "time values with period less than delta() found" (error 451).
    """
    npaths, ncols = values.shape
    _drop_if_present("path step t %s" % gen)
    Data.addVarInt("path")
    Data.addVarLong("step")
    Data.addVarDouble("t")
    Data.addVarDouble(gen)
    Data.setObsTotal(npaths * ncols)

    steps = _np.arange(ncols, dtype=float)
    pathcol = _np.repeat(_np.arange(1, npaths + 1, dtype=float), ncols)
    Data.store("path", None, pathcol.tolist())
    Data.store("step", None, _np.tile(steps, npaths).tolist())
    Data.store("t", None, _np.tile(times, npaths).tolist())
    Data.store(gen, None, values.reshape(-1).tolist())

    _label("path", "simulated path")
    _label("step", "time index (integer; use with xtset)")
    _label("t", "time")
    _label(gen, _value_label(handle, uselog, start))
    _format("path", "%8.0f")
    _format("step", "%8.0f")
    _format("t", "%9.4f")
    _format(gen, "%10.0g")
    Macro.setGlobal("r(stepvar)", "step")


def _write_wide(gen, times, values, handle, uselog, start) -> None:
    """Wide layout: one variable per path, and -t- is the integer time index."""
    npaths, ncols = values.shape
    _drop_if_present("t " + " ".join("%s%d" % (gen, j + 1) for j in range(npaths)))
    Data.addVarLong("t")
    names = []
    for j in range(npaths):
        var = "%s%d" % (gen, j + 1)
        Data.addVarDouble(var)
        names.append(var)
    Data.setObsTotal(ncols)
    Data.store("t", None, _np.arange(ncols, dtype=float).tolist())
    for j, var in enumerate(names):
        Data.store(var, None, values[j].tolist())
        _label(var, _value_label(handle, uselog, start))
        _format(var, "%10.0g")
    _label("t", "time index (integer; use with xtset)")
    _format("t", "%8.0f")
    Macro.setGlobal("r(stepvar)", "t")


def _value_label(handle, uselog, start) -> str:
    h = (handle or "").strip()
    if uselog:
        return "simulated %s: %g*exp(X_t)" % (h, start)
    return "simulated %s: X_t" % h if start == 0 else "simulated %s: %g + X_t" % (h, start)


def _simulate_entry(handle, paths, steps, horizon, initial, uselog, wide,
                    hasinitial) -> None:
    _simulate(handle, paths, steps, horizon, _g(G_SEED), _g(G_GENERATE),
              initial, uselog, wide, hasinitial)


def spxa_simulate(handle, paths=1, steps=252, horizon=1.0, initial=0.0,
                  uselog=0, wide=0, hasinitial=0) -> None:
    """spxa simulate -- write simulated paths into the Stata dataset."""
    _run(_simulate_entry, handle, paths, steps, horizon, initial, uselog, wide,
         hasinitial)


# ---------------------------------------------------------------------------
# Subcommand: report
# ---------------------------------------------------------------------------


def _report(handle: str, order: int = 4, matrix: str = "", story: int = 0, detail: int = 0) -> None:
    _require_spxa()
    proc = _get(handle)
    h = (handle or "").strip()
    order = int(order)
    if order < 1 or order > 20:
        raise SpxaError("cumulants() must lie between 1 and 20", RC_SYNTAX)

    SFIToolkit.rclear()

    exact = _exactness_name(proc)
    _disp("")
    _disp("{txt}process law: {res}%s" % h)
    for line in _wrap("structure", repr(proc)):
        _disp("{txt}" + line)
    _disp("{txt}  %-15s : {res}%s" % ("exactness", exact))

    b = None
    sigma_sq = None
    if exact == "EXACT":
        try:
            trip = proc.triplet
            b = float(trip.b)
            sigma_sq = float(trip.sigma_sq)
        except Exception as exc:
            _disp("{txt}  (triplet unavailable: %s)" % str(exc).splitlines()[0])
    else:
        _disp(
            "{txt}  (no closed-form triplet; the cumulants below are propagated "
            "moments or are unavailable)"
        )

    if b is not None:
        _disp("")
        _disp("{txt}Lévy-Khintchine triplet of X_1")
        _disp("{txt}  %-22s %s" % ("drift b", _fmt(b)))
        _disp("{txt}  %-22s %s" % ("Gaussian variance", _fmt(sigma_sq)))
        _rset("r(b)", b)
        _rset("r(sigma_sq)", sigma_sq)
    else:
        _rset("r(b)", None)
        _rset("r(sigma_sq)", None)

    kappas: List[Optional[float]] = []
    try:
        raw = proc.cumulants(order)
    except Exception as exc:
        raw = {}
        _disp("{txt}  cumulants unavailable: %s" % str(exc).splitlines()[0])
    for j in range(1, order + 1):
        val = raw.get(j) if isinstance(raw, dict) else None
        kappas.append(None if val is None else float(val))

    if any(k is not None for k in kappas):
        _disp("")
        _disp("{txt}cumulants of X_1")
        for j, val in enumerate(kappas, start=1):
            _disp("{txt}  %-22s %s" % ("kappa_%d" % j, _fmt(val)))
            _rset("r(kappa%d)" % j, val)

    k2 = kappas[1] if len(kappas) > 1 else None
    skew = None
    exkurt = None
    if k2 is not None and k2 > 0:
        if len(kappas) > 2 and kappas[2] is not None:
            skew = kappas[2] / k2 ** 1.5
        if len(kappas) > 3 and kappas[3] is not None:
            exkurt = kappas[3] / k2 ** 2
        _disp("")
        _disp("{txt}derived")
        if skew is not None:
            _disp("{txt}  %-22s %s" % ("skewness", _fmt(skew)))
            _rset("r(skewness)", skew)
        if exkurt is not None:
            _disp("{txt}  %-22s %s" % ("excess kurtosis", _fmt(exkurt)))
            _rset("r(exkurtosis)", exkurt)
    else:
        _rset("r(skewness)", None)
        _rset("r(exkurtosis)", None)

    if matrix:
        # a row vector, as Stata's own estimation commands store e(b), so that
        # kappa_j is read as b[1, j]
        row = [float("nan") if val is None else val for val in kappas]
        try:
            Matrix.store(matrix, [row])
            try:
                Matrix.setRowNames(matrix, ["kappa"])
                Matrix.setColNames(matrix, ["k%d" % (j + 1)
                                            for j in range(len(row))])
            except Exception:  # pragma: no cover - names are cosmetic
                pass
            _disp("")
            _disp("{txt}matrix {res}%s{txt} contains kappa_1 ... kappa_%d "
                  "in kappa[1,1] ... kappa[1,%d]" % (matrix, len(row), len(row)))
        except Exception as exc:
            raise SpxaError(
                "could not create matrix %s: %s" % (matrix, exc), RC_SYNTAX
            )

    if detail:
        _disp("")
        _disp("{txt}properties")
        props = getattr(proc, "properties", None)
        if props is not None:
            for fld in getattr(props, "_fields", []):
                try:
                    _disp("{txt}  %-26s %s" % (fld, getattr(props, fld)))
                except Exception:  # pragma: no cover
                    continue

    Macro.setGlobal("r(handle)", h)
    Macro.setGlobal("r(structure)", repr(proc))
    Macro.setGlobal("r(exactness)", exact)

    if story:
        _disp("")
        try:
            text = proc.__story__()
        except Exception as exc:
            raise SpxaError(
                "spxa could not produce a derivation trace: %s" % exc, RC_GENERAL
            )
        for line in str(text).splitlines():
            _disp(line)


def spxa_report(handle: str, order: int = 4, matrix: str = "", story: int = 0, detail: int = 0) -> None:
    """spxa report -- display the law of a process and store r() results."""
    _run(_report, handle, order, matrix, story, detail)


# ---------------------------------------------------------------------------
# Subcommand: list / drop / clear / probe
# ---------------------------------------------------------------------------


def _list() -> None:
    _require_spxa()
    SFIToolkit.rclear()
    if not _REGISTRY:
        _disp("{txt}no spxa processes are defined in this session")
        _rset("r(n_defined)", 0)
        return
    _disp("")
    _disp("{txt}{hline 70}")
    _disp("{txt}  %-16s %-22s %s" % ("handle", "exactness", "structure"))
    _disp("{txt}{hline 70}")
    for handle in sorted(_REGISTRY):
        proc = _REGISTRY[handle]
        struct = repr(proc)
        if len(struct) > 60:
            struct = struct[:57] + "..."
        _disp("{txt}  %-16s %-22s %s" % (handle, _exactness_name(proc), struct))
    _disp("{txt}{hline 70}")
    _rset("r(n_defined)", len(_REGISTRY))


def spxa_list() -> None:
    _run(_list)


def _drop(handle: str) -> None:
    h = (handle or "").strip()
    if h not in _REGISTRY:
        raise SpxaError("process handle '%s' is not defined" % h, RC_NOTFOUND)
    del _REGISTRY[h]
    _disp("{txt}process {res}%s{txt} dropped" % h)


def spxa_drop(handle: str) -> None:
    _run(_drop, handle)


def _clear() -> None:
    n = len(_REGISTRY)
    _REGISTRY.clear()
    _disp("{txt}all spxa processes cleared (%d removed)" % n)


def spxa_clear() -> None:
    _run(_clear)


def _probe() -> None:
    _require_spxa()
    Macro.setGlobal("r(spxa_version)", SPXA_VERSION)
    Macro.setGlobal("r(adapter_version)", ADAPTER_VERSION)


def spxa_probe() -> None:
    """Check that the Python side is usable; called by _spxa_ensure."""
    _run(_probe)


# ---------------------------------------------------------------------------
# Introspection helpers (used by the test suite)
# ---------------------------------------------------------------------------


def _registry_handles() -> List[str]:
    return sorted(_REGISTRY)
