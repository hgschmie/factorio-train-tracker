------------------------------------------------------------------------
-- runtime code
------------------------------------------------------------------------

This, Framework = require('lib.init')()

-- setup events
require('scripts.event-setup')

Framework.post_runtime_stage()
