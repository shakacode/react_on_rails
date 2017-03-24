# Images

A full example can be found at [spec/dummy/client/app/components/ImageExample/ImageExample.js](../../spec/dummy/client/app/components/ImageExample/ImageExample.js)

You are free to use images either in image tags or as background images in SCSS files. You can 
use a "global" location of /client/app/assets/images or a relative path to your JS or SCSS file, as
is done with CSS modules.

**images** is a defined alias, so "images/foobar.jpg" would point to the file at 
`/client/app/assets/images/foobar.jpg.`

# Usage as Background Images or for `img` Tags

Background images for CSS/SCSS need slightly different handling than images used with `img` tags,
and thus we need to configure the webpack loaders slightly differently.

The example shows you how to put either `bg-` or `bg_` in any file to be used as a background image. A regexp match
will ensure the appropriate version of the url-loader to be used depending on if the image is used
as a background image or within an `img` tag.

The reason why this is done is that the sass-loader assumes that images will be relative to the
deployed sass file, which will already be `/assets/some-file.css`. Thus, the sass-loader is already
going to prepend `/assets` to all images. The file-loader needs an option to specify that the
public path is `/assets` and that will get prepended to any image path. Consequently, if we didn't
distinguish background images from images for `img` tags, then the background image tags will get
an image path like `/assets/assets/some-file.svg` because the sass-loader thinks the path should be
`/assets/some-file.svg` and that gets added to what the file-loader will be doing.

We solve this by requiring a naming convention of `bg-` or `bg_` in the image names. Be warned that
the regexp does not check that these three characters are the beginning of a name or path. They can
be anywhere in the string. Of course, you can create your convention.

You can see this configured: [spec/dummy/client/webpack.common.js](../../spec/dummy/client/webpack.common.js)

_Note, all of this may change when we skip the asset pipeline for processing files in the near future._
