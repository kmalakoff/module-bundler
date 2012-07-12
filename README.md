[![Build Status](https://secure.travis-ci.org/kmalakoff/module-bundler.png)](http://travis-ci.org/kmalakoff/module-bundler)

````
                          _                 __                    ____
   ________  ____ ___  __(_)_______        / /_  __  ______  ____/ / /__  _____
  / ___/ _ \/ __ `/ / / / / ___/ _ \______/ __ \/ / / / __ \/ __  / / _ \/ ___/
 / /  /  __/ /_/ / /_/ / / /  /  __/_____/ /_/ / /_/ / / / / /_/ / /  __/ /
/_/   \___/\__, /\__,_/_/_/   \___/     /_.___/\__,_/_/ /_/\__,_/_/\___/_/
             /_/
````

ModuleBundler combines javascript files and provides a minimal AMD-like loader to access them.

A typically bundle file will have multiple bundles and output directories specified like (CoffeeScript config file):

```
module.exports =
  'test/packaging/build/bundle-latest.js':
    underscore: 'underscore'
    'underscore-awesomer': 'underscore-awesomer.js'

  'test/packaging/build/bundle-legacy.js':
    underscore: 'vendor/underscore-1.2.1.js'
    'underscore-awesomer': 'underscore-awesomer.js'
```

In this example, two bundles will be created:

1. test/packaging/build/bundle-latest.js - will include underscore from an npm install and underscore-awesomer.js from the current working directory.

2. test/packaging/build/bundle-legacy.js - will include underscore from the vendor directory and underscore-awesomer.js from the current working directory.

Also, there are some additional bundling options:

1. **_publish** - this calls require(module_name) and assigns the result to a symbol on window (browser) or globals (server). This is useful when using a bundle on the client where libraries expect dependent symbols to be defined on window.

2. **_alias** - this calls require(module_name) and re-defines it under a new, aliased module name. This is useful is you want to replace a loaded module in a library. For example, you can replace underscore with Lo-Dash in Backbone.js.

3. **_load** - this calls require(module_name) to ensure the module is loaded when the bundle is loaded.

Examples (CoffeeScript config file):

```
module.exports =
  'vendor/scripts/client-bundle.js':
    lodash: 'lodash'
    backbone: 'backbone'
    'backbone-articulation': 'backbone-articulation'

    _alias:
      underscore: 'lodash'
    _publish:
      _: 'underscore'
      Backbone: 'backbone'
    _load:
      'backbone-articulation'
```

Of course, this example could be simplified as:

```
module.exports =
  'vendor/scripts/client-bundle.js':
    underscore: 'lodash'
    backbone: 'backbone'
    'backbone-articulation': 'backbone-articulation'

    _publish:
      _: 'underscore'
      Backbone: 'backbone'
    _load:
      'backbone-articulation'
```


# Release Notes

###0.1.1

- initial release

Building the library
-----------------------

###Installing:

1. install node.js: http://nodejs.org
2. install node packages: 'npm install'

###Commands:

Look at: https://github.com/kmalakoff/easy-bake
