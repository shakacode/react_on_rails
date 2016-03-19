# Updating Dependencies

If you frequently update you dependencies in small batches, you will avoid large and painful updates later. Then again, if you don't have good tests coverage, it's hazardous to update dependencies at any time.

## Ruby

Delete any unwanted version constraints from your Gemfile and run:

```bash
bundle update
```

## NPM

1. Install [npm-check-updates](https://www.npmjs.com/package/npm-check-updates)
1. Run `npm outdated` and read CHANGELOGs of major updated packages before you update. You might not be ready for some updates.
1. Run these commands. Note, you may or may not want to remove your npm-shrinkwrap.json if you get some werid conflicts, and you may or may not need to `rm -rf` your `node_modules` directory. 

```
cd client
rm npm-shrinkwrap.json
ncu -u -a
npm i
```

Some combinations that I often run:

### remove old installed `node_modules` so you only get what corresponds to package.json
```
ncu -u -a && rm -rf node_modules && npm i
```

Note: newer versions of npm (>3) automatically create a new version of the npm-shrinkwrap.json.
