*! _spxa_drop 1.0.0  21nov2026
*! internal: implement -spxa drop-
*! author: Nityahapani
*!
*! Removes one process handle.

program define _spxa_drop, rclass
    version 16.0

    syntax name(name=handle)

    _spxa_ensure
    local erc = r(rc)
    if (`erc' != 0) exit `erc'

    * Pre-seed the return code: if the Python call were to fail before it could
    * report back, the code below would still see a failure rather than a
    * silent success.
    capture scalar drop __spxa_rc
    scalar __spxa_rc = 499

    * -capture noisily- : the output of the block is shown, and a failure
    * still sets _rc instead of stopping the do-file.
    capture noisily python: import spxa_stata; spxa_stata.spxa_drop("`handle'")

    local pyrc = 499
    capture local pyrc = scalar(__spxa_rc)
    capture scalar drop __spxa_rc
    if (`pyrc' != 0) exit `pyrc'
end
