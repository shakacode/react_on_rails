## Rails assets

### Problem
When client js uses images in render methods, e.g. `<img src='...' />` or in css, e.g. `background-image: url(...)` 
these assets fail to load. This happens because rails adds digest hashes to filenames 
when compiling assets, e.g. `img1.jpg` becomes `img1-dbu097452jf2v2.jpg`. 

When compiling its native css Rails transforms all urls and links to digested 
versions, i.e. `background-image: image-url(img1.jpg)` becomes 
`background-image: url(img1-dbu097452jf2v2.jpg)`. However this doesn't happen for js and 
css files compiled by webpack on the client side, because they don't use 
`image-url` and `asset-url`. Without some fix, these assets would fail to load.

### Solution

React on Rails creates copies of non-digested versions to digested versions in the public 
deployment directory when doing a Rails assets compile.
The solution is implemented using `assets:precompile` after-hook. The assets for copying
are defined by `config.non_digested_assets_regex` in `config/initializers/react_on_rails.rb`.
To disable this transformation, set this parameter to `nil`.
